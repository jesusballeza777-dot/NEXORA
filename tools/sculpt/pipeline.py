"""
Pipeline del escultor: SDF → malla de alta resolución → malla de juego (presupuesto de la
Biblia) → UV → mapas PBR horneados → rig con pesos → GLB/OBJ/PNG + metadatos.

Convenciones de salida
- Studs de Roblox, Y arriba, la criatura mira hacia +Z.
- Mapa de normales en espacio tangente con convención OpenGL (verde = arriba en la imagen),
  la que usan glTF y Roblox. El GLB incluye tangentes coherentes con el horneado.
- Mapas sueltos para SurfaceAppearance: color (sRGB, con oclusión horneada), normal,
  rugosidad, metalicidad y máscara emisiva.
"""

from __future__ import annotations

import io
import json
import math
import struct
import time
from pathlib import Path

import numpy as np
from PIL import Image
from skimage import measure
import fast_simplification
import xatlas

from sdf import norm

# ---------------------------------------------------------------------------
# 1. Malla de alta resolución
# ---------------------------------------------------------------------------


def eval_grid(creature, voxel=None, chunk=400_000):
    h = voxel or creature.voxel
    lo, hi = creature.bounds()
    lo = lo - 3 * h
    hi = hi + 3 * h
    n = np.ceil((hi - lo) / h).astype(int) + 1
    xs = lo[0] + np.arange(n[0]) * h
    ys = lo[1] + np.arange(n[1]) * h
    zs = lo[2] + np.arange(n[2]) * h
    vol = np.empty((n[0], n[1], n[2]), dtype=np.float32)
    # por losas en X para acotar memoria
    slab = max(1, chunk // (n[1] * n[2]))
    Y, Z = np.meshgrid(ys, zs, indexing="ij")
    yz = np.stack([Y.ravel(), Z.ravel()], axis=1)
    for i0 in range(0, n[0], slab):
        i1 = min(n[0], i0 + slab)
        X = np.repeat(xs[i0:i1], len(yz))
        P = np.column_stack([X, np.tile(yz, (i1 - i0, 1))])
        vol[i0:i1] = creature.sdf(P).reshape(i1 - i0, n[1], n[2])
    return vol, lo, h


def high_mesh(creature, voxel=None):
    vol, lo, h = eval_grid(creature, voxel)
    verts, faces, _normals, _vals = measure.marching_cubes(vol, level=0.0, spacing=(h, h, h))
    verts = (verts + lo).astype(np.float64)
    faces = faces.astype(np.int64)
    # orientación: las normales de las caras deben apuntar hacia fuera (gradiente del SDF)
    sample = faces[:: max(1, len(faces) // 4000)]
    a, b, c = verts[sample[:, 0]], verts[sample[:, 1]], verts[sample[:, 2]]
    fn = np.cross(b - a, c - a)
    g = creature.gradient((a + b + c) / 3)
    if np.mean(np.sum(fn * g, axis=1)) < 0:
        faces = faces[:, ::-1].copy()
    return verts, faces


def decimate(verts, faces, target_tris):
    if len(faces) <= target_tris:
        return verts, faces
    red = 1.0 - target_tris / len(faces)
    v2, f2 = fast_simplification.simplify(verts.astype(np.float32), faces.astype(np.int32), target_reduction=red, agg=5)
    return v2.astype(np.float64), f2.astype(np.int64)


def clean_mesh(verts, faces):
    """Quita triángulos degenerados y vértices sin uso."""
    a, b, c = verts[faces[:, 0]], verts[faces[:, 1]], verts[faces[:, 2]]
    area = norm(np.cross(b - a, c - a)) * 0.5
    keep = (area > 1e-10) & (faces[:, 0] != faces[:, 1]) & (faces[:, 1] != faces[:, 2]) & (faces[:, 0] != faces[:, 2])
    faces = faces[keep]
    used = np.unique(faces)
    remap = -np.ones(len(verts), dtype=np.int64)
    remap[used] = np.arange(len(used))
    return verts[used], remap[faces]


def largest_component(verts, faces):
    """Se queda con la pieza conexa más grande (evita islas sueltas del marching cubes)."""
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import connected_components

    n = len(verts)
    e = np.concatenate([faces[:, [0, 1]], faces[:, [1, 2]], faces[:, [2, 0]]])
    g = coo_matrix((np.ones(len(e)), (e[:, 0], e[:, 1])), shape=(n, n))
    ncomp, labels = connected_components(g, directed=False)
    if ncomp <= 1:
        return verts, faces
    counts = np.bincount(labels[faces[:, 0]], minlength=ncomp)
    # conserva componentes con al menos el 2 % de las caras (ojos, garras separadas)
    keep_labels = np.where(counts >= max(8, 0.002 * len(faces)))[0]
    keep = np.isin(labels[faces[:, 0]], keep_labels)
    return clean_mesh(verts, faces[keep])


# ---------------------------------------------------------------------------
# 2. Normales, tangentes y UV
# ---------------------------------------------------------------------------


def vertex_normals_sdf(creature, verts):
    return creature.gradient(verts)


def unwrap(verts, faces, resolution=1024):
    atlas = xatlas.Atlas()
    atlas.add_mesh(verts.astype(np.float32), faces.astype(np.uint32))
    co = xatlas.ChartOptions()
    co.max_iterations = 2
    po = xatlas.PackOptions()
    po.resolution = resolution
    po.padding = 4
    po.bilinear = True
    po.bruteForce = False
    atlas.generate(co, po)
    vmapping, indices, uvs = atlas[0]
    return vmapping.astype(np.int64), indices.astype(np.int64), uvs.astype(np.float64)


def tangents(verts, normals, faces, uvs):
    """Tangente por vértice (xyz, w). T = dP/du; el bitangente apunta hacia arriba en la
    imagen (−dP/dv con v de glTF hacia abajo): convención OpenGL."""
    p0, p1, p2 = verts[faces[:, 0]], verts[faces[:, 1]], verts[faces[:, 2]]
    w0, w1, w2 = uvs[faces[:, 0]], uvs[faces[:, 1]], uvs[faces[:, 2]]
    e1, e2 = p1 - p0, p2 - p0
    d1, d2 = w1 - w0, w2 - w0
    r = d1[:, 0] * d2[:, 1] - d2[:, 0] * d1[:, 1]
    r = np.where(np.abs(r) < 1e-12, 1e-12, r)
    t = (e1 * d2[:, 1:2] - e2 * d1[:, 1:2]) / r[:, None]
    b = (e2 * d1[:, 0:1] - e1 * d2[:, 0:1]) / r[:, None]  # dP/dv
    T = np.zeros_like(verts)
    B = np.zeros_like(verts)
    for k in range(3):
        np.add.at(T, faces[:, k], t)
        np.add.at(B, faces[:, k], b)
    n = normals
    T = T - n * np.sum(n * T, axis=1, keepdims=True)
    T = T / np.maximum(norm(T)[:, None], 1e-9)
    up = -B
    w = np.sign(np.sum(np.cross(n, T) * up, axis=1))
    w[w == 0] = 1.0
    return np.column_stack([T, w])


# ---------------------------------------------------------------------------
# 3. Horneado de mapas
# ---------------------------------------------------------------------------


def rasterize(uvs, faces, res):
    """Para cada texel cubierto devuelve (índice de triángulo, baricéntricas)."""
    px = uvs * res - 0.5  # centros de texel en enteros
    tri_ids, bary, pix = [], [], []
    for f, (i0, i1, i2) in enumerate(faces):
        a, b, c = px[i0], px[i1], px[i2]
        xmin = max(int(math.floor(min(a[0], b[0], c[0]))), 0)
        xmax = min(int(math.ceil(max(a[0], b[0], c[0]))), res - 1)
        ymin = max(int(math.floor(min(a[1], b[1], c[1]))), 0)
        ymax = min(int(math.ceil(max(a[1], b[1], c[1]))), res - 1)
        if xmax < xmin or ymax < ymin:
            continue
        xs = np.arange(xmin, xmax + 1)
        ys = np.arange(ymin, ymax + 1)
        X, Y = np.meshgrid(xs, ys)
        P = np.stack([X.ravel(), Y.ravel()], axis=1).astype(np.float64)
        v0, v1 = b - a, c - a
        den = v0[0] * v1[1] - v1[0] * v0[1]
        if abs(den) < 1e-12:
            continue
        v2 = P - a
        l1 = (v2[:, 0] * v1[1] - v1[0] * v2[:, 1]) / den
        l2 = (v0[0] * v2[:, 1] - v2[:, 0] * v0[1]) / den
        l0 = 1 - l1 - l2
        eps = -0.02
        inside = (l0 >= eps) & (l1 >= eps) & (l2 >= eps)
        if not np.any(inside):
            continue
        tri_ids.append(np.full(int(inside.sum()), f))
        bary.append(np.stack([l0[inside], l1[inside], l2[inside]], axis=1))
        pix.append(P[inside].astype(np.int64))
    tri_ids = np.concatenate(tri_ids)
    bary = np.clip(np.concatenate(bary), 0, 1)
    bary = bary / bary.sum(axis=1, keepdims=True)
    pix = np.concatenate(pix)
    # un texel puede caer en dos triángulos vecinos: se queda el último (son contiguos)
    key = pix[:, 1] * res + pix[:, 0]
    _, last = np.unique(key[::-1], return_index=True)
    sel = len(key) - 1 - last
    return tri_ids[sel], bary[sel], pix[sel]


def project_to_surface(creature, p, iters=3):
    for _ in range(iters):
        d = creature.sdf(p)
        g = creature.gradient(p)
        p = p - d[:, None] * g
    return p


def bake_ao(creature, p, n, step=0.035, samples=5, strength=1.2):
    occ = np.zeros(len(p))
    w = 0.5
    for i in range(1, samples + 1):
        h = step * i
        d = creature.sdf(p + n * h)
        occ += w * np.maximum(h - d, 0.0) / h
        w *= 0.5
    return np.clip(1.0 - strength * occ, 0.0, 1.0)


def dilate(img, mask, passes=6):
    img = img.copy()
    mask = mask.copy()
    for _ in range(passes):
        acc = np.zeros_like(img)
        cnt = np.zeros(mask.shape)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
            sm = np.roll(np.roll(mask, dy, 0), dx, 1)
            si = np.roll(np.roll(img, dy, 0), dx, 1)
            acc += si * sm[..., None]
            cnt += sm
        grow = (~mask) & (cnt > 0)
        img[grow] = acc[grow] / cnt[grow][:, None]
        mask = mask | grow
    return img, mask


def bake(creature, verts, normals, tangents4, faces, uvs, res=1024):
    t0 = time.time()
    tri, bary, pix = rasterize(uvs, faces, res)
    f = faces[tri]
    P = np.einsum("nk,nkd->nd", bary, verts[f])
    N = np.einsum("nk,nkd->nd", bary, normals[f])
    N = N / np.maximum(norm(N)[:, None], 1e-9)
    Tt = np.einsum("nk,nkd->nd", bary, tangents4[f][:, :, :3])
    W = np.sign(np.einsum("nk,nk->n", bary, tangents4[f][:, :, 3]))
    W[W == 0] = 1
    Tt = Tt - N * np.sum(N * Tt, axis=1, keepdims=True)
    Tt = Tt / np.maximum(norm(Tt)[:, None], 1e-9)
    B = np.cross(N, Tt) * W[:, None]

    S = project_to_surface(creature, P)
    Nh = creature.gradient(S)
    _, winners, _ = creature.sdf(S, want_parts=True)

    base = np.zeros((len(S), 3))
    rough = np.zeros(len(S))
    metal = np.zeros(len(S))
    emis = np.zeros((len(S), 3))
    ao_w = np.zeros(len(S))
    for idx in np.unique(winners):
        sel = winners == idx
        part = creature.parts[idx]
        mat = creature.materials[part.mat]
        q = part.local(S[sel])
        base[sel] = mat.sample_color(q)
        rough[sel] = mat.roughness
        metal[sel] = mat.metalness
        emis[sel] = mat.sample_emissive(q) * min(1.0, mat.emissive_strength)
        ao_w[sel] = mat.ao
    ao = bake_ao(creature, S, Nh)
    ao_eff = 1.0 - ao_w * (1.0 - ao)
    base_ao = base * (0.35 + 0.65 * ao_eff)[:, None]

    # normal en espacio tangente (OpenGL)
    nts = np.stack([np.sum(Nh * Tt, 1), np.sum(Nh * B, 1), np.sum(Nh * N, 1)], axis=1)
    nts = nts / np.maximum(norm(nts)[:, None], 1e-9)

    def img(values, ch):
        out = np.zeros((res, res, ch))
        out[pix[:, 1], pix[:, 0]] = values.reshape(len(pix), ch)
        return out

    mask = np.zeros((res, res), dtype=bool)
    mask[pix[:, 1], pix[:, 0]] = True
    maps = {
        "color": img(base_ao, 3),
        "albedo": img(base, 3),
        "normal": img(nts * 0.5 + 0.5, 3),
        "roughness": img(rough, 1),
        "metalness": img(metal, 1),
        "emissive": img(emis, 3),
        "ao": img(ao, 1),
    }
    for k in maps:
        maps[k], _ = dilate(maps[k], mask, passes=8)
    # fuera de las islas: normal plana
    flat = ~dilate(np.zeros((res, res, 1)), mask, passes=8)[1]
    maps["normal"][flat] = (0.5, 0.5, 1.0)
    stats = {"texels": int(mask.sum()), "coverage": round(float(mask.mean()), 3), "seconds": round(time.time() - t0, 1)}
    return maps, stats


def to_png(arr, mode):
    a = np.clip(arr, 0, 1)
    if mode == "L":
        a = a[..., 0]
    im = Image.fromarray((a * 255 + 0.5).astype(np.uint8), mode)
    buf = io.BytesIO()
    im.save(buf, format="PNG", optimize=True)
    return buf.getvalue()


def linear_to_srgb(x):
    x = np.clip(x, 0, 1)
    return np.where(x <= 0.0031308, x * 12.92, 1.055 * np.power(x, 1 / 2.4) - 0.055)


# ---------------------------------------------------------------------------
# 4. Rig: pesos por cercanía a las piezas de cada hueso
# ---------------------------------------------------------------------------


def skin_weights(creature, verts, sigma=0.05):
    _, _, per = creature.sdf(verts, want_parts=True)
    bidx = creature.bone_index()
    W = np.zeros((len(verts), len(creature.bones)))
    for part, d in zip(creature.parts, per):
        if part.op != "add":
            continue
        w = np.exp(-np.maximum(d, 0.0) / sigma)
        if part.bone.endswith("*"):
            # pieza en espejo: hueso _L para x ≥ 0 y _R para x < 0
            left = verts[:, 0] >= 0
            bl = bidx.get(part.bone[:-1] + "L", bidx["root"])
            br = bidx.get(part.bone[:-1] + "R", bidx["root"])
            W[left, bl] += w[left]
            W[~left, br] += w[~left]
        else:
            b = bidx[part.bone if part.bone in bidx else "root"]
            W[:, b] += w
    top = np.argsort(-W, axis=1)[:, :4]
    tw = np.take_along_axis(W, top, axis=1)
    tw = tw / np.maximum(tw.sum(axis=1, keepdims=True), 1e-9)
    return top.astype(np.uint16), tw.astype(np.float32)


# ---------------------------------------------------------------------------
# 5. Exportación
# ---------------------------------------------------------------------------


def write_glb(path, verts, normals, tangents4, uvs, faces, images, creature=None, joints=None, weights=None):
    bufs = bytearray()
    views, accessors = [], []

    def add_view(data: bytes, target=None):
        while len(bufs) % 4:
            bufs.append(0)
        off = len(bufs)
        bufs.extend(data)
        view = {"buffer": 0, "byteOffset": off, "byteLength": len(data)}
        if target:
            view["target"] = target
        views.append(view)
        return len(views) - 1

    def add_acc(arr, ctype, atype, target=None, minmax=False):
        arr = np.ascontiguousarray(arr)
        vi = add_view(arr.tobytes(), target)
        acc = {"bufferView": vi, "componentType": ctype, "count": int(arr.shape[0]), "type": atype}
        if minmax:
            acc["min"] = arr.min(axis=0).tolist()
            acc["max"] = arr.max(axis=0).tolist()
        accessors.append(acc)
        return len(accessors) - 1

    attrs = {
        "POSITION": add_acc(verts.astype(np.float32), 5126, "VEC3", 34962, True),
        "NORMAL": add_acc(normals.astype(np.float32), 5126, "VEC3", 34962),
        "TANGENT": add_acc(tangents4.astype(np.float32), 5126, "VEC4", 34962),
        "TEXCOORD_0": add_acc(uvs.astype(np.float32), 5126, "VEC2", 34962),
    }
    if joints is not None:
        attrs["JOINTS_0"] = add_acc(joints.astype(np.uint16), 5123, "VEC4", 34962)
        attrs["WEIGHTS_0"] = add_acc(weights.astype(np.float32), 5126, "VEC4", 34962)
    ind = add_acc(faces.astype(np.uint32).ravel(), 5125, "SCALAR", 34963)

    gltf_images, textures = [], []
    for name in ("color", "orm", "normal", "emissive"):
        if name not in images:
            continue
        vi = add_view(images[name])
        gltf_images.append({"bufferView": vi, "mimeType": "image/png", "name": name})
        textures.append({"source": len(gltf_images) - 1, "sampler": 0})
    tex_index = {n: i for i, n in enumerate([k for k in ("color", "orm", "normal", "emissive") if k in images])}
    material = {
        "name": "M_" + (creature.id if creature else "creature"),
        "pbrMetallicRoughness": {
            "baseColorTexture": {"index": tex_index["color"]},
            "metallicRoughnessTexture": {"index": tex_index["orm"]},
            "metallicFactor": 1.0,
            "roughnessFactor": 1.0,
        },
        "normalTexture": {"index": tex_index["normal"]},
    }
    if "emissive" in images:
        material["emissiveTexture"] = {"index": tex_index["emissive"]}
        material["emissiveFactor"] = [1.0, 1.0, 1.0]

    nodes = [{"name": creature.id if creature else "creature", "mesh": 0}]
    skins = []
    scene_nodes = [0]
    if joints is not None and creature is not None:
        bidx = creature.bone_index()
        first = len(nodes)
        for b in creature.bones:
            parent_head = np.array(creature.bones[bidx[b.parent]].head) if b.parent else np.zeros(3)
            t = (np.array(b.head) - parent_head).tolist()
            nodes.append({"name": b.name, "translation": t})
        for b in creature.bones:
            if b.parent:
                pnode = nodes[first + bidx[b.parent]]
                pnode.setdefault("children", []).append(first + bidx[b.name])
        ibm = []
        for b in creature.bones:
            m = np.eye(4, dtype=np.float32)
            m[:3, 3] = -np.array(b.head)
            ibm.append(m.T.ravel())  # glTF: columna mayor
        ibm_acc = add_acc(np.array(ibm, dtype=np.float32), 5126, "MAT4")
        skins.append({"joints": list(range(first, first + len(creature.bones))), "inverseBindMatrices": ibm_acc, "skeleton": first})
        nodes[0]["skin"] = 0
        roots = [first + bidx[b.name] for b in creature.bones if not b.parent]
        scene_nodes += roots

    gltf = {
        "asset": {"version": "2.0", "generator": "NEXORA tools/sculpt"},
        "scene": 0,
        "scenes": [{"nodes": scene_nodes}],
        "nodes": nodes,
        "meshes": [{"name": nodes[0]["name"], "primitives": [{"attributes": attrs, "indices": ind, "material": 0}]}],
        "materials": [material],
        "textures": textures,
        "images": gltf_images,
        "samplers": [{"magFilter": 9729, "minFilter": 9987, "wrapS": 33071, "wrapT": 33071}],
        "accessors": accessors,
        "bufferViews": views,
        "buffers": [{"byteLength": len(bufs)}],
    }
    if skins:
        gltf["skins"] = skins
    js = json.dumps(gltf, separators=(",", ":")).encode()
    while len(js) % 4:
        js += b" "
    while len(bufs) % 4:
        bufs.append(0)
    total = 12 + 8 + len(js) + 8 + len(bufs)
    with open(path, "wb") as fh:
        fh.write(struct.pack("<III", 0x46546C67, 2, total))
        fh.write(struct.pack("<II", len(js), 0x4E4F534A))
        fh.write(js)
        fh.write(struct.pack("<II", len(bufs), 0x004E4942))
        fh.write(bytes(bufs))


def write_obj(path: Path, verts, normals, uvs, faces, mtl_name, tex_prefix):
    lines = [f"# NEXORA tools/sculpt · {path.stem}", f"mtllib {mtl_name}", f"o {path.stem}"]
    lines += [f"v {x:.5f} {y:.5f} {z:.5f}" for x, y, z in verts]
    lines += [f"vt {u:.6f} {1 - w:.6f}" for u, w in uvs]
    lines += [f"vn {x:.4f} {y:.4f} {z:.4f}" for x, y, z in normals]
    lines.append(f"usemtl {path.stem}")
    for a, b, c in faces + 1:
        lines.append(f"f {a}/{a}/{a} {b}/{b}/{b} {c}/{c}/{c}")
    path.write_text("\n".join(lines) + "\n")
    mtl = [
        f"newmtl {path.stem}",
        "Kd 1 1 1",
        f"map_Kd {tex_prefix}_color.png",
        f"norm {tex_prefix}_normal.png",
        f"map_Pr {tex_prefix}_roughness.png",
        f"map_Pm {tex_prefix}_metalness.png",
        f"map_Ke {tex_prefix}_emissive.png",
    ]
    (path.parent / mtl_name).write_text("\n".join(mtl) + "\n")


# ---------------------------------------------------------------------------
# 6. Construcción completa de un activo
# ---------------------------------------------------------------------------


def build_asset(creature, out_dir: Path, tex_res=1024, lod1_ratio=0.45, lod1_res=512, high_voxel=None, log=print):
    out_dir.mkdir(parents=True, exist_ok=True)
    t0 = time.time()
    hv, hf = high_mesh(creature, high_voxel)
    hv, hf = largest_component(hv, hf)
    log(f"  alta: {len(hf):,} triángulos ({time.time() - t0:.1f} s)")
    lo_t, hi_t = creature.tri_budget
    target = int(min(hi_t, max(lo_t, hi_t * 0.94)))
    results = {}
    for lod, (tgt, res) in enumerate([(target, tex_res), (int(target * lod1_ratio), lod1_res)]):
        v, f = decimate(hv, hf, tgt)
        v, f = clean_mesh(v, f)
        n = vertex_normals_sdf(creature, v)
        vm, idx, uv = unwrap(v, f, res)
        v2, n2, f2 = v[vm], n[vm], idx
        t4 = tangents(v2, n2, f2, uv)
        maps, bstats = bake(creature, v2, n2, t4, f2, uv, res)
        joints, weights = skin_weights(creature, v2)
        tag = f"{creature.id}" + ("" if lod == 0 else "_LOD1")
        orm = np.concatenate([np.ones_like(maps["roughness"]), maps["roughness"], maps["metalness"]], axis=2)
        color_srgb = maps["color"]  # los colores de la paleta ya están en sRGB
        images = {
            "color": to_png(color_srgb, "RGB"),
            "orm": to_png(orm, "RGB"),
            "normal": to_png(maps["normal"], "RGB"),
            "emissive": to_png(maps["emissive"], "RGB"),
        }
        write_glb(out_dir / f"{tag}.glb", v2, n2, t4, uv, f2, images, creature, joints, weights)
        if lod == 0:
            tex_dir = out_dir / "textures"
            tex_dir.mkdir(exist_ok=True)
            (tex_dir / f"{tag}_color.png").write_bytes(images["color"])
            (tex_dir / f"{tag}_normal.png").write_bytes(images["normal"])
            (tex_dir / f"{tag}_roughness.png").write_bytes(to_png(maps["roughness"], "L"))
            (tex_dir / f"{tag}_metalness.png").write_bytes(to_png(maps["metalness"], "L"))
            (tex_dir / f"{tag}_emissive.png").write_bytes(images["emissive"])
            write_obj(out_dir / f"{tag}.obj", v2, n2, uv, f2, f"{tag}.mtl", f"textures/{tag}")
        lo_, hi_ = v2.min(axis=0), v2.max(axis=0)
        results[f"LOD{lod}"] = {
            "file": f"{tag}.glb",
            "triangles": int(len(f2)),
            "vertices": int(len(v2)),
            "texture": f"{res}x{res}",
            "uvCoverage": bstats["coverage"],
            "bakeSeconds": bstats["seconds"],
            "sizeStuds": [round(float(x), 3) for x in (hi_ - lo_)],
        }
        log(f"  LOD{lod}: {len(f2):,} tri · {len(v2):,} vért · UV {bstats['coverage']:.0%} · horneado {bstats['seconds']} s")
    results["highPolyTriangles"] = int(len(hf))
    results["buildSeconds"] = round(time.time() - t0, 1)
    return results


# ---------------------------------------------------------------------------
# 7. Vista rápida para iterar el diseño (malla con color por vértice, sin hornear)
# ---------------------------------------------------------------------------


def vertex_colors(creature, verts, normals):
    _, winners, _ = creature.sdf(verts, want_parts=True)
    col = np.zeros((len(verts), 3))
    emis = np.zeros((len(verts), 3))
    ao_w = np.zeros(len(verts))
    for idx in np.unique(winners):
        sel = winners == idx
        part = creature.parts[idx]
        mat = creature.materials[part.mat]
        q = part.local(verts[sel])
        col[sel] = mat.sample_color(q)
        emis[sel] = mat.sample_emissive(q) * min(1.0, mat.emissive_strength)
        ao_w[sel] = mat.ao
    ao = bake_ao(creature, verts, normals)
    col = col * (0.35 + 0.65 * (1.0 - ao_w * (1.0 - ao)))[:, None]
    return np.clip(col + emis * 0.45, 0, 1)


def write_preview_glb(path, verts, normals, faces, colors):
    bufs = bytearray()
    views, accessors = [], []

    def add(arr, ctype, atype, target, minmax=False):
        arr = np.ascontiguousarray(arr)
        while len(bufs) % 4:
            bufs.append(0)
        views.append({"buffer": 0, "byteOffset": len(bufs), "byteLength": arr.nbytes, "target": target})
        bufs.extend(arr.tobytes())
        acc = {"bufferView": len(views) - 1, "componentType": ctype, "count": int(arr.shape[0]), "type": atype}
        if minmax:
            acc["min"] = arr.min(axis=0).tolist()
            acc["max"] = arr.max(axis=0).tolist()
        accessors.append(acc)
        return len(accessors) - 1

    attrs = {
        "POSITION": add(verts.astype(np.float32), 5126, "VEC3", 34962, True),
        "NORMAL": add(normals.astype(np.float32), 5126, "VEC3", 34962),
        "COLOR_0": add(colors.astype(np.float32), 5126, "VEC3", 34962),
    }
    ind = add(faces.astype(np.uint32).ravel(), 5125, "SCALAR", 34963)
    gltf = {
        "asset": {"version": "2.0", "generator": "NEXORA tools/sculpt (vista rápida)"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0}],
        "meshes": [{"primitives": [{"attributes": attrs, "indices": ind, "material": 0}]}],
        "materials": [{"pbrMetallicRoughness": {"baseColorFactor": [1, 1, 1, 1], "metallicFactor": 0.0, "roughnessFactor": 0.62}}],
        "accessors": accessors,
        "bufferViews": views,
        "buffers": [{"byteLength": len(bufs)}],
    }
    js = json.dumps(gltf, separators=(",", ":")).encode()
    while len(js) % 4:
        js += b" "
    while len(bufs) % 4:
        bufs.append(0)
    with open(path, "wb") as fh:
        fh.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(bufs)))
        fh.write(struct.pack("<II", len(js), 0x4E4F534A))
        fh.write(js)
        fh.write(struct.pack("<II", len(bufs), 0x004E4942))
        fh.write(bytes(bufs))


def _saturate(fn, amount=1.3, lift=1.08):
    def g(p):
        c = fn(p)
        m = c.mean(axis=1, keepdims=True)
        return np.clip((m + (c - m) * amount) * lift, 0, 1)

    return g


def apply_style(creature, style):
    """Direcciones visuales de la propuesta (misma anatomía, distinto acabado)."""
    if style == "juguete":
        for part in creature.parts:
            part.detail_amp = 0.0
        for m in creature.materials.values():
            orig = m.color
            if callable(orig):
                base = orig
            else:
                const = np.asarray(orig, dtype=np.float64)
                base = lambda p, c=const: np.tile(c, (len(p), 1))  # noqa: E731
            m.color = _saturate(base, 1.35, 1.1)
            m.roughness = 0.16
    return creature


def write_faceted_glb(path, v, f, colors, levels=5):
    """Estilo facetado: caras planas y paleta posterizada."""
    fv = v[f].reshape(-1, 3)
    a, b, c = v[f[:, 0]], v[f[:, 1]], v[f[:, 2]]
    fn = np.cross(b - a, c - a)
    fn = fn / np.maximum(norm(fn)[:, None], 1e-9)
    fc = colors[f].mean(axis=1)
    fc = np.round(fc * (levels - 1)) / (levels - 1) * 0.85 + fc * 0.15
    nrm_ = np.repeat(fn, 3, axis=0)
    col = np.repeat(fc, 3, axis=0)
    idx = np.arange(len(fv)).reshape(-1, 3)
    write_preview_glb(path, fv, nrm_, idx, col)


def preview(creature, path, voxel=None, max_tris=80_000):
    import os

    style = os.environ.get("SCULPT_STYLE", "artesanal")
    apply_style(creature, style)
    t0 = time.time()
    v, f = high_mesh(creature, voxel or max(creature.voxel, 0.014))
    v, f = largest_component(v, f)
    v, f = decimate(v, f, max_tris)
    v, f = clean_mesh(v, f)
    n = creature.gradient(v)
    c = vertex_colors(creature, v, n)
    import os
    if os.environ.get("SCULPT_DEBUG_PARTS"):
        _, w, _ = creature.sdf(v, want_parts=True)
        rng = np.random.RandomState(7)
        pal = rng.rand(len(creature.parts), 3) * 0.8 + 0.2
        c = pal[w]
        print("piezas:", {creature.parts[i].name: int((w == i).sum()) for i in np.unique(w)})
    # glTF: COLOR_0 es lineal; la paleta está en sRGB
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    if style == "facetado":
        v2, f2 = decimate(v, f, 1400 if creature.form == "Brote" else 2200)
        v2, f2 = clean_mesh(v2, f2)
        c2 = vertex_colors(creature, v2, creature.gradient(v2))
        c2 = np.where(c2 <= 0.04045, c2 / 12.92, ((c2 + 0.055) / 1.055) ** 2.4)
        write_faceted_glb(path, v2, f2, c2)
        return {"triangles": int(len(f2)), "seconds": round(time.time() - t0, 1)}
    write_preview_glb(path, v, n, f, c)
    return {"triangles": int(len(f)), "seconds": round(time.time() - t0, 1)}
