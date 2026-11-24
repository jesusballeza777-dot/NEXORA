"""
CLI del escultor de NEXORA.

  python3 tools/sculpt/build.py preview kuachi brote [expresión]   → vista rápida (GLB con color por vértice)
  python3 tools/sculpt/build.py asset kuachi brote                → activo completo en assets/Creatures/Initials/
  python3 tools/sculpt/build.py all                               → los seis activos iniciales

Requisitos: numpy, scikit-image, fast-simplification, xatlas, pillow (tools/sculpt/requirements.txt).
"""

from __future__ import annotations

import importlib
import json
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
ROOT = HERE.parent.parent

import pipeline  # noqa: E402

SPECIES = {
    "kuachi": ("Kuachi", "Ascuacho"),
    "xolumi": ("Xolumi", "Xolossus"),
    "teselo": ("Teselo", "Mitlaxis"),
}


def make(species, form, expr="neutral", variant=None):
    mod = importlib.import_module(f"species.{species}")
    fn = getattr(mod, form.lower())
    kw = {"expr": expr}
    if variant:
        kw["variant"] = variant
    return fn(**kw)


def asset_dir(species, form):
    brote, tallado = SPECIES[species]
    name = brote if form.lower() == "brote" else tallado
    return ROOT / "assets" / "Creatures" / "Initials" / name, name


def build_asset(species, form):
    c = make(species, form)
    out, name = asset_dir(species, form)
    print(f"▸ {c.id} ({name})")
    res = pipeline.build_asset(c, out)
    meta = {
        "id": c.id,
        "name": name,
        "species": c.species,
        "form": c.form,
        "version": 1,
        "status": "Proposal",
        "approval": "Pendiente de aprobación humana (docs/ART_BIBLE_GENESIS.md §11)",
        "provenance": "Esculpido procedural con tools/sculpt (campos de distancia → marching cubes → simplificación → UV xatlas → horneado PBR). Sin herramientas externas de IA.",
        "rarity": c.rarity,
        "elements": list(c.elements),
        "family": c.family,
        "biome": "ValleCopal",
        "units": "studs (Y arriba, mira hacia +Z)",
        "budget": {"triangles": list(c.tri_budget), "bones": c.bone_budget, "texture": "1024x1024"},
        "bones": [{"name": b.name, "parent": b.parent, "head": list(b.head)} for b in c.bones],
        "lods": {k: v for k, v in res.items() if k.startswith("LOD")},
        "highPolyTriangles": res["highPolyTriangles"],
        "maps": {
            "ColorMap": f"textures/{c.id}_color.png",
            "NormalMap": f"textures/{c.id}_normal.png",
            "RoughnessMap": f"textures/{c.id}_roughness.png",
            "MetalnessMap": f"textures/{c.id}_metalness.png",
            "EmissiveMask": f"textures/{c.id}_emissive.png",
        },
        "files": {"glb": f"{c.id}.glb", "glbLod1": f"{c.id}_LOD1.glb", "obj": f"{c.id}.obj"},
        "dependencies": [],
        "robloxAssetId": None,
        "notes": c.notes,
        "builtAt": time.strftime("%Y-%m-%d"),
    }
    (out / "asset.json").write_text(json.dumps(meta, indent=2, ensure_ascii=False) + "\n")
    return meta


def main(argv):
    if not argv:
        print(__doc__)
        return 1
    cmd = argv[0]
    if cmd == "preview":
        species, form = argv[1], argv[2]
        expr = argv[3] if len(argv) > 3 else "neutral"
        variant = argv[4] if len(argv) > 4 else None
        out = Path(argv[5]) if len(argv) > 5 else ROOT / "build" / "sculpt" / f"{species}_{form}_{expr}{'_' + variant if variant else ''}.glb"
        out.parent.mkdir(parents=True, exist_ok=True)
        c = make(species, form, expr, variant)
        st = pipeline.preview(c, out)
        print(f"{out} · {st['triangles']:,} tri · {st['seconds']} s")
        return 0
    if cmd == "asset":
        build_asset(argv[1], argv[2])
        return 0
    if cmd == "all":
        for sp in SPECIES:
            for form in ("brote", "tallado"):
                build_asset(sp, form)
        return 0
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
