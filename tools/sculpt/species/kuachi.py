"""
Kuachi → Ascuacho (Fuego · Común · Atacante · cuadrúpedo marsupial · Valle Copal).

Biblia p. 49: «El tlacuache que, según el relato, robó el fuego para los demás y lo cargó
en la cola.» Brote: hocico largo, orejas redondas, cola pelada y enroscada con la punta
chamuscada, la bolsa del vientre brilla como un horno tibio. Tallado: tlacuache de acecho,
largo y bajo; la bolsa es un horno con rejilla al rojo y la cola un látigo de ceniza con
anillos encendidos. Mirada de ladrón astuto. Claves 2D: silueta baja y alargada, bolsa-horno
brillante, gris ceniza con brasa naranja.

Rasgos reales del tlacuache que se conservan: cara clara con máscara oscura alrededor de
los ojos, orejas desnudas oscuras con borde claro, nariz rosada, manos de cinco dedos con
pulgar oponible en las patas traseras, cola prensil sin pelo.
"""

from __future__ import annotations

import numpy as np

from core import Bone, Creature, Material, capsule, cone, custom, ellipsoid, hexc, sphere, spike, torus, tube
from sdf import bezier_point, euler, fbm, norm, sd_round_cone, sd_torus
from species.common import eye_material, fur_color, fur_detail, lid, mix, smile

# ---------------------------------------------------------------------------
# Expresiones (seis por forma, Biblia p. 21; dosier docs/art/dossiers/KUACHI.md)
# ---------------------------------------------------------------------------
EXPRESSIONS = {
    "neutral": dict(upper=0.86, lower=0.08, tilt=0, ears=0, mouth=0.0, smile=1.0, brow=0),
    "desafio": dict(upper=0.62, lower=0.18, tilt=10, ears=-25, mouth=0.0, smile=0.4, brow=-12),
    "ataque": dict(upper=0.72, lower=0.12, tilt=12, ears=-35, mouth=1.0, smile=0.0, brow=-18),
    "victoria": dict(upper=0.50, lower=0.30, tilt=-6, ears=10, mouth=0.3, smile=1.6, brow=6),
    "cansado": dict(upper=0.38, lower=0.10, tilt=-14, ears=25, mouth=0.0, smile=-0.6, brow=10),
    "carino": dict(upper=0.30, lower=0.34, tilt=-4, ears=8, mouth=0.0, smile=1.3, brow=4),
}

FUR = "#9E8A7A"
CREAM = "#EADDC8"
MASK = "#5E5047"
EAR = "#463B38"
PINK = "#E39A96"
EMBER = "#FF9640"


def _belly_brote(p):
    # vientre y pecho claros (abajo y delante)
    return np.clip((0.62 - p[:, 1]) * 3.0, 0, 1) * np.clip((p[:, 2] + 0.25) * 2.2, 0, 1)


def _head_mask_brote(c_head):
    """Cara clara del tlacuache con máscara oscura alrededor de los ojos."""
    c_head = np.asarray(c_head)
    cream, fur, mask = np.asarray(hexc(CREAM)), np.asarray(hexc(FUR)), np.asarray(hexc(MASK))

    def f(p):
        q = p - c_head
        q[:, 0] = np.abs(q[:, 0])
        front = np.clip((q[:, 2] + 0.05) * 3.2, 0, 1)
        top = np.clip((q[:, 1] - 0.16) * 6.0, 0, 1)
        col = mix(fur, cream, front * (1 - top * 0.85))
        # máscara: mancha alrededor de cada ojo (espejo: |x|)
        e = np.asarray([0.17, 0.06, 0.27])
        d = norm((q - e) * np.array([1.0, 1.35, 0.85]))
        col = mix(col, mask, np.clip((0.215 - d) * 14.0, 0, 1) * 0.9)
        n = fbm(p, 7.0, 2)
        return col * (1.0 + 0.05 * n)[:, None]

    return f


def brote(expr="neutral"):
    e = EXPRESSIONS[expr]
    head_c = (0.0, 1.10, 0.40)
    eye_c = (0.170, 1.16, 0.665)
    look = (0.30, 0.04, 1.0)

    mats = {
        "fur": Material("fur", fur_color(FUR, CREAM, _belly_brote), roughness=0.86),
        "face": Material("face", _head_mask_brote(head_c), roughness=0.82),
        "ear": Material("ear", lambda p: mix(np.asarray(hexc(EAR)), np.asarray(hexc("#8A6E6A")), np.clip((p[:, 1] - 1.58) * 6, 0, 1)), roughness=0.55),
        "innerEar": Material("innerEar", hexc("#C9827E"), roughness=0.5),
        "skin": Material("skin", hexc(PINK), roughness=0.45),
        "nose": Material("nose", hexc("#D9737E"), roughness=0.25),
        "mouth": Material("mouth", hexc("#4A2A2C"), roughness=0.6, ao=0.5),
        "eye": eye_material("eye", eye_c, look, iris="#3A2A22", sclera="#1E1614", iris_ang=1.15, pupil_ang=0.62, rim="#120C0B"),
        "tail": Material(
            "tail",
            lambda p: mix(np.asarray(hexc("#D8ADA4")), np.asarray(hexc("#2E2624")), np.clip((p[:, 1] - 1.0) * 4.0, 0, 1) * np.clip((p[:, 2] + 1.15) * 3, 0, 1)),
            roughness=0.5,
            emissive=lambda p: np.outer(np.clip((p[:, 1] - 1.12) * 6, 0, 1) * (fbm(p, 22.0, 1) > 0.35), hexc(EMBER)),
            emissive_strength=0.8,
        ),
        "pouch": Material(
            "pouch",
            lambda p: mix(np.asarray(hexc("#E8C9A8")), np.asarray(hexc("#F0B070")), np.clip((0.56 - p[:, 1]) * 4, 0, 1)),
            roughness=0.6,
            emissive=lambda p: np.outer(np.clip((0.52 - p[:, 1]) * 5, 0, 1), hexc(EMBER)) * 0.55,
            emissive_strength=0.6,
        ),
        "ember": Material("ember", hexc("#FFB060"), roughness=0.4, emissive=hexc(EMBER), emissive_strength=1.0, ao=0.2),
        "claw": Material("claw", hexc("#F2E6D6"), roughness=0.35),
    }

    parts = []
    # --- torso (pera baja, cría) ---
    parts.append(ellipsoid("torso", (0, 0.60, -0.08), (0.40, 0.38, 0.50), R=euler(x=-6), mat="fur", bone="spine", detail=fur_detail(), detail_amp=0.012))
    parts.append(ellipsoid("haunch", (0.20, 0.48, -0.32), (0.21, 0.25, 0.27), mat="fur", k=0.14, bone="spine", mirror=True, detail=fur_detail(), detail_amp=0.01))
    parts.append(ellipsoid("chest", (0, 0.72, 0.22), (0.30, 0.30, 0.26), mat="fur", k=0.16, bone="chest"))
    # --- cabeza grande (≈ 43 % de la altura) ---
    parts.append(ellipsoid("head", head_c, (0.40, 0.36, 0.37), mat="face", k=0.18, bone="head", detail=fur_detail(11), detail_amp=0.006))
    parts.append(ellipsoid("cheek", (0.21, 1.00, 0.55), (0.15, 0.13, 0.14), mat="face", k=0.10, bone="head", mirror=True))
    parts.append(cone("snout", (0, 1.05, 0.62), (0, 0.97, 1.02), 0.20, 0.075, mat="face", k=0.10, bone="head"))
    parts.append(sphere("nose", (0, 0.985, 1.045), 0.064, mat="nose", k=0.025, bone="head", priority=0.02))
    parts.append(sphere("nostril", (0.026, 0.975, 1.104), 0.016, mat="mouth", op="sub", k=0.008, bone="head", mirror=True))
    # mechones de las mejillas: lóbulos de llama (lenguaje Copal Nexo), hacia atrás
    parts.append(cone("tuftA", (0.30, 1.00, 0.47), (0.47, 1.06, 0.30), 0.075, 0.018, mat="face", k=0.05, bone="head", mirror=True))
    parts.append(cone("tuftB", (0.29, 0.93, 0.42), (0.43, 0.90, 0.26), 0.06, 0.016, mat="face", k=0.05, bone="head", mirror=True))
    parts.append(ellipsoid("whiskerPad", (0.06, 0.95, 0.93), (0.07, 0.05, 0.06), mat="face", k=0.04, bone="head", mirror=True))
    # orejas redondas, desnudas, oscuras con borde claro
    ear_R = euler(y=28, z=-18 + e["ears"], x=-8)
    parts.append(ellipsoid("ear", (0.30, 1.47, 0.27), (0.20, 0.21, 0.055), R=ear_R, mat="ear", k=0.05, bone="head", mirror=True, priority=0.01))
    inner_c = np.array([0.30, 1.47, 0.27]) + ear_R @ np.array([0.0, -0.01, 0.045])
    parts.append(ellipsoid("innerEar", inner_c, (0.13, 0.14, 0.035), R=ear_R, mat="innerEar", op="sub", k=0.015, bone="head", mirror=True))
    # ojos con párpados (los párpados son pelo de la cara)
    parts.append(sphere("eye", eye_c, 0.118, mat="eye", k=0.012, bone="head", mirror=True))
    parts.append(lid("lidUp", eye_c, 0.129, look, e["upper"], tilt=e["tilt"], mat="face", bone="head"))
    parts.append(lid("lidLow", eye_c, 0.127, look, 1 - e["lower"], tilt=-e["tilt"] * 0.5, lower=True, mat="face", bone="head"))
    if e["brow"] != 0:
        bR = euler(z=e["brow"])
        parts.append(capsule("brow", np.array(eye_c) + bR @ np.array([-0.06, 0.14, -0.02]), np.array(eye_c) + bR @ np.array([0.07, 0.15, -0.04]), 0.028, mat="face", k=0.03, bone="head", mirror=True))
    # boca: sonrisa tallada bajo el hocico (smile > 0 sonríe; < 0 hacia abajo)
    sm = e["smile"]
    parts.append(smile("mouth", (0.0, 0.915, 0.97), (0.06, 0.905 - 0.012 * sm, 0.955), (0.12, 0.935 + 0.02 * sm, 0.88), 0.013, mirror=True))
    if e["mouth"] > 0:
        parts.append(ellipsoid("mouthOpen", (0, 0.90, 0.93), (0.07, 0.035 * e["mouth"] + 0.01, 0.06), mat="mouth", op="sub", k=0.02, bone="jaw"))
    # --- bolsa-horno tibia (vientre) ---
    parts.append(ellipsoid("pouch", (0, 0.50, 0.30), (0.22, 0.17, 0.13), R=euler(x=-18), mat="pouch", k=0.06, bone="spine", priority=0.01))
    parts.append(ellipsoid("pouchSlit", (0, 0.54, 0.425), (0.11, 0.022, 0.05), R=euler(x=-18), mat="ember", op="sub", k=0.014, bone="spine"))
    # --- patas: manos rosadas de cinco dedos (delante) y pies con pulgar (detrás) ---
    parts.append(cone("legF", (0.18, 0.50, 0.24), (0.20, 0.12, 0.30), 0.12, 0.08, mat="fur", k=0.08, bone="legF_*", mirror=True))
    parts.append(ellipsoid("handF", (0.205, 0.055, 0.35), (0.095, 0.055, 0.11), mat="skin", k=0.05, bone="legF_*", mirror=True))
    for i, (dx, dz) in enumerate(((-0.06, 0.44), (0.0, 0.46), (0.06, 0.43))):
        parts.append(sphere(f"fingerF{i}", (0.205 + dx, 0.035, dz), 0.035, mat="skin", k=0.03, bone="legF_*", mirror=True))
    parts.append(cone("legB", (0.25, 0.40, -0.30), (0.26, 0.12, -0.22), 0.13, 0.085, mat="fur", k=0.08, bone="legB_*", mirror=True))
    parts.append(ellipsoid("footB", (0.265, 0.055, -0.14), (0.10, 0.055, 0.14), mat="skin", k=0.05, bone="legB_*", mirror=True))
    parts.append(sphere("thumbB", (0.34, 0.045, -0.12), 0.035, mat="skin", k=0.03, bone="legB_*", mirror=True))
    # --- cola prensil pelada, enroscada en espiral hacia arriba, punta chamuscada ---
    t1 = [(0, 0.50, -0.52), (0, 0.40, -0.95), (0, 0.72, -1.25), (0, 1.12, -1.10)]
    t2 = [(0, 1.12, -1.10), (0, 1.40, -0.98), (0, 1.42, -0.66), (0, 1.22, -0.66)]
    t3 = [(0, 1.22, -0.66), (0, 1.08, -0.66), (0, 1.10, -0.86), (0, 1.25, -0.84)]
    parts.append(tube("tail1", t1, 0.105, 0.075, segments=12, mat="tail", k=0.10, bone="tail1"))
    parts.append(tube("tail2", t2, 0.075, 0.050, segments=12, mat="tail", k=0.02, bone="tail2"))
    parts.append(tube("tail3", t3, 0.050, 0.040, segments=8, mat="tail", k=0.02, bone="tail3"))
    parts.append(sphere("tailEmber", (0, 1.255, -0.845), 0.052, mat="ember", k=0.025, bone="tail3", priority=0.02))

    bones = [
        Bone("root", None, (0, 0, 0)),
        Bone("spine", "root", (0, 0.58, -0.10)),
        Bone("chest", "spine", (0, 0.70, 0.20)),
        Bone("head", "chest", (0, 1.00, 0.36)),
        Bone("jaw", "head", (0, 0.93, 0.80)),
        Bone("legF_L", "chest", (0.18, 0.50, 0.24)),
        Bone("legF_R", "chest", (-0.18, 0.50, 0.24)),
        Bone("legB_L", "spine", (0.25, 0.42, -0.30)),
        Bone("legB_R", "spine", (-0.25, 0.42, -0.30)),
        Bone("tail1", "spine", (0, 0.50, -0.52)),
        Bone("tail2", "tail1", (0, 1.12, -1.10)),
        Bone("tail3", "tail2", (0, 1.22, -0.66)),
    ]
    return Creature(
        id="CR_Kuachi_Brote_v01",
        display="Kuachi",
        species="kuachi",
        form="Brote",
        rarity="Comun",
        elements=("Fuego",),
        family="CuadrupedoAgil",
        parts=parts,
        materials=mats,
        bones=bones,
        tri_budget=(2500, 4000),
        bone_budget=18,
        voxel=0.011,
        notes="Cría sentada-de-pie con cabeza grande; cola en espiral como firma; bolsa tibia.",
        meta={"expression": expr},
    )


# ---------------------------------------------------------------------------
# Tallado · Ascuacho
# ---------------------------------------------------------------------------
TALLADO_EXPRESSIONS = {
    "neutral": dict(upper=0.62, lower=0.22, tilt=16, brow=0, jaw=0.25, ears=0, smirk=0),
    "desafio": dict(upper=0.50, lower=0.26, tilt=20, brow=-8, jaw=0.15, ears=-15, smirk=0),
    "ataque": dict(upper=0.66, lower=0.20, tilt=22, brow=-14, jaw=1.0, ears=-28, smirk=0),
    "victoria": dict(upper=0.46, lower=0.34, tilt=12, brow=6, jaw=0.35, ears=8, smirk=1),
    "cansado": dict(upper=0.34, lower=0.18, tilt=4, brow=10, jaw=0.1, ears=22, smirk=0),
    "carino": dict(upper=0.32, lower=0.36, tilt=8, brow=8, jaw=0.05, ears=10, smirk=0.5),
}

ASH = "#625A58"
CHAR = "#3A3433"
ASH_FACE = "#A0948A"


def tallado(expr="neutral"):
    from species.common import axis_frame, bezier_samples, polyline_groove, surface_points
    from sdf import bezier_point

    e = TALLADO_EXPRESSIONS[expr]
    head_c = np.array([0.0, 1.14, 1.46])
    eye_c = (0.185, 1.235, 1.745)
    look = (0.42, 0.02, 1.0)

    def face_col(p):
        q = p - head_c
        q[:, 0] = np.abs(q[:, 0])
        front = np.clip((q[:, 2] + 0.02) * 3.0, 0, 1)
        top = np.clip((q[:, 1] - 0.12) * 5.0, 0, 1)
        col = mix(np.asarray(hexc(ASH)), np.asarray(hexc(ASH_FACE)), front * (1 - top * 0.9))
        d = norm((q - np.array([0.185, 0.095, 0.285])) * np.array([0.9, 1.5, 0.8]))
        col = mix(col, np.asarray(hexc("#2A2422")), np.clip((0.2 - d) * 12, 0, 1) * 0.92)
        return col * (1 + 0.05 * fbm(p, 7.0, 2))[:, None]

    def belly(p):
        return np.clip((0.80 - p[:, 1]) * 2.4, 0, 1)

    mats = {
        "fur": Material("fur", fur_color(ASH, CHAR, belly, noise_amp=0.08), roughness=0.88),
        "face": Material("face", face_col, roughness=0.84),
        "ear": Material("ear", hexc("#2E2826"), roughness=0.6),
        "innerEar": Material("innerEar", hexc("#6E3428"), roughness=0.5, emissive=hexc("#FF5A1A"), emissive_strength=0.25),
        "nose": Material("nose", hexc("#2A2222"), roughness=0.3),
        "mouth": Material("mouth", hexc("#3A1612"), roughness=0.6, ao=0.4, emissive=hexc("#FF4A10"), emissive_strength=0.25),
        "claw": Material("claw", hexc("#EDE2CF"), roughness=0.3),
        "skin": Material("skin", hexc("#8A5A55"), roughness=0.55),
        "eye": eye_material(
            "eye", eye_c, look, iris="#FF8A2A", sclera="#2A1A12", pupil="#120A08",
            iris_ang=0.95, slit=(0.10, 0.55), rim="#5A1A06", glints=((-0.30, 0.32, 0.10),), glow=0.55,
        ),
        "clay": Material(
            "clay",
            lambda p: mix(np.asarray(hexc("#A2553A")), np.asarray(hexc("#3E2418")), np.clip((p[:, 1] - 0.58) * 4.5, 0, 1)) * (1 + 0.08 * fbm(p, 14, 2))[:, None],
            roughness=0.8,
        ),
        "emberCore": Material("emberCore", hexc("#FFB070"), roughness=0.5, emissive=hexc("#FF5A1A"), emissive_strength=1.0, ao=0.1),
        "iron": Material("iron", hexc("#2B2523"), roughness=0.45, metalness=0.7),
        "ember": Material("ember", hexc("#FF8A40"), roughness=0.4, emissive=hexc("#FF5A1A"), emissive_strength=1.0, ao=0.2),
        "tail": Material(
            "tail",
            lambda p: mix(np.asarray(hexc("#5A5250")), np.asarray(hexc("#26201F")), np.clip((p[:, 1] - 1.95) * 2.2, 0, 1)) * (1 + 0.06 * fbm(p, 9, 2))[:, None],
            roughness=0.85,
            emissive=lambda p: np.outer(np.clip((p[:, 1] - 2.05) * 3, 0, 1) * (fbm(p, 18.0, 1) > 0.4), hexc("#FF6A20")),
            emissive_strength=0.9,
        ),
    }

    P = []
    # --- cuerpo largo y bajo de acecho (unas 2,2 veces más largo que alto) ---
    P.append(ellipsoid("torso", (0, 0.80, -0.15), (0.52, 0.40, 0.98), R=euler(x=3), mat="fur", bone="spine", detail=fur_detail(7), detail_amp=0.018))
    P.append(ellipsoid("shoulders", (0, 0.88, 0.55), (0.52, 0.44, 0.48), mat="fur", k=0.22, bone="chest", detail=fur_detail(7), detail_amp=0.018))
    P.append(ellipsoid("hips", (0, 0.92, -0.85), (0.48, 0.44, 0.46), mat="fur", k=0.20, bone="spine", detail=fur_detail(7), detail_amp=0.018))
    P.append(cone("neck", (0, 0.98, 0.85), (0, 1.08, 1.28), 0.36, 0.28, mat="fur", k=0.16, bone="neck"))
    P.append(ellipsoid("ruff", (0, 1.02, 0.98), (0.44, 0.34, 0.24), R=euler(x=-20), mat="fur", k=0.12, bone="neck", detail=fur_detail(6), detail_amp=0.035))
    # --- cabeza: hocico afilado, mirada de ladrón ---
    P.append(ellipsoid("head", head_c, (0.36, 0.32, 0.40), mat="face", k=0.14, bone="head", detail=fur_detail(10), detail_amp=0.008))
    P.append(cone("snout", (0, 1.07, 1.66), (0, 0.96, 2.16), 0.22, 0.075, mat="face", k=0.10, bone="head"))
    P.append(sphere("nose", (0, 0.945, 2.19), 0.07, mat="nose", k=0.03, bone="head", priority=0.01))
    P.append(sphere("nostril", (0.028, 0.935, 2.252), 0.017, mat="mouth", op="sub", k=0.008, bone="head", mirror=True))
    jd = 0.04 * e["jaw"]
    P.append(ellipsoid("jaw", (0, 0.90 - jd, 1.84), (0.14, 0.075, 0.27), R=euler(x=-8 - 12 * e["jaw"]), mat="face", k=0.05, bone="jaw"))
    P.append(ellipsoid("mouthCut", (0, 0.945 - jd * 0.5, 1.90), (0.115, 0.022 + 0.035 * e["jaw"], 0.25), R=euler(x=-4), mat="mouth", op="sub", k=0.015, bone="jaw"))
    if e["smirk"]:
        P.append(ellipsoid("smirk", (0.10, 0.96, 1.90), (0.05, 0.02, 0.08), R=euler(z=-25), mat="mouth", op="sub", k=0.01, bone="jaw"))
    for i, (a, b) in enumerate((((0.07, 0.965, 2.01), (0.075, 0.845 - jd, 2.035)), ((0.05, 0.87 - jd, 2.06), (0.05, 0.95, 2.07)))):
        P.append(spike(f"fang{i}", a, b, 0.026, mat="claw", k=0.006, bone="head" if i == 0 else "jaw", mirror=True, priority=0.01))
    # orejas redondas echadas hacia atrás
    ear_c = np.array([0.26, 1.44, 1.26])
    ear_R = euler(y=40, z=-38 + e["ears"], x=28)
    P.append(ellipsoid("ear", ear_c, (0.17, 0.19, 0.048), R=ear_R, mat="ear", k=0.05, bone="head", mirror=True))
    P.append(ellipsoid("innerEar", ear_c + ear_R @ np.array([0, -0.01, 0.04]), (0.11, 0.13, 0.03), R=ear_R, mat="innerEar", op="sub", k=0.012, bone="head", mirror=True))
    # ojo almendrado con párpados gruesos y ceja feroz
    P.append(sphere("eye", eye_c, 0.088, mat="eye", k=0.01, bone="head", mirror=True))
    P.append(lid("lidUp", eye_c, 0.099, look, e["upper"], tilt=e["tilt"], mat="face", bone="head"))
    P.append(lid("lidLow", eye_c, 0.097, look, 1 - e["lower"], tilt=-e["tilt"] * 0.6, lower=True, mat="face", bone="head"))
    bR = euler(z=e["brow"])
    P.append(capsule("brow", np.array(eye_c) + bR @ np.array([-0.09, 0.07, 0.005]), np.array(eye_c) + bR @ np.array([0.085, 0.095, -0.07]), 0.03, mat="face", k=0.08, bone="head", mirror=True))
    # mechones en lóbulo de llama hacia atrás (suaves, no púas)
    P.append(cone("tuftA", (0.29, 1.08, 1.36), (0.43, 1.13, 1.13), 0.085, 0.04, mat="face", k=0.08, bone="head", mirror=True))
    P.append(cone("tuftB", (0.27, 0.98, 1.36), (0.41, 0.95, 1.15), 0.065, 0.035, mat="face", k=0.08, bone="head", mirror=True))
    # --- bolsa → horno de comal en el vientre, con rejilla al rojo y respiraderos ---
    P.append(ellipsoid("oven", (0, 0.46, 0.05), (0.40, 0.30, 0.55), mat="clay", k=0.08, bone="spine", priority=0.01))
    mouth_c = np.array([0, 0.46, 0.58])
    P.append(torus("ovenRim", mouth_c, 0.17, 0.035, R=euler(x=90), mat="clay", k=0.03, bone="spine"))
    P.append(ellipsoid("ovenMouth", mouth_c + np.array([0, 0, 0.02]), (0.16, 0.12, 0.12), mat="emberCore", op="sub", k=0.02, bone="spine"))
    for i, y in enumerate((0.40, 0.46, 0.52)):
        P.append(capsule(f"grillH{i}", (-0.15, y, 0.60), (0.15, y, 0.60), 0.017, mat="iron", bone="spine", priority=0.01))
    for x in (-0.06, 0.06):
        P.append(capsule(f"grillV{x}", (x, 0.35, 0.605), (x, 0.57, 0.605), 0.015, mat="iron", bone="spine", priority=0.01))
    for j, dz in enumerate((-0.22, 0.0, 0.22)):
        P.append(ellipsoid(f"vent{j}", (0.39, 0.50, 0.05 + dz), (0.06, 0.022, 0.075), mat="emberCore", op="sub", k=0.012, bone="spine", mirror=True))
    # --- patas cortas y fuertes con garras ---
    P.append(ellipsoid("arm", (0.36, 0.72, 0.62), (0.20, 0.28, 0.24), mat="fur", k=0.12, bone="legF_*", mirror=True))
    P.append(cone("forearm", (0.38, 0.55, 0.72), (0.41, 0.13, 0.86), 0.16, 0.12, mat="fur", k=0.08, bone="legF_*", mirror=True))
    P.append(ellipsoid("pawF", (0.42, 0.075, 0.95), (0.14, 0.075, 0.17), mat="skin", k=0.06, bone="pawF_*", mirror=True))
    P.append(ellipsoid("thigh", (0.38, 0.78, -0.85), (0.23, 0.33, 0.34), mat="fur", k=0.12, bone="legB_*", mirror=True))
    P.append(cone("shin", (0.40, 0.55, -0.97), (0.42, 0.13, -0.80), 0.15, 0.11, mat="fur", k=0.08, bone="legB_*", mirror=True))
    P.append(ellipsoid("pawB", (0.42, 0.075, -0.68), (0.13, 0.075, 0.21), mat="skin", k=0.06, bone="pawB_*", mirror=True))
    for i, dx in enumerate((-0.07, 0.0, 0.07)):
        P.append(spike(f"clawF{i}", (0.42 + dx, 0.06, 1.07), (0.42 + dx * 1.2, 0.0, 1.19), 0.028, mat="claw", k=0.012, bone="pawF_*", mirror=True))
        P.append(spike(f"clawB{i}", (0.42 + dx, 0.06, -0.50), (0.42 + dx * 1.2, 0.0, -0.40), 0.025, mat="claw", k=0.012, bone="pawB_*", mirror=True))
    # --- cola: látigo de ceniza en S por encima del lomo, con anillos encendidos ---
    t1 = [(0, 0.82, -1.20), (0, 0.45, -1.95), (0, 1.20, -2.50), (0, 1.95, -2.08)]
    t2 = [(0, 1.95, -2.08), (0, 2.55, -1.68), (0, 2.68, -0.90), (0, 2.28, -0.58)]
    t3 = [(0, 2.28, -0.58), (0, 2.06, -0.42), (0, 1.92, -0.56), (0, 2.00, -0.74)]
    P.append(tube("tail1", t1, 0.18, 0.12, segments=14, mat="tail", k=0.14, bone="tail1"))
    P.append(tube("tail2", t2, 0.12, 0.075, segments=14, mat="tail", k=0.03, bone="tail3"))
    P.append(tube("tail3", t3, 0.075, 0.05, segments=8, mat="tail", k=0.02, bone="tail5"))
    P.append(sphere("tailTip", (0, 2.00, -0.74), 0.06, mat="ember", k=0.03, bone="tail5", priority=0.01))
    rings = [(t1, 0.55, 0.15), (t1, 0.75, 0.135), (t1, 0.93, 0.125), (t2, 0.18, 0.11), (t2, 0.40, 0.095), (t2, 0.62, 0.085)]
    for i, (pts, t, rr) in enumerate(rings):
        c0 = bezier_point(pts, t)
        tan = bezier_point(pts, min(1, t + 0.02)) - bezier_point(pts, max(0, t - 0.02))
        P.append(torus(f"ring{i}", c0, rr, 0.028, R=axis_frame(tan), mat="ember", op="sub", k=0.012, bone="tail2" if pts is t1 else "tail4"))
    # surcos de lóbulos de llama en los costados (relieve con luz dentro)
    base_parts = list(P)
    for j, curve in enumerate(
        (
            [(0.60, 1.06, 0.80), (0.70, 0.76, 0.55), (0.66, 1.08, 0.25), (0.62, 0.81, 0.00)],
            [(0.60, 1.06, -0.40), (0.70, 0.76, -0.62), (0.62, 1.06, -0.88), (0.58, 0.81, -1.10)],
        )
    ):
        pts = surface_points(base_parts, bezier_samples(curve, 14))
        P.append(polyline_groove(f"flank{j}", pts, 0.024, "ember", k=0.012, bone="spine", mirror=True))

    bones = [
        Bone("root", None, (0, 0, 0)),
        Bone("spine", "root", (0, 0.80, -0.40)),
        Bone("chest", "spine", (0, 0.84, 0.50)),
        Bone("neck", "chest", (0, 1.00, 0.90)),
        Bone("head", "neck", (0, 1.14, 1.34)),
        Bone("jaw", "head", (0, 0.96, 1.60)),
        Bone("legF_L", "chest", (0.36, 0.82, 0.60)),
        Bone("legF_R", "chest", (-0.36, 0.82, 0.60)),
        Bone("pawF_L", "legF_L", (0.41, 0.14, 0.86)),
        Bone("pawF_R", "legF_R", (-0.41, 0.14, 0.86)),
        Bone("legB_L", "spine", (0.38, 0.88, -0.85)),
        Bone("legB_R", "spine", (-0.38, 0.88, -0.85)),
        Bone("pawB_L", "legB_L", (0.42, 0.14, -0.80)),
        Bone("pawB_R", "legB_R", (-0.42, 0.14, -0.80)),
        Bone("tail1", "spine", (0, 0.82, -1.20)),
        Bone("tail2", "tail1", (0, 0.70, -2.10)),
        Bone("tail3", "tail2", (0, 1.95, -2.08)),
        Bone("tail4", "tail3", (0, 2.60, -1.30)),
        Bone("tail5", "tail4", (0, 2.28, -0.58)),
    ]
    return Creature(
        id="CR_Ascuacho_Tallado_v01",
        display="Ascuacho",
        species="kuachi",
        form="Tallado",
        rarity="Comun",
        elements=("Fuego",),
        family="CuadrupedoAgil",
        parts=P,
        materials=mats,
        bones=bones,
        tri_budget=(4000, 6500),
        bone_budget=30,
        voxel=0.014,
        notes="Acecho largo y bajo; horno de comal en el vientre con rejilla al rojo; látigo de ceniza en S con anillos encendidos; ojo almendrado de iris naranja.",
        meta={"expression": expr},
    )
