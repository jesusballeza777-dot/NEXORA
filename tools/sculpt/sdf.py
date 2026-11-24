"""
Biblioteca de campos de distancia (SDF) del escultor de NEXORA.

Unidades: studs de Roblox. Ejes: Y arriba, la criatura mira hacia +Z, X a su izquierda.
Todo vectorizado con numpy: cada primitiva recibe p con forma (N, 3) y devuelve (N,).
"""

from __future__ import annotations

import math
import numpy as np

# ---------------------------------------------------------------------------
# Utilidades geométricas
# ---------------------------------------------------------------------------


def v(*a):
    return np.array(a, dtype=np.float64)


def norm(a, axis=-1):
    return np.sqrt(np.sum(a * a, axis=axis))


def rot(axis: str, deg: float) -> np.ndarray:
    """Matriz de rotación (columna) alrededor de un eje cardinal."""
    r = math.radians(deg)
    c, s = math.cos(r), math.sin(r)
    if axis == "x":
        return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])
    if axis == "y":
        return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def euler(x=0.0, y=0.0, z=0.0) -> np.ndarray:
    """Rotación YXZ (yaw, pitch, roll) en grados, como CFrame.fromEulerAnglesYXZ."""
    return rot("y", y) @ rot("x", x) @ rot("z", z)


def clamp01(x):
    return np.clip(x, 0.0, 1.0)


# ---------------------------------------------------------------------------
# Primitivas (distancia con signo, negativa dentro)
# ---------------------------------------------------------------------------


def sd_sphere(p, c, r):
    return norm(p - c) - r


def sd_ellipsoid(p, c, radii, R=None):
    q = p - c
    if R is not None:
        q = q @ R  # al espacio local (R ortonormal: R^T aplicada por la derecha)
    rr = np.asarray(radii, dtype=np.float64)
    k0 = norm(q / rr)
    k1 = norm(q / (rr * rr))
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


def sd_round_cone(p, a, b, ra, rb):
    """Cono redondeado entre los puntos a (radio ra) y b (radio rb). Exacto (iq)."""
    ba = b - a
    l2 = float(np.dot(ba, ba))
    rr = ra - rb
    a2 = l2 - rr * rr
    il2 = 1.0 / l2
    pa = p - a
    y = pa @ ba
    z = y - l2
    xv = pa * l2 - np.outer(y, ba)
    x2 = np.sum(xv * xv, axis=1)
    y2 = y * y * l2
    z2 = z * z * l2
    k = np.sign(rr) * rr * rr * x2
    out = (np.sqrt(x2 * a2 * il2) + y * rr) * il2 - ra
    m1 = np.sign(z) * a2 * z2 > k
    out = np.where(m1, np.sqrt(x2 + z2) * il2 - rb, out)
    m2 = np.sign(y) * a2 * y2 < k
    out = np.where(m2, np.sqrt(x2 + y2) * il2 - ra, out)
    return out


def sd_capsule(p, a, b, r):
    pa = p - a
    ba = b - a
    h = clamp01((pa @ ba) / float(np.dot(ba, ba)))
    return norm(pa - np.outer(h, ba)) - r


def sd_round_box(p, c, half, r, R=None):
    q = p - c
    if R is not None:
        q = q @ R
    d = np.abs(q) - (np.asarray(half) - r)
    return norm(np.maximum(d, 0.0)) + np.minimum(np.max(d, axis=1), 0.0) - r


def sd_torus(p, c, R_major, r_minor, R=None):
    """Toro en el plano XZ local (eje Y local)."""
    q = p - c
    if R is not None:
        q = q @ R
    qx = np.sqrt(q[:, 0] ** 2 + q[:, 2] ** 2) - R_major
    return np.sqrt(qx * qx + q[:, 1] ** 2) - r_minor


def sd_cylinder(p, c, radius, half_h, R=None, round_r=0.0):
    q = p - c
    if R is not None:
        q = q @ R
    dx = np.sqrt(q[:, 0] ** 2 + q[:, 2] ** 2) - (radius - round_r)
    dy = np.abs(q[:, 1]) - (half_h - round_r)
    return np.minimum(np.maximum(dx, dy), 0.0) + np.sqrt(np.maximum(dx, 0) ** 2 + np.maximum(dy, 0) ** 2) - round_r


def sd_cone_tip(p, a, b, ra):
    """Cono que termina en punta (b); útil para garras, colmillos y cuernos."""
    return sd_round_cone(p, a, b, ra, max(ra * 0.08, 0.004))


def sd_bezier_tube(p, pts, r0, r1, segments=10):
    """Tubo a lo largo de una curva de Bézier cúbica con radio que va de r0 a r1."""
    P0, P1, P2, P3 = [np.asarray(x, dtype=np.float64) for x in pts]
    out = None
    prev = P0
    for i in range(1, segments + 1):
        t = i / segments
        cur = (1 - t) ** 3 * P0 + 3 * (1 - t) ** 2 * t * P1 + 3 * (1 - t) * t * t * P2 + t ** 3 * P3
        ra = r0 + (r1 - r0) * ((i - 1) / segments)
        rb = r0 + (r1 - r0) * t
        d = sd_round_cone(p, prev, cur, ra, rb)
        out = d if out is None else np.minimum(out, d)
        prev = cur
    return out


def bezier_point(pts, t):
    P0, P1, P2, P3 = [np.asarray(x, dtype=np.float64) for x in pts]
    return (1 - t) ** 3 * P0 + 3 * (1 - t) ** 2 * t * P1 + 3 * (1 - t) * t * t * P2 + t ** 3 * P3


# ---------------------------------------------------------------------------
# Operaciones suaves
# ---------------------------------------------------------------------------


def smin(a, b, k):
    if k <= 0:
        return np.minimum(a, b)
    h = np.maximum(k - np.abs(a - b), 0.0) / k
    return np.minimum(a, b) - h * h * k * 0.25


def smax(a, b, k):
    return -smin(-a, -b, k)


# ---------------------------------------------------------------------------
# Ruido (valor 3D con interpolación suave) para pelaje, barro y piedra
# ---------------------------------------------------------------------------

_PERM = np.random.RandomState(1729).permutation(256)
_PERM = np.concatenate([_PERM, _PERM])
_VALS = np.random.RandomState(4242).rand(256)


def _hash3(ix, iy, iz):
    return _VALS[_PERM[(_PERM[(_PERM[ix & 255] + iy) & 255] + iz) & 255]]


def value_noise(p, freq=1.0):
    q = p * freq
    i = np.floor(q).astype(np.int64)
    f = q - i
    u = f * f * (3 - 2 * f)
    ix, iy, iz = i[:, 0], i[:, 1], i[:, 2]
    def h(dx, dy, dz):
        return _hash3(ix + dx, iy + dy, iz + dz)
    x00 = h(0, 0, 0) * (1 - u[:, 0]) + h(1, 0, 0) * u[:, 0]
    x10 = h(0, 1, 0) * (1 - u[:, 0]) + h(1, 1, 0) * u[:, 0]
    x01 = h(0, 0, 1) * (1 - u[:, 0]) + h(1, 0, 1) * u[:, 0]
    x11 = h(0, 1, 1) * (1 - u[:, 0]) + h(1, 1, 1) * u[:, 0]
    y0 = x00 * (1 - u[:, 1]) + x10 * u[:, 1]
    y1 = x01 * (1 - u[:, 1]) + x11 * u[:, 1]
    return (y0 * (1 - u[:, 2]) + y1 * u[:, 2]) * 2.0 - 1.0


def fbm(p, freq=1.0, octaves=3, gain=0.5):
    total = np.zeros(len(p))
    amp = 1.0
    f = freq
    norm_ = 0.0
    for _ in range(octaves):
        total += amp * value_noise(p, f)
        norm_ += amp
        amp *= gain
        f *= 2.03
    return total / norm_


# ---------------------------------------------------------------------------
# Patrones de oficio (relieve tallado)
# ---------------------------------------------------------------------------


def greca_2d(u, w, cell=1.0, line=0.16):
    """Greca escalonada (step-fret) de Mitla en coordenadas 2D (u, w).
    Devuelve 1 dentro del surco y 0 fuera, con borde suave."""
    x = np.mod(u / cell, 1.0)
    y = np.mod(w / cell, 1.0)
    # espiral cuadrada simplificada: marco + gancho escalonado
    frame = (np.minimum(np.minimum(x, 1 - x), np.minimum(y, 1 - y)) < line).astype(np.float64)
    hook_v = ((np.abs(x - 0.5) < line * 0.5) & (y > 0.25) & (y < 0.75)).astype(np.float64)
    hook_h = ((np.abs(y - 0.5) < line * 0.5) & (x > 0.5) & (x < 0.8)).astype(np.float64)
    step = ((np.abs(y - 0.25) < line * 0.5) & (x > 0.2) & (x < 0.5)).astype(np.float64)
    return np.clip(frame + hook_v + hook_h + step, 0, 1)


def grooves_rings(t, count, width):
    """Anillos (surcos) periódicos a lo largo de un parámetro t en [0, 1]."""
    s = np.mod(t * count, 1.0)
    return (np.abs(s - 0.5) < width * 0.5).astype(np.float64)


def voronoi(p, scale=1.0, jitter=0.85):
    """Voronoi 3D: distancia a la celda más cercana (f1), a la segunda (f2) e id de celda.
    Sirve para las teselas del caparazón (juntas = f2 − f1 pequeño)."""
    q = p * scale
    i = np.floor(q).astype(np.int64)
    f1 = np.full(len(p), np.inf)
    f2 = np.full(len(p), np.inf)
    cid = np.zeros(len(p))
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                cx, cy, cz = i[:, 0] + dx, i[:, 1] + dy, i[:, 2] + dz
                jx = _hash3(cx, cy, cz)
                jy = _hash3(cx + 17, cy + 31, cz + 7)
                jz = _hash3(cx + 53, cy + 11, cz + 29)
                fp = np.stack([cx + 0.5 + (jx - 0.5) * jitter, cy + 0.5 + (jy - 0.5) * jitter, cz + 0.5 + (jz - 0.5) * jitter], axis=1)
                d = norm(q - fp)
                h = _hash3(cx + 101, cy + 211, cz + 307)
                closer = d < f1
                f2 = np.where(closer, f1, np.minimum(f2, d))
                cid = np.where(closer, h, cid)
                f1 = np.where(closer, d, f1)
    return f1 / scale, f2 / scale, cid
