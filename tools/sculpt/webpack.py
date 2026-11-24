"""
Versión ligera de los activos para la vista previa web (misma geometría LOD0, texturas a
512² en JPEG). Salida: assets/Creatures/Initials/<Nombre>/web/<id>.web.glb

  python3 tools/sculpt/webpack.py
"""

from __future__ import annotations

import io
import json
import struct
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent


def read_glb(p):
    b = p.read_bytes()
    jl = struct.unpack("<I", b[12:16])[0]
    js = json.loads(b[20 : 20 + jl])
    bl = struct.unpack("<I", b[20 + jl : 24 + jl])[0]
    return js, bytearray(b[28 + jl : 28 + jl + bl])


def write_glb(p, js, buf):
    j = json.dumps(js, separators=(",", ":")).encode()
    while len(j) % 4:
        j += b" "
    while len(buf) % 4:
        buf.append(0)
    with open(p, "wb") as fh:
        fh.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(j) + 8 + len(buf)))
        fh.write(struct.pack("<II", len(j), 0x4E4F534A))
        fh.write(j)
        fh.write(struct.pack("<II", len(buf), 0x004E4942))
        fh.write(bytes(buf))


def shrink(js, buf, size=512):
    """Reescribe el buffer: geometría igual, imágenes a JPEG de `size`²."""
    views = js["bufferViews"]
    image_views = {img["bufferView"]: img for img in js["images"]}
    out = bytearray()
    new_views = []
    for i, v in enumerate(views):
        data = bytes(buf[v.get("byteOffset", 0) : v.get("byteOffset", 0) + v["byteLength"]])
        if i in image_views:
            img = image_views[i]
            im = Image.open(io.BytesIO(data)).convert("RGB").resize((size, size), Image.LANCZOS)
            b = io.BytesIO()
            q = 92 if img.get("name") == "normal" else 84
            im.save(b, format="JPEG", quality=q, optimize=True)
            data = b.getvalue()
            img["mimeType"] = "image/jpeg"
        while len(out) % 4:
            out.append(0)
        nv = dict(v)
        nv["byteOffset"] = len(out)
        nv["byteLength"] = len(data)
        out.extend(data)
        new_views.append(nv)
    js["bufferViews"] = new_views
    js["buffers"] = [{"byteLength": len(out)}]
    return js, out


def main():
    for meta in sorted((ROOT / "assets" / "Creatures").glob("**/asset.json")):
        m = json.loads(meta.read_text())
        src = meta.parent / m["files"]["glb"]
        js, buf = read_glb(src)
        js, buf = shrink(js, buf)
        out = meta.parent / "web" / f"{m['id']}.web.glb"
        out.parent.mkdir(exist_ok=True)
        write_glb(out, js, buf)
        print(f"{out.relative_to(ROOT)} · {out.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
