"""
Teselo → Mitlaxis (Tierra · Común · Defensor · reptil, tortuga terrestre · Valle Copal).

Biblia p. 51: tortuga terrestre con caparazón de grecas, como los mosaicos de piedra de Mitla.
Brote: caparazón alto de teselas pulidas, patas columnares y cara curiosa; sin vegetación ni
picos. Tallado: tortuga-fortaleza con caparazón de grecas en terrazas y anillos de astrolabio que
giran; sobre el lomo flota un disco de cielo nocturno. Claves 2D: domo escalonado, anillos
dorados, piedra ocre y jade.

Paletas y proporciones del dosier docs/art/dossiers/TESELO.md (propuesta). Originalidad: no es
una tortuga con árbol ni con cañones; la firma es el domo escalonado + anillos + disco.
"""

from __future__ import annotations

import numpy as np

from core import Bone, Creature, Material, capsule, cone, custom, cylinder, ellipsoid, hexc, sphere, spike, torus
from sdf import euler, fbm, greca_2d, norm, sd_ellipsoid, smax, voronoi
from species.common import eye_material, lid, mix, smile, surface_points

EXPRESSIONS = {
    "neutral": dict(upper=0.86, lower=0.10, tilt=0, smile=1.0, head=0.0, brow=0),
    "desafio": dict(upper=0.62, lower=0.18, tilt=8, smile=0.2, head=0.04, brow=-10),
    "ataque": dict(upper=0.70, lower=0.14, tilt=10, smile=-0.2, head=0.08, brow=-16),
    "victoria": dict(upper=0.48, lower=0.32, tilt=-6, smile=1.7, head=0.02, brow=6),
    "cansado": dict(upper=0.34, lower=0.10, tilt=-12, smile=-0.5, head=-0.20, brow=10),
    "carino": dict(upper=0.30, lower=0.34, tilt=-4, smile=1.3, head=0.0, brow=4),
}


def _dome(c, radii, cut_y, k=0.06):
    c = np.asarray(c, dtype=np.float64)

    def fn(p):
        return smax(sd_ellipsoid(p, c, radii), cut_y - p[:, 1], k)

    return fn


def _tile_color(scale, base, light, jade, joint, joint_w=0.035):
    b, l, j, jt = (np.asarray(hexc(x)) for x in (base, light, jade, joint))

    def f(p):
        f1, f2, cid = voronoi(p, scale)
        col = np.tile(b, (len(p), 1))
        col[cid > 0.62] = l
        col[cid > 0.86] = j
        col = col * (0.92 + 0.16 * fbm(p, 9.0, 1))[:, None]
        edge = np.clip((joint_w - (f2 - f1)) / joint_w, 0, 1)
        return mix(col, jt, edge)

    return f


def _tile_detail(scale, joint_w=0.035):
    def f(p):
        f1, f2, _ = voronoi(p, scale)
        # juntas hundidas entre teselas (negativo = hacia dentro) y teselas un poco abombadas
        return -np.clip((joint_w - (f2 - f1)) / joint_w, 0, 1) + 0.25 * np.clip((f2 - f1) / 0.2, 0, 1)

    return f


def brote(expr="neutral"):
    e = EXPRESSIONS[expr]
    hz = e["head"]
    head_c = np.array([0.0, 0.80, 1.30 + hz])
    eye_c = (0.185, 0.89, 1.565 + hz)
    look = (0.35, 0.05, 1.0)

    def skin_col(p):
        col = mix(np.asarray(hexc("#8E7A5C")), np.asarray(hexc("#B9A47E")), np.clip((0.75 - p[:, 1]) * 3, 0, 1))
        f1, f2, _ = voronoi(p, 14.0)
        return col * (0.9 + 0.18 * np.clip((f2 - f1) * 20, 0, 1))[:, None]

    def face_col(p):
        col = skin_col(p)
        q = p - head_c
        q[:, 0] = np.abs(q[:, 0])
        blush = norm((q - np.array([0.20, -0.05, 0.22])) * np.array([1, 1.6, 1])) < 0.06
        col[blush] = mix(col[blush], np.asarray(hexc("#FF929E")), np.full(int(blush.sum()), 0.5))
        return col

    mats = {
        "shell": Material("shell", _tile_color(3.6, "#9C8462", "#C4A87A", "#3E967A", "#786248"), roughness=0.32),
        "rim": Material("rim", lambda p: np.tile(np.asarray(hexc("#C4A87A")), (len(p), 1)) * (0.95 + 0.1 * fbm(p, 12, 1))[:, None], roughness=0.45),
        "skin": Material("skin", skin_col, roughness=0.7),
        "face": Material("face", face_col, roughness=0.65),
        "nail": Material("nail", hexc("#E8DCC4"), roughness=0.4),
        "eye": eye_material("eye", eye_c, look, iris="#161412", sclera="#F6EEDC", pupil="#0A0908", iris_ang=1.02, pupil_ang=0.9, rim="#0A0908"),
        "mouth": Material("mouth", hexc("#281816"), roughness=0.6, ao=0.5),
    }

    P = []
    # --- caparazón alto de teselas pulidas (60 % de la altura) ---
    P.append(custom("shell", _dome((0, 0.86, -0.05), (0.95, 0.90, 1.22), 0.52), (0, 0.86, -0.05), 1.35, mat="shell", bone="body", detail=_tile_detail(3.6), detail_amp=0.022))
    P.append(ellipsoid("rim", (0, 0.54, -0.05), (0.99, 0.11, 1.26), mat="rim", k=0.05, bone="body"))
    P.append(ellipsoid("plastron", (0, 0.46, -0.02), (0.80, 0.22, 1.05), mat="rim", k=0.06, bone="body"))
    # --- cuello y cabeza curiosa ---
    P.append(cone("neck", (0, 0.66, 0.85), (0, 0.78, 1.18 + hz), 0.25, 0.22, mat="skin", k=0.10, bone="neck"))
    P.append(ellipsoid("head", head_c, (0.38, 0.35, 0.36), mat="face", k=0.12, bone="head"))
    P.append(ellipsoid("beak", (0, 0.73, 1.60 + hz), (0.18, 0.12, 0.10), mat="face", k=0.08, bone="head"))
    P.append(sphere("eye", eye_c, 0.11, mat="eye", k=0.012, bone="head", mirror=True))
    P.append(lid("lidUp", eye_c, 0.121, look, e["upper"], tilt=e["tilt"], mat="face", bone="head"))
    P.append(lid("lidLow", eye_c, 0.119, look, 1 - e["lower"], tilt=-e["tilt"] * 0.5, lower=True, mat="face", bone="head"))
    sm = e["smile"]
    mp = surface_points(P, [(0.0, 0.71, 1.70 + hz), (0.10, 0.71 - 0.008 * sm, 1.67 + hz), (0.19, 0.75 + 0.02 * sm, 1.58 + hz)])
    P.append(smile("mouth", mp[0], mp[1], mp[2], 0.014, mirror=True, bone="head"))
    # --- patas columnares con uñas ---
    for nm, x, z in (("legF", 0.64, 0.70), ("legB", 0.64, -0.78)):
        bone = nm + "_*"
        P.append(cylinder(nm, (x, 0.26, z), 0.24, 0.26, round_r=0.09, mat="skin", k=0.10, bone=bone, mirror=True))
        for i, dx in enumerate((-0.10, 0.0, 0.10)):
            P.append(sphere(f"{nm}Nail{i}", (x + dx, 0.05, z + 0.21), 0.05, mat="nail", k=0.02, bone=bone, mirror=True))
    P.append(cone("tail", (0, 0.50, -1.20), (0, 0.40, -1.45), 0.10, 0.03, mat="skin", k=0.06, bone="body"))

    bones = [
        Bone("root", None, (0, 0, 0)),
        Bone("body", "root", (0, 0.70, -0.05)),
        Bone("neck", "body", (0, 0.66, 0.85)),
        Bone("head", "neck", (0, 0.80, 1.20)),
        Bone("legF_L", "body", (0.60, 0.55, 0.72)),
        Bone("legF_R", "body", (-0.60, 0.55, 0.72)),
        Bone("legB_L", "body", (0.60, 0.55, -0.80)),
        Bone("legB_R", "body", (-0.60, 0.55, -0.80)),
    ]
    return Creature(
        id="CR_Teselo_Brote_v01",
        display="Teselo",
        species="teselo",
        form="Brote",
        rarity="Comun",
        elements=("Tierra",),
        family="ReptilAcorazado",
        parts=P,
        materials=mats,
        bones=bones,
        tri_budget=(2500, 4000),
        bone_budget=18,
        voxel=0.013,
        notes="Caparazón alto de teselas pulidas (ocre, crema y jade), patas columnares, cara curiosa; sin vegetación ni picos.",
        meta={"expression": expr},
    )


# ---------------------------------------------------------------------------
# Tallado · Mitlaxis
# ---------------------------------------------------------------------------
TALLADO_EXPRESSIONS = {
    "neutral": dict(upper=0.60, lower=0.24, tilt=12, brow=0, open=0.0, head=0.0),
    "desafio": dict(upper=0.50, lower=0.28, tilt=16, brow=-8, open=0.0, head=0.05),
    "ataque": dict(upper=0.64, lower=0.22, tilt=18, brow=-14, open=1.0, head=0.10),
    "victoria": dict(upper=0.44, lower=0.34, tilt=8, brow=6, open=0.3, head=0.03),
    "cansado": dict(upper=0.32, lower=0.18, tilt=2, brow=10, open=0.0, head=-0.30),
    "carino": dict(upper=0.30, lower=0.36, tilt=6, brow=8, open=0.0, head=0.0),
}

STONE = "#786248"
LIGHT = "#B09264"
JADE = "#348A70"
GOLD = "#ECC460"
SKY = "#1C2446"
STAR = "#F6D26E"


def _tier(c, radii, half_h, k=0.05):
    """Terraza del caparazón: elipsoide alargado recortado por dos planos (losa redondeada)."""
    c = np.asarray(c, dtype=np.float64)
    big = (radii[0], half_h * 3.0, radii[2])

    def fn(p):
        d = sd_ellipsoid(p, c, big)
        return smax(d, np.abs(p[:, 1] - c[1]) - half_h, k)

    return fn


def _greca_mask(c_y, half_h, radius, cell=0.30):
    def m(p):
        ang = np.arctan2(p[:, 0], p[:, 2])
        u = ang * radius
        w = p[:, 1] - c_y
        band = np.abs(w) < half_h * 0.62
        return greca_2d(u, w + half_h, cell=cell, line=0.17) * band

    return m


def tallado(expr="neutral"):
    e = TALLADO_EXPRESSIONS[expr]
    hz = e["head"]
    head_c = np.array([0.0, 1.26, 2.05 + hz])
    eye_c = (0.25, 1.40, 2.36 + hz)
    look = (0.50, 0.04, 1.0)
    tiers = [((0, 1.18, -0.05), (1.42, 0, 1.86), 0.32), ((0, 1.74, -0.10), (1.10, 0, 1.44), 0.25), ((0, 2.15, -0.12), (0.76, 0, 1.00), 0.18)]
    masks = [_greca_mask(c[1], h, (r[0] + r[2]) * 0.5) for c, r, h in tiers]

    def stone_col(p):
        col = np.tile(np.asarray(hexc(STONE)), (len(p), 1)) * (0.9 + 0.2 * fbm(p, 6.0, 2))[:, None]
        g = np.zeros(len(p))
        for m in masks:
            g = np.maximum(g, m(p))
        col = mix(col, np.asarray(hexc(GOLD)) * 0.9, g)
        # cornisa clara en el borde superior de cada terraza
        for c, r, h in tiers:
            top = np.clip(1 - np.abs(p[:, 1] - (c[1] + h)) * 14, 0, 1)
            col = mix(col, np.asarray(hexc(LIGHT)), top * 0.8)
        return col

    def stone_emis(p):
        g = np.zeros(len(p))
        for m in masks:
            g = np.maximum(g, m(p))
        return np.outer(g * 0.6, hexc(STAR))

    def greca_detail(p):
        g = np.zeros(len(p))
        for m in masks:
            g = np.maximum(g, m(p))
        return -g

    def top_col(p):
        return _tile_color(3.0, LIGHT, "#C8A878", JADE, STONE, 0.03)(p)

    def sky_col(p):
        col = np.tile(np.asarray(hexc(SKY)), (len(p), 1))
        n = fbm(p, 3.0, 2)
        col = mix(col, np.asarray(hexc("#3A3A7A")), np.clip(n + 0.2, 0, 1) * 0.5)
        f1, _, cid = voronoi(p, 9.0, 0.9)
        star = (f1 < 0.018) & (cid > 0.5)
        col[star] = hexc(STAR)
        return col

    def sky_emis(p):
        f1, _, cid = voronoi(p, 9.0, 0.9)
        star = ((f1 < 0.018) & (cid > 0.5)).astype(np.float64)
        return np.outer(star, hexc(STAR))

    def skin_col(p):
        col = mix(np.asarray(hexc("#6E5A42")), np.asarray(hexc("#9C8462")), np.clip((1.1 - p[:, 1]) * 2, 0, 1))
        f1, f2, _ = voronoi(p, 9.0)
        return col * (0.86 + 0.24 * np.clip((f2 - f1) * 14, 0, 1))[:, None]

    mats = {
        "stone": Material("stone", stone_col, roughness=0.8, emissive=stone_emis, emissive_strength=0.5),
        "top": Material("top", top_col, roughness=0.35),
        "rim": Material("rim", hexc(LIGHT), roughness=0.6),
        "skin": Material("skin", skin_col, roughness=0.75),
        "face": Material("face", skin_col, roughness=0.7),
        "plate": Material("plate", hexc(JADE), roughness=0.3),
        "gold": Material("gold", hexc(GOLD), roughness=0.28, metalness=0.85),
        "nail": Material("nail", hexc("#5A4A38"), roughness=0.6),
        "beak": Material("beak", hexc("#4A3C2C"), roughness=0.45),
        "sky": Material("sky", sky_col, roughness=0.2, emissive=sky_emis, emissive_strength=1.0),
        "eye": eye_material("eye", eye_c, look, iris="#CE963C", sclera="#F6EEDC", pupil="#1A1006", iris_ang=0.8, slit=(0.12, 0.5), rim="#5A3A10", glints=((-0.3, 0.3, 0.1),), glow=0.3),
        "mouth": Material("mouth", hexc("#281816"), roughness=0.6, ao=0.5),
    }

    P = []
    # --- cuerpo y fortaleza escalonada de grecas ---
    P.append(ellipsoid("body", (0, 0.86, 0.0), (1.22, 0.42, 1.62), mat="skin", bone="body"))
    for i, (c, r, h) in enumerate(tiers):
        P.append(custom(f"tier{i}", _tier(c, r, h), c, float(max(r)) + h, mat="stone", k=0.05 if i else 0.10, bone="body", detail=greca_detail, detail_amp=0.03))
    P.append(custom("cap", _dome((0, 2.20, -0.12), (0.62, 0.30, 0.82), 2.30), (0, 2.3, -0.12), 0.9, mat="top", k=0.05, bone="body", detail=_tile_detail(3.0, 0.03), detail_amp=0.018))
    P.append(ellipsoid("skirt", (0, 0.88, -0.05), (1.46, 0.10, 1.90), mat="rim", k=0.04, bone="body"))
    # --- anillos de astrolabio (giran: huesos propios) ---
    P.append(torus("ringA", (0, 1.62, -0.08), 2.15, 0.075, R=euler(x=20), mat="gold", bone="ringA"))
    P.append(torus("ringB", (0, 1.82, -0.10), 1.95, 0.065, R=euler(z=-20, x=-6), mat="gold", bone="ringB"))
    for ang in (0, 90, 180, 270):
        # marcas de grados del astrolabio sobre el anillo exterior
        Ra = euler(x=20)
        pos = np.array([0, 1.62, -0.08]) + Ra @ (euler(y=ang) @ np.array([0, 0, 2.15]))
        P.append(sphere(f"ringMark{ang}", pos, 0.09, mat="gold", k=0.03, bone="ringA"))
    # --- disco de cielo nocturno flotante con aro de oro ---
    disc_c = np.array([0, 2.95, -0.20])
    P.append(cylinder("skyDisc", disc_c, 0.88, 0.06, R=euler(x=32), round_r=0.03, mat="sky", bone="skyDisc"))
    P.append(torus("skyRim", disc_c, 0.88, 0.05, R=euler(x=32), mat="gold", k=0.02, bone="skyDisc"))
    # --- cuello y cabeza fuerte con pico córneo ---
    P.append(cone("neck", (0, 1.00, 1.45), (0, 1.18, 1.85 + hz), 0.40, 0.34, mat="skin", k=0.12, bone="neck"))
    P.append(ellipsoid("head", head_c, (0.52, 0.44, 0.52), mat="face", k=0.12, bone="head"))
    P.append(ellipsoid("beak", (0, 1.15, 2.42 + hz), (0.24, 0.17, 0.17), mat="beak", k=0.06, bone="head"))
    P.append(spike("beakHook", (0, 1.16, 2.50 + hz), (0, 1.03, 2.62 + hz), 0.08, mat="beak", k=0.05, bone="head"))
    P.append(ellipsoid("mouthCut", (0, 1.07 - 0.03 * e["open"], 2.40 + hz), (0.22, 0.015 + 0.05 * e["open"], 0.18), mat="mouth", op="sub", k=0.015, bone="jaw"))
    # corona de placas de jade con filete de oro en la frente (greca pequeña)
    P.append(ellipsoid("crestPlate", (0, 1.62, 2.10 + hz), (0.22, 0.06, 0.24), R=euler(x=-15), mat="plate", k=0.05, bone="head"))
    P.append(ellipsoid("cheekPlate", (0.36, 1.30, 2.12 + hz), (0.06, 0.16, 0.20), R=euler(y=20), mat="plate", k=0.05, bone="head", mirror=True))
    # ojos almendrados con ceja de piedra
    P.append(sphere("eye", eye_c, 0.095, mat="eye", k=0.01, bone="head", mirror=True))
    P.append(lid("lidUp", eye_c, 0.106, look, e["upper"], tilt=e["tilt"], mat="face", bone="head"))
    P.append(lid("lidLow", eye_c, 0.104, look, 1 - e["lower"], tilt=-e["tilt"] * 0.6, lower=True, mat="face", bone="head"))
    bR = euler(z=e["brow"])
    P.append(capsule("brow", np.array(eye_c) + bR @ np.array([-0.11, 0.08, 0.0]), np.array(eye_c) + bR @ np.array([0.09, 0.11, -0.08]), 0.045, mat="face", k=0.08, bone="head", mirror=True))
    # --- patas-columna de piedra con uñas de piedra ---
    for nm, z in (("legF", 1.05), ("legB", -1.15)):
        bone = nm + "_*"
        P.append(cylinder(nm, (0.98, 0.46, z), 0.36, 0.46, round_r=0.10, mat="skin", k=0.12, bone=bone, mirror=True))
        P.append(torus(nm + "Band", (0.98, 0.62, z), 0.36, 0.05, mat="gold", k=0.02, bone=bone, mirror=True))
        for i, dx in enumerate((-0.15, 0.0, 0.15)):
            P.append(ellipsoid(f"{nm}Nail{i}", (0.98 + dx, 0.07, z + 0.32), (0.07, 0.06, 0.09), mat="nail", k=0.03, bone=bone, mirror=True))
    P.append(cone("tail", (0, 0.80, -1.65), (0, 0.55, -2.10), 0.18, 0.05, mat="skin", k=0.08, bone="body"))

    bones = [
        Bone("root", None, (0, 0, 0)),
        Bone("body", "root", (0, 1.00, 0.0)),
        Bone("neck", "body", (0, 1.00, 1.45)),
        Bone("head", "neck", (0, 1.20, 1.90)),
        Bone("jaw", "head", (0, 1.08, 2.20)),
        Bone("legF_L", "body", (0.98, 0.90, 1.05)),
        Bone("legF_R", "body", (-0.98, 0.90, 1.05)),
        Bone("legB_L", "body", (0.98, 0.90, -1.15)),
        Bone("legB_R", "body", (-0.98, 0.90, -1.15)),
        Bone("ringA", "body", (0, 1.62, -0.08)),
        Bone("ringB", "body", (0, 1.82, -0.10)),
        Bone("skyDisc", "body", (0, 2.88, -0.12)),
    ]
    return Creature(
        id="CR_Mitlaxis_Tallado_v01",
        display="Mitlaxis",
        species="teselo",
        form="Tallado",
        rarity="Comun",
        elements=("Tierra",),
        family="ReptilAcorazado",
        parts=P,
        materials=mats,
        bones=bones,
        tri_budget=(4000, 6500),
        bone_budget=30,
        voxel=0.018,
        notes="Fortaleza de tres terrazas con grecas talladas (luz en los surcos), anillos de astrolabio con huesos propios, disco de cielo nocturno flotante, placas de jade.",
        meta={"expression": expr},
    )
