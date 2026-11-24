"""
Piezas y materiales compartidos por las especies: ojos (Brote redondo, Tallado almendrado),
párpados, cejas, bocas y mezclas de color. Cada especie conserva su propia anatomía: aquí
solo hay utilidades, no cuerpos.
"""

from __future__ import annotations

import numpy as np

from core import Material, Part, custom, hexc, tube
from sdf import fbm, norm, sd_sphere


def nrm(a):
    a = np.asarray(a, dtype=np.float64)
    return a / np.linalg.norm(a)


def frame(look):
    look = nrm(look)
    up = np.array([0.0, 1.0, 0.0])
    right = np.cross(up, look)
    right = right / np.linalg.norm(right)
    up2 = np.cross(look, right)
    return look, right, up2


def mix(a, b, t):
    t = np.clip(t, 0, 1)[:, None]
    return np.asarray(a) * (1 - t) + np.asarray(b) * t


def eye_material(name, c, look, iris, sclera="#F4EEE4", pupil="#141012", iris_ang=0.62, pupil_ang=0.40, slit=None,
                 rim="#000000", glints=((-0.28, 0.30, 0.13), (0.20, -0.16, 0.06)), glow=0.0):
    """Ojo pintado sobre una esfera: esclerótica, iris con degradado, pupila (redonda o
    rasgada) y brillos. `slit` = (ancho, alto) de la pupila rasgada en el plano del ojo."""
    c = np.asarray(c, dtype=np.float64)
    L, R, U = frame(look)
    iris_c, sclera_c, pupil_c, rim_c = hexc(iris), hexc(sclera), hexc(pupil), hexc(rim)

    def color(p):
        u = p - c
        u = u / np.maximum(norm(u)[:, None], 1e-9)
        x, y, z = u @ R, u @ U, u @ L
        ang = np.arccos(np.clip(z, -1, 1))
        col = np.tile(np.asarray(sclera_c), (len(p), 1))
        # iris con anillo oscuro y luz en la parte baja
        t_iris = np.clip(ang / iris_ang, 0, 1)
        iris_col = mix(np.asarray(iris_c) * 1.25, np.asarray(iris_c) * 0.55, t_iris ** 2)
        iris_col = mix(iris_col, np.asarray(iris_c) * 1.5, np.clip(-y * 2.2, 0, 1) * (1 - t_iris) * 0.6)
        iris_col = mix(iris_col, rim_c, np.clip((t_iris - 0.86) / 0.14, 0, 1))
        inside = ang < iris_ang
        col[inside] = iris_col[inside]
        if slit is None:
            pup = ang < pupil_ang
        else:
            pup = (x / slit[0]) ** 2 + (y / slit[1]) ** 2 < 1.0
            pup &= z > 0
        col[pup] = pupil_c
        for gx, gy, gr in glints:
            g = (x - gx) ** 2 + (y - gy) ** 2 < gr * gr
            col[g & (z > 0)] = (1.0, 0.98, 0.94)
        return col

    def emissive(p):
        u = p - c
        u = u / np.maximum(norm(u)[:, None], 1e-9)
        x, y, z = u @ R, u @ U, u @ L
        ang = np.arccos(np.clip(z, -1, 1))
        m = (ang < iris_ang) & (ang > iris_ang * 0.15)
        if slit is not None:
            m &= ~(((x / slit[0]) ** 2 + (y / slit[1]) ** 2 < 1.0) & (z > 0))
        return np.outer(m.astype(np.float64) * (1 - np.clip(ang / iris_ang, 0, 1) * 0.5), iris_c)

    if glow > 0:
        return Material(name, color, roughness=0.06, metalness=0.0, ao=0.25, emissive=emissive, emissive_strength=glow)
    return Material(name, color, roughness=0.06, metalness=0.0, ao=0.25)


def axis_frame(t):
    """Matriz de rotación cuyo eje Y local apunta en la dirección t (para anillos)."""
    y = nrm(t)
    a = np.array([1.0, 0.0, 0.0]) if abs(y[0]) < 0.9 else np.array([0.0, 0.0, 1.0])
    x = np.cross(a, y)
    x = x / np.linalg.norm(x)
    z = np.cross(x, y)
    return np.column_stack([x, y, z])


def lid(name, c, r, look, opening, tilt=0.0, lower=False, mat="skin", k=0.02, bone="head", mirror=True, priority=0.0):
    """Párpado: casquete de esfera (radio r) por encima (o por debajo) de un plano.
    opening 1 → no tapa nada; 0 → cerrado hasta el centro. tilt (grados) gira el borde
    alrededor del eje de la mirada: positivo sube la esquina exterior (almendra)."""
    c = np.asarray(c, dtype=np.float64)
    L, R, U = frame(look)
    a = np.radians(tilt)
    up = U * np.cos(a) - R * np.sin(a)
    if lower:
        up = -U * np.cos(a) - R * np.sin(a)
    h = r * (2 * opening - 1)

    def fn(p):
        q = p - c
        return np.maximum(sd_sphere(p, c, r), h - q @ up)

    return custom(name, fn, c, r, mat=mat, k=k, bone=bone, mirror=mirror, priority=priority)


def smile(name, a, mid, b, r, mat="mouth", k=0.01, bone="jaw", mirror=False):
    """Boca tallada: surco a lo largo de una curva (pieza de resta)."""
    a, mid, b = (np.asarray(x, dtype=np.float64) for x in (a, mid, b))
    pts = [a, a + (mid - a) * 0.66, b + (mid - b) * 0.66, b]
    return tube(name, pts, r, r, segments=8, mat=mat, op="sub", k=k, bone=bone, mirror=mirror)


def gradient_y(c_low, c_high, y0, y1):
    lo, hi = np.asarray(hexc(c_low)), np.asarray(hexc(c_high))

    def f(p):
        return mix(lo, hi, (p[:, 1] - y0) / (y1 - y0))

    return f


def fur_color(base, belly, belly_fn, noise_amp=0.06, noise_freq=6.0, extra=None):
    """Pelaje: color base, vientre (máscara 0–1) y variación sutil de valor."""
    b, w = np.asarray(hexc(base)), np.asarray(hexc(belly))

    def f(p):
        col = mix(b, w, belly_fn(p))
        n = fbm(p, noise_freq, 2)
        col = col * (1.0 + noise_amp * n)[:, None]
        if extra is not None:
            col = extra(p, col)
        return col

    return f


def fur_detail(freq=9.0):
    """Masas de pelaje (no pelos): crestas suaves de ruido."""

    def f(p):
        n = fbm(p, freq, 2)
        return np.abs(n) * 1.0 - 0.35

    return f


def surface_points(parts, pts, iters=8):
    """Proyecta puntos sobre la superficie formada por `parts` (para surcos y anillos)."""
    from core import Creature

    tmp = Creature("tmp", "", "", "", "", (), "", list(parts), {}, [], (0, 0), 0)
    P = np.array(pts, dtype=np.float64)
    for _ in range(iters):
        d = tmp.sdf(P)
        g = tmp.gradient(P)
        P = P - d[:, None] * g
    return P


def polyline_groove(name, pts, r, mat, k=0.01, bone="root", mirror=False, op="sub"):
    """Surco (o cordón, con op='add') que sigue una polilínea de puntos ya sobre la superficie."""
    from core import custom
    from sdf import sd_capsule

    P = np.asarray(pts, dtype=np.float64)

    def fn(p):
        out = None
        for a, b in zip(P[:-1], P[1:]):
            d = sd_capsule(p, a, b, r)
            out = d if out is None else np.minimum(out, d)
        return out

    c = P.mean(axis=0)
    rad = float(np.max(np.linalg.norm(P - c, axis=1)) + r)
    return custom(name, fn, c, rad, mat=mat, op=op, k=k, bone=bone, mirror=mirror)


def bezier_samples(pts, n):
    from sdf import bezier_point

    return np.array([bezier_point(pts, t) for t in np.linspace(0, 1, n)])
