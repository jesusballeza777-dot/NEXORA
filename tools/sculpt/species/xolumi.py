"""
Xolumi → Xolossus (Agua · Común · Soporte · anfibio · Valle Copal).

Biblia p. 50: ajolote de barro negro bruñido que se regenera; su tema es transformarse para
no desaparecer (solo el tema, sin la deidad). Brote: cabeza ancha y sonrisa tranquila; tres
pares de branquias plumosas turquesa; piel negra pulida como cerámica de San Bartolo
Coyotepec. Tallado: ajolote colosal de seis patas, erguido como un dragón de río; branquias de
humo de copal, cicatrices doradas y boca con colmillos pequeños.

Paletas y proporciones del dosier docs/art/dossiers/XOLUMI.md (propuesta). Originalidad: no es
un anfibio azul con burbujas; la lectura viene del negro bruñido, la cabeza ancha y las
branquias. El oro es de reparación (kintsugi), nunca heridas.
"""

from __future__ import annotations

import numpy as np

from core import Bone, Creature, Material, capsule, cone, ellipsoid, hexc, sphere, spike, tube
from sdf import bezier_point, euler, fbm, norm
from species.common import (
    bezier_samples,
    eye_material,
    lid,
    mix,
    polyline_groove,
    smile,
    surface_points,
)

EXPRESSIONS = {
    "neutral": dict(upper=0.84, lower=0.10, tilt=0, smile=1.0, open=0.0, gills=0),
    "desafio": dict(upper=0.62, lower=0.16, tilt=8, smile=0.3, open=0.0, gills=-10),
    "ataque": dict(upper=0.72, lower=0.12, tilt=10, smile=0.0, open=1.0, gills=-18),
    "victoria": dict(upper=0.46, lower=0.32, tilt=-6, smile=1.6, open=0.4, gills=14),
    "cansado": dict(upper=0.36, lower=0.10, tilt=-12, smile=-0.4, open=0.0, gills=22),
    "carino": dict(upper=0.30, lower=0.34, tilt=-4, smile=1.3, open=0.0, gills=8),
}


def _gill_material(name, head_c, base, tip, glow, reach=0.45, start=0.45):
    head_c = np.asarray(head_c)
    b, t = np.asarray(hexc(base)), np.asarray(hexc(tip))

    def color(p):
        f = np.clip((norm(p - head_c) - start) / reach, 0, 1)
        return mix(b, t, f) * (1 + 0.06 * fbm(p, 20, 1))[:, None]

    def emis(p):
        f = np.clip((norm(p - head_c) - start) / reach, 0, 1)
        return np.outer(f ** 3, t)

    return Material(name, color, roughness=0.6, emissive=emis, emissive_strength=glow)


def _skin(base, belly, y_belly, gloss=0.28, spots=None):
    b, w = np.asarray(hexc(base)), np.asarray(hexc(belly))

    def color(p):
        col = mix(b, w, np.clip((y_belly - p[:, 1]) * 5, 0, 1))
        n = fbm(p, 6.0, 2)
        col = col * (1 + 0.10 * n)[:, None]
        if spots is not None:
            s = fbm(p, 11.0, 1)
            col = mix(col, np.asarray(hexc(spots)), (s > 0.45).astype(float) * 0.5)
        return col

    return Material("skin", color, roughness=gloss)


def brote(expr="neutral"):
    e = EXPRESSIONS[expr]
    head_c = np.array([0.0, 0.58, 0.40])
    eye_c = (0.32, 0.69, 0.625)
    look = (0.62, 0.10, 1.0)

    def face(p):
        col = _skin("#22242A", "#3A3E48", 0.40, spots="#2E3440").color(p)
        q = p - head_c
        q[:, 0] = np.abs(q[:, 0])
        blush = norm((q - np.array([0.30, -0.06, 0.25])) * np.array([1, 1.6, 1])) < 0.075
        col[blush] = mix(col[blush], np.asarray(hexc("#FF929E")), np.full(int(blush.sum()), 0.55))
        return col

    mats = {
        "skin": _skin("#22242A", "#3A3E48", 0.40, spots="#2E3440"),
        "face": Material("face", face, roughness=0.26),
        "fin": Material("fin", lambda p: mix(np.asarray(hexc("#22242A")), np.asarray(hexc("#2E5A5C")), np.clip((p[:, 1] - 0.55) * 4, 0, 1)), roughness=0.4),
        "gill": _gill_material("gill", head_c, "#40CEC4", "#6EECDC", 0.35, reach=0.42, start=0.48),
        "eye": eye_material("eye", eye_c, look, iris="#0E0E10", sclera="#FAFAF6", pupil="#0E0E10", iris_ang=1.05, pupil_ang=1.0, rim="#0E0E10"),
        "mouth": Material("mouth", hexc("#EC96A0"), roughness=0.5, ao=0.5),
    }

    P = []
    P.append(ellipsoid("body", (0, 0.42, -0.30), (0.34, 0.29, 0.58), mat="skin", bone="spine"))
    P.append(ellipsoid("head", head_c, (0.50, 0.33, 0.40), mat="face", k=0.20, bone="head"))
    P.append(ellipsoid("jowl", (0.26, 0.48, 0.52), (0.22, 0.18, 0.22), mat="face", k=0.12, bone="head", mirror=True))
    # cola de aleta alta y aleta dorsal
    P.append(ellipsoid("tail", (0, 0.45, -1.02), (0.08, 0.22, 0.52), R=euler(x=-6), mat="skin", k=0.14, bone="tail1"))
    P.append(ellipsoid("dorsal", (0, 0.63, -0.62), (0.03, 0.12, 0.58), R=euler(x=-4), mat="fin", k=0.07, bone="tail1"))
    P.append(ellipsoid("tailFin", (0, 0.47, -1.20), (0.025, 0.30, 0.48), mat="fin", k=0.05, bone="tail2"))
    # ojos muy separados en los bordes de la cabeza ancha, con párpados suaves
    P.append(sphere("eye", eye_c, 0.105, mat="eye", k=0.012, bone="head", mirror=True))
    P.append(lid("lidUp", eye_c, 0.115, look, e["upper"], tilt=e["tilt"], mat="face", bone="head"))
    P.append(lid("lidLow", eye_c, 0.113, look, 1 - e["lower"], tilt=-e["tilt"] * 0.5, lower=True, mat="face", bone="head"))
    # sonrisa ancha y tranquila (rosa sobre negro)
    sm = e["smile"]
    mpts = surface_points(P, [(0.0, 0.452, 0.79), (0.17, 0.452 - 0.006 * sm, 0.768), (0.32, 0.505 + 0.03 * sm, 0.655)])
    P.append(smile("mouth", mpts[0], mpts[1], mpts[2], 0.018, mirror=True, bone="head"))
    if e["open"] > 0:
        P.append(ellipsoid("mouthOpen", (0, 0.455, 0.76), (0.16, 0.02 + 0.04 * e["open"], 0.06), mat="mouth", op="sub", k=0.02, bone="head"))
    # tres pares de branquias plumosas: tallo curvo + filamentos
    g = np.radians(e["gills"])
    gills = [
        ((0.40, 0.76, 0.22), (0.53, 0.98, 0.12), (0.60, 1.14, -0.02), (0.58, 1.22, -0.13)),
        ((0.46, 0.63, 0.20), (0.66, 0.72, 0.12), (0.80, 0.78, 0.00), (0.86, 0.82, -0.09)),
        ((0.44, 0.50, 0.24), (0.62, 0.44, 0.15), (0.74, 0.38, 0.05), (0.80, 0.36, -0.05)),
    ]
    for gi, pts in enumerate(gills):
        pts = [np.array(x) for x in pts]
        # las branquias se levantan o se pegan según la expresión (giro alrededor de su base)
        Rg = euler(z=-np.degrees(g) * (1 if gi == 0 else 0.6))
        pts = [pts[0] + Rg @ (x - pts[0]) for x in pts]
        P.append(tube(f"gill{gi}", pts, 0.05, 0.028, segments=10, mat="gill", k=0.04, bone="head", mirror=True))
        for fi, t in enumerate(np.linspace(0.32, 0.95, 5)):
            a = bezier_point(pts, t)
            tan = bezier_point(pts, min(1, t + 0.03)) - bezier_point(pts, t - 0.03)
            tan = tan / np.linalg.norm(tan)
            side = np.cross(tan, np.array([0.0, 0.0, 1.0]))
            side = side / max(np.linalg.norm(side), 1e-6)
            sgn = 1 if fi % 2 == 0 else -1
            dirv = side * sgn * 0.8 + np.array([0, 0, -0.6])
            dirv = dirv / np.linalg.norm(dirv)
            ln = 0.075 * (1.15 - t * 0.35)
            Rf = np.column_stack([np.cross(dirv, tan) / max(np.linalg.norm(np.cross(dirv, tan)), 1e-6), tan, dirv])
            P.append(ellipsoid(f"frond{gi}{fi}", a + dirv * ln * 0.8, (0.03, 0.035, ln), R=Rf, mat="gill", k=0.03, bone="head", mirror=True))
    # patitas cortas con cuatro dedos
    for nm, a, b, hc in (
        ("legF", (0.28, 0.32, 0.12), (0.37, 0.07, 0.20), (0.39, 0.035, 0.25)),
        ("legB", (0.26, 0.32, -0.55), (0.35, 0.07, -0.50), (0.37, 0.035, -0.45)),
    ):
        bone = nm + "_*"
        P.append(cone(nm, a, b, 0.095, 0.065, mat="skin", k=0.07, bone=bone, mirror=True))
        P.append(ellipsoid(nm + "Hand", hc, (0.08, 0.035, 0.075), mat="skin", k=0.03, bone=bone, mirror=True))
        for fi, ang in enumerate((-40, -12, 15, 42)):
            d = euler(y=ang) @ np.array([0.0, 0.0, 0.09])
            P.append(capsule(f"{nm}Finger{fi}", hc, np.array(hc) + d + np.array([0, -0.01, 0]), 0.022, mat="skin", k=0.02, bone=bone, mirror=True))

    bones = [
        Bone("root", None, (0, 0, 0)),
        Bone("spine", "root", (0, 0.42, -0.30)),
        Bone("head", "spine", (0, 0.55, 0.15)),
        Bone("legF_L", "spine", (0.28, 0.32, 0.12)),
        Bone("legF_R", "spine", (-0.28, 0.32, 0.12)),
        Bone("legB_L", "spine", (0.26, 0.32, -0.55)),
        Bone("legB_R", "spine", (-0.26, 0.32, -0.55)),
        Bone("tail1", "spine", (0, 0.45, -0.70)),
        Bone("tail2", "tail1", (0, 0.45, -1.15)),
    ]
    return Creature(
        id="CR_Xolumi_Brote_v01",
        display="Xolumi",
        species="xolumi",
        form="Brote",
        rarity="Comun",
        elements=("Agua",),
        family="Anfibio",
        parts=P,
        materials=mats,
        bones=bones,
        tri_budget=(2500, 4000),
        bone_budget=18,
        voxel=0.011,
        notes="Cabeza ancha y sonrisa tranquila; tres pares de branquias plumosas; barro negro bruñido.",
        meta={"expression": expr},
    )


# ---------------------------------------------------------------------------
# Tallado · Xolossus
# ---------------------------------------------------------------------------
TALLADO_EXPRESSIONS = {
    "neutral": dict(upper=0.60, lower=0.24, tilt=14, brow=0, open=0.2),
    "desafio": dict(upper=0.48, lower=0.28, tilt=18, brow=-8, open=0.1),
    "ataque": dict(upper=0.66, lower=0.20, tilt=20, brow=-14, open=1.0),
    "victoria": dict(upper=0.44, lower=0.34, tilt=10, brow=6, open=0.35),
    "cansado": dict(upper=0.32, lower=0.18, tilt=2, brow=10, open=0.05),
    "carino": dict(upper=0.30, lower=0.36, tilt=6, brow=8, open=0.0),
}


def _kintsugi_paths(parts, seeds, rng, steps=9, step=0.07):
    """Vetas de oro de reparación: caminos quebrados sobre la superficie (deterministas)."""
    out = []
    for s in seeds:
        p = np.array(s, dtype=np.float64)
        d = rng.normal(size=3)
        pts = [p]
        for _ in range(steps):
            d = d + rng.normal(size=3) * 0.9
            d = d / np.linalg.norm(d)
            p = p + d * step
            pts.append(p)
        out.append(surface_points(parts, np.array(pts)))
    return out


def tallado(expr="neutral"):
    e = TALLADO_EXPRESSIONS[expr]
    head_c = np.array([0.0, 1.84, 1.02])
    eye_c = (0.50, 1.98, 1.30)
    look = (0.70, 0.12, 1.0)
    GOLD = "#D6AA4A"

    def fin_edge(p):
        # oro solo en el borde de las aletas (la aleta caudal y la dorsal)
        tail_edge = (np.abs(p[:, 1] - 0.62) - 0.36) * 7
        dorsal_edge = (p[:, 1] - (1.30 + 0.45 * np.clip(p[:, 2] + 0.5, 0, 1.2))) * 6
        return np.where(p[:, 2] < -1.45, tail_edge, dorsal_edge)

    mats = {
        "skin": _skin("#16181E", "#282A32", 0.75, gloss=0.24),
        "face": _skin("#16181E", "#282A32", 1.50, gloss=0.22),
        "fin": Material("fin", lambda p: mix(np.asarray(hexc("#16181E")), np.asarray(hexc(GOLD)), np.clip(fin_edge(p), 0, 1)), roughness=0.35, metalness=0.15),
        "gold": Material("gold", hexc(GOLD), roughness=0.35, metalness=0.2, emissive=hexc("#78F0E2"), emissive_strength=0.0),
        "smoke": _gill_material("smoke", head_c, "#40CEC4", "#78F0E2", 0.45, reach=0.75, start=0.55),
        "eye": eye_material("eye", eye_c, look, iris="#46C8E6", sclera="#F0ECDC", pupil="#08202A", iris_ang=0.78, slit=(0.11, 0.5), rim="#0A3A4A", glints=((-0.3, 0.3, 0.1),), glow=0.35),
        "mouth": Material("mouth", hexc("#3A1E26"), roughness=0.5, ao=0.4),
        "tooth": Material("tooth", hexc("#F0ECDC"), roughness=0.3),
    }

    P = []
    # --- cuerpo en S que se yergue 30° hacia la cabeza ---
    P.append(ellipsoid("hips", (0, 0.58, -0.95), (0.46, 0.37, 0.52), mat="skin", bone="spine"))
    P.append(ellipsoid("belly", (0, 0.74, -0.28), (0.52, 0.42, 0.62), R=euler(x=-12), mat="skin", k=0.22, bone="spine"))
    P.append(ellipsoid("chest", (0, 1.20, 0.42), (0.52, 0.52, 0.48), R=euler(x=-38), mat="skin", k=0.24, bone="chest"))
    P.append(cone("neck", (0, 1.36, 0.62), (0, 1.76, 0.92), 0.44, 0.40, mat="skin", k=0.16, bone="neck"))
    # --- cabeza ancha y plana, alta ---
    P.append(ellipsoid("head", head_c, (0.64, 0.36, 0.50), mat="face", k=0.18, bone="head"))
    P.append(ellipsoid("jowl", (0.40, 1.70, 1.14), (0.28, 0.22, 0.28), mat="face", k=0.12, bone="head", mirror=True))
    P.append(ellipsoid("jaw", (0, 1.64 - 0.05 * e["open"], 1.22), (0.46, 0.14, 0.32), R=euler(x=-6 - 10 * e["open"]), mat="face", k=0.06, bone="jaw"))
    P.append(ellipsoid("mouthCut", (0, 1.70 - 0.025 * e["open"], 1.34), (0.44, 0.022 + 0.05 * e["open"], 0.22), R=euler(x=-4), mat="mouth", op="sub", k=0.02, bone="jaw"))
    for i, x in enumerate((0.16, 0.30)):
        P.append(spike(f"fang{i}", (x, 1.725, 1.44 - i * 0.07), (x * 1.02, 1.625 - 0.04 * e["open"], 1.45 - i * 0.07), 0.03, mat="tooth", k=0.006, bone="head", mirror=True, priority=0.01))
    # ojos almendrados en el mismo sitio que en el Brote (bordes de la cabeza)
    P.append(sphere("eye", eye_c, 0.092, mat="eye", k=0.01, bone="head", mirror=True))
    P.append(lid("lidUp", eye_c, 0.103, look, e["upper"], tilt=e["tilt"], mat="face", bone="head"))
    P.append(lid("lidLow", eye_c, 0.101, look, 1 - e["lower"], tilt=-e["tilt"] * 0.6, lower=True, mat="face", bone="head"))
    bR = euler(z=e["brow"])
    P.append(capsule("brow", np.array(eye_c) + bR @ np.array([-0.10, 0.075, 0.0]), np.array(eye_c) + bR @ np.array([0.07, 0.10, -0.07]), 0.032, mat="face", k=0.08, bone="head", mirror=True))
    # --- corona de branquias de humo de copal: volutas de bocanadas que se enroscan ---
    crowns = [
        [(0.50, 2.04, 0.84), (0.74, 2.46, 0.74), (0.80, 2.76, 0.42), (0.62, 2.80, 0.22)],
        [(0.60, 1.92, 0.80), (0.98, 2.16, 0.62), (1.18, 2.36, 0.32), (1.06, 2.50, 0.12)],
        [(0.60, 1.78, 0.82), (1.00, 1.74, 0.64), (1.20, 1.84, 0.38), (1.14, 2.00, 0.20)],
    ]
    rngp = np.random.RandomState(5)
    for ci, pts in enumerate(crowns):
        P.append(tube(f"smokeStem{ci}", pts, 0.06, 0.03, segments=12, mat="smoke", k=0.06, bone="head", mirror=True))
        for j, t in enumerate(np.linspace(0.18, 1.0, 9)):
            c0 = bezier_point(pts, t) + rngp.normal(size=3) * 0.025
            P.append(sphere(f"puff{ci}{j}", c0, 0.13 * (1.2 - t * 0.6), mat="smoke", k=0.07, bone="head", mirror=True))
        # rizo final de la voluta
        end = np.array(pts[-1])
        curl = [end, end + np.array([-0.10, 0.10, -0.06]), end + np.array([-0.22, 0.02, -0.06]), end + np.array([-0.16, -0.08, 0.02])]
        P.append(tube(f"curl{ci}", curl, 0.045, 0.025, segments=8, mat="smoke", k=0.03, bone="head", mirror=True))
    # --- aleta dorsal y cola con aleta dorada ---
    P.append(ellipsoid("dorsal1", (0, 1.66, 0.30), (0.035, 0.18, 0.44), R=euler(x=-38), mat="fin", k=0.08, bone="chest"))
    P.append(ellipsoid("dorsal2", (0, 1.14, -0.40), (0.035, 0.17, 0.62), R=euler(x=-12), mat="fin", k=0.08, bone="spine"))
    P.append(ellipsoid("tail", (0, 0.55, -1.85), (0.15, 0.30, 0.86), R=euler(x=-4), mat="skin", k=0.18, bone="tail1"))
    P.append(ellipsoid("tailFin", (0, 0.62, -2.15), (0.03, 0.50, 0.78), R=euler(x=-4), mat="fin", k=0.06, bone="tail2"))
    # --- seis patas: las delanteras más largas sostienen el torso erguido ---
    legs = [
        ("legF", (0.42, 1.00, 0.58), (0.80, 0.62, 0.74), (0.74, 0.10, 0.96), 0.20, 0.15),
        ("legM", (0.44, 0.68, -0.20), (0.82, 0.48, -0.16), (0.82, 0.10, -0.08), 0.18, 0.14),
        ("legB", (0.40, 0.56, -0.95), (0.78, 0.42, -1.02), (0.76, 0.10, -0.96), 0.18, 0.14),
    ]
    for nm, a, m, b, ra, rb in legs:
        bone = nm + "_*"
        P.append(cone(nm, a, m, ra, rb * 1.05, mat="skin", k=0.10, bone=bone, mirror=True))
        P.append(cone(nm + "Fore", m, b, rb * 1.05, rb, mat="skin", k=0.06, bone=bone, mirror=True))
        hc = np.array(b) + np.array([0.02, -0.05, 0.06])
        P.append(ellipsoid(nm + "Hand", hc, (0.13, 0.055, 0.12), mat="skin", k=0.05, bone=bone, mirror=True))
        for fi, ang in enumerate((-45, -15, 15, 45)):
            d = euler(y=ang) @ np.array([0.0, 0.0, 0.15])
            P.append(capsule(f"{nm}Finger{fi}", hc, hc + d + np.array([0, -0.025, 0]), 0.034, mat="skin", k=0.025, bone=bone, mirror=True))
    # --- vetas de oro de reparación (siguen el barro: grietas reparadas, no heridas) ---
    base_parts = list(P)
    rng = np.random.RandomState(31)
    seeds = [(0.25, 2.18, 1.10), (0.55, 1.36, 0.55), (0.52, 0.85, -0.30), (0.40, 0.80, -1.00), (0.15, 2.10, 0.62), (0.14, 0.60, -1.75)]
    for i, path in enumerate(_kintsugi_paths(base_parts, seeds, rng, steps=12, step=0.06)):
        P.append(polyline_groove(f"kintsugi{i}", path, 0.016, "gold", k=0.006, bone="spine", mirror=True, op="sub"))

    bones = [
        Bone("root", None, (0, 0, 0)),
        Bone("spine", "root", (0, 0.62, -0.60)),
        Bone("chest", "spine", (0, 1.05, 0.30)),
        Bone("neck", "chest", (0, 1.40, 0.66)),
        Bone("head", "neck", (0, 1.80, 0.94)),
        Bone("jaw", "head", (0, 1.68, 0.99)),
        Bone("legF_L", "chest", (0.44, 1.02, 0.60)),
        Bone("legF_R", "chest", (-0.44, 1.02, 0.60)),
        Bone("legM_L", "spine", (0.46, 0.66, -0.20)),
        Bone("legM_R", "spine", (-0.46, 0.66, -0.20)),
        Bone("legB_L", "spine", (0.40, 0.56, -0.95)),
        Bone("legB_R", "spine", (-0.40, 0.56, -0.95)),
        Bone("tail1", "spine", (0, 0.58, -1.30)),
        Bone("tail2", "tail1", (0, 0.58, -2.00)),
    ]
    return Creature(
        id="CR_Xolossus_Tallado_v01",
        display="Xolossus",
        species="xolumi",
        form="Tallado",
        rarity="Comun",
        elements=("Agua",),
        family="Anfibio",
        parts=P,
        materials=mats,
        bones=bones,
        tri_budget=(4000, 6500),
        bone_budget=30,
        voxel=0.016,
        notes="Seis patas, torso erguido 30°, corona de branquias de humo de copal, vetas de oro de reparación, aleta dorada.",
        meta={"expression": expr},
    )
