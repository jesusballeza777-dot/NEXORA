"""
Genera src/ReplicatedStorage/Shared/Config/CreatureAssets.luau a partir de los asset.json de
assets/Creatures (sin números escritos a mano). Los IDs de Roblox solo se rellenan cuando el
activo se importa de verdad en Studio (campo robloxAssetId del asset.json).

  python3 tools/sculpt/registry.py
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "src" / "ReplicatedStorage" / "Shared" / "Config" / "CreatureAssets.luau"


def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    entries = []
    for meta_path in sorted((ROOT / "assets" / "Creatures").glob("**/asset.json")):
        m = json.loads(meta_path.read_text())
        rel = meta_path.parent.relative_to(ROOT).as_posix()
        lod0 = m["lods"]["LOD0"]
        entries.append((m, rel, lod0))
    lines = [
        "--!strict",
        "-- Registro de activos 3D de criaturas (Fase 3). GENERADO por tools/sculpt/registry.py",
        "-- a partir de assets/Creatures/**/asset.json: no se edita a mano.",
        "-- * status: Blockout | Proposal | InReview | Approved | Final (Biblia visual §11). Solo",
        "--   una persona pasa un activo a Approved o Final.",
        "-- * roblox: IDs reales tras importar en Studio. Mientras estén vacíos, CreatureBuilder",
        "--   sigue usando el blockout de Parts (Config/Visuals). No se inventan IDs.",
        "",
        "local Freeze = require(script.Parent.Parent.Util.Freeze)",
        "",
        "export type RobloxRefs = {",
        "\tmeshAsset: string?,",
        "\tcolorMap: string?,",
        "\tnormalMap: string?,",
        "\troughnessMap: string?,",
        "\tmetalnessMap: string?,",
        "}",
        "",
        "export type CreatureAsset = {",
        "\tid: string,",
        "\tspecies: string,",
        "\tform: string,",
        "\tstatus: string,",
        "\tfolder: string,",
        "\tglb: string,",
        "\ttriangles: number,",
        "\ttriangleBudget: { number },",
        "\tbones: number,",
        "\tboneBudget: number,",
        "\tsizeStuds: { number },",
        "\ttexture: string,",
        "\troblox: RobloxRefs,",
        "}",
        "",
        "local ById: { [string]: CreatureAsset } = {",
    ]
    order = []
    for m, rel, lod0 in entries:
        key = f"{m['species']}:{m['form']}"
        order.append(key)
        rid = m.get("robloxAssetId")
        size = ", ".join(str(x) for x in lod0["sizeStuds"])
        lines += [
            f"\t[{lua_str(key)}] = {{",
            f"\t\tid = {lua_str(m['id'])},",
            f"\t\tspecies = {lua_str(m['species'])},",
            f"\t\tform = {lua_str(m['form'])},",
            f"\t\tstatus = {lua_str(m['status'])},",
            f"\t\tfolder = {lua_str(rel)},",
            f"\t\tglb = {lua_str(rel + '/' + m['files']['glb'])},",
            f"\t\ttriangles = {lod0['triangles']},",
            f"\t\ttriangleBudget = {{ {m['budget']['triangles'][0]}, {m['budget']['triangles'][1]} }},",
            f"\t\tbones = {len(m['bones'])},",
            f"\t\tboneBudget = {m['budget']['bones']},",
            f"\t\tsizeStuds = {{ {size} }},",
            f"\t\ttexture = {lua_str(lod0['texture'])},",
            "\t\troblox = {" + (f" meshAsset = {lua_str(rid)} " if rid else "") + "},",
            "\t},",
        ]
    lines += ["}", "", "return Freeze.deep({", "\tById = ById,", "\tOrder = {"]
    lines += [f"\t\t{lua_str(k)}," for k in order]
    lines += [
        "\t},",
        "})",
        "",
    ]
    OUT.write_text("\n".join(lines))
    print(f"{OUT.relative_to(ROOT)} · {len(entries)} activos")


if __name__ == "__main__":
    main()
