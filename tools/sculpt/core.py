"""
Modelo de escena del escultor: piezas (Part), materiales y criatura.

Una criatura es una lista ordenada de piezas con campo de distancia. Las piezas «add» se
unen con mezcla suave y las piezas «sub» tallan (surcos, boca, rejilla). Cada pieza tiene
un material y un hueso del rig. El material de un punto de la superficie es el de la pieza
más cercana (con prioridad), o el de la pieza que lo talló.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable, Optional

import numpy as np

from sdf import (
    norm,
    sd_capsule,
    sd_cone_tip,
    sd_cylinder,
    sd_ellipsoid,
    sd_round_box,
    sd_round_cone,
    sd_sphere,
    sd_torus,
    sd_bezier_tube,
    smax,
    smin,
)

ColorFn = Callable[[np.ndarray], np.ndarray]


@dataclass
class Material:
    name: str
    color: object  # (r, g, b) 0–1 o función p_local -> (N, 3)
    roughness: float = 0.7
    metalness: float = 0.0
    emissive: object = None  # None, (r, g, b) o función p_local -> (N, 3) en 0–1 (máscara × color)
    emissive_strength: float = 0.0
    ao: float = 1.0  # cuánto oscurece la oclusión ambiental horneada (0–1)

    def sample_color(self, p):
        if callable(self.color):
            return np.clip(self.color(p), 0, 1)
        return np.tile(np.asarray(self.color, dtype=np.float64), (len(p), 1))

    def sample_emissive(self, p):
        if self.emissive is None:
            return np.zeros((len(p), 3))
        if callable(self.emissive):
            return np.clip(self.emissive(p), 0, 1)
        return np.tile(np.asarray(self.emissive, dtype=np.float64), (len(p), 1))


def hexc(h: str):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) / 255.0 for i in (0, 2, 4))


@dataclass
class Part:
    name: str
    fn: Callable[[np.ndarray], np.ndarray]
    bounds: tuple  # (centro, radio) en el espacio de la pieza (tras el espejo)
    mat: Optional[str] = None
    op: str = "add"  # add | sub
    k: float = 0.0  # radio de mezcla con lo anterior
    bone: str = "root"
    mirror: bool = False  # se evalúa con |x| (pieza definida en +X)
    priority: float = 0.0  # sesgo para ganar el material (en studs)
    detail: Optional[Callable[[np.ndarray], np.ndarray]] = None  # desplazamiento (+ hacia fuera)
    detail_amp: float = 0.0
    tags: tuple = ()

    def local(self, p):
        if self.mirror:
            q = p.copy()
            q[:, 0] = np.abs(q[:, 0])
            return q
        return p

    def eval(self, p, margin):
        """Distancia de la pieza; fuera de su esfera envolvente devuelve una cota."""
        q = self.local(p)
        c, r = self.bounds
        db = norm(q - np.asarray(c)) - r
        out = db.copy()
        near = db < margin
        if np.any(near):
            qn = q[near]
            d = self.fn(qn)
            if self.detail is not None and self.detail_amp != 0.0:
                d = d - self.detail_amp * self.detail(qn)
            out[near] = d
        return out


# ---------------------------------------------------------------------------
# Constructores de piezas con su esfera envolvente
# ---------------------------------------------------------------------------


def _arr(x):
    return np.asarray(x, dtype=np.float64)


def ellipsoid(name, c, radii, R=None, **kw):
    c = _arr(c)
    return Part(name, lambda p: sd_ellipsoid(p, c, radii, R), (c, float(max(radii)) * 1.05), **kw)


def sphere(name, c, r, **kw):
    c = _arr(c)
    return Part(name, lambda p: sd_sphere(p, c, r), (c, r), **kw)


def cone(name, a, b, ra, rb, **kw):
    a, b = _arr(a), _arr(b)
    return Part(name, lambda p: sd_round_cone(p, a, b, ra, rb), ((a + b) / 2, norm(b - a) / 2 + max(ra, rb)), **kw)


def capsule(name, a, b, r, **kw):
    a, b = _arr(a), _arr(b)
    return Part(name, lambda p: sd_capsule(p, a, b, r), ((a + b) / 2, norm(b - a) / 2 + r), **kw)


def spike(name, a, b, ra, **kw):
    a, b = _arr(a), _arr(b)
    return Part(name, lambda p: sd_cone_tip(p, a, b, ra), ((a + b) / 2, norm(b - a) / 2 + ra), **kw)


def rbox(name, c, half, r, R=None, **kw):
    c = _arr(c)
    return Part(name, lambda p: sd_round_box(p, c, half, r, R), (c, float(norm(_arr(half)))), **kw)


def torus(name, c, R_major, r_minor, R=None, **kw):
    c = _arr(c)
    return Part(name, lambda p: sd_torus(p, c, R_major, r_minor, R), (c, R_major + r_minor), **kw)


def cylinder(name, c, radius, half_h, R=None, round_r=0.0, **kw):
    c = _arr(c)
    return Part(
        name,
        lambda p: sd_cylinder(p, c, radius, half_h, R, round_r),
        (c, float(np.hypot(radius, half_h))),
        **kw,
    )


def tube(name, pts, r0, r1, segments=10, **kw):
    P = [_arr(x) for x in pts]
    c = sum(P) / 4
    rad = max(norm(x - c) for x in P) + max(r0, r1)
    return Part(name, lambda p: sd_bezier_tube(p, P, r0, r1, segments), (c, rad), **kw)


def custom(name, fn, c, r, **kw):
    return Part(name, fn, (_arr(c), r), **kw)


# ---------------------------------------------------------------------------
# Criatura
# ---------------------------------------------------------------------------


@dataclass
class Bone:
    name: str
    parent: Optional[str]
    head: tuple  # posición del pivote en reposo (studs)


@dataclass
class Creature:
    id: str
    display: str
    species: str
    form: str  # Brote | Tallado
    rarity: str
    elements: tuple
    family: str
    parts: list
    materials: dict
    bones: list
    tri_budget: tuple  # (mínimo, máximo) de la Biblia p. 120
    bone_budget: int
    voxel: float = 0.012  # tamaño de celda de la malla de alta resolución
    notes: str = ""
    meta: dict = field(default_factory=dict)

    # --- campo de distancia ---
    def sdf(self, p, margin=None, want_parts=False):
        m = margin if margin is not None else max(0.08, 4 * self.voxel)
        # la distancia acumulada debe ser exacta dentro del mayor radio de mezcla de
        # cualquier pieza posterior; si no, el atajo de la esfera envolvente deja escalones
        kmax = max((pt.k for pt in self.parts), default=0.0)
        d = None
        winners = None
        best = None
        per = [] if want_parts else None
        for i, part in enumerate(self.parts):
            dm = m + kmax + part.k
            di = part.eval(p, dm)
            if want_parts:
                per.append(di)
            if part.op == "add":
                if d is None:
                    d = di
                    if want_parts:
                        best = di - part.priority
                        winners = np.full(len(p), i)
                else:
                    d = smin(d, di, part.k)
                    if want_parts:
                        cand = di - part.priority
                        better = cand < best
                        best = np.where(better, cand, best)
                        winners = np.where(better, i, winners)
            else:  # sub
                carved = -di > d
                d = smax(d, -di, part.k)
                if want_parts and part.mat is not None:
                    winners = np.where(carved, i, winners)
        if want_parts:
            return d, winners, per
        return d

    def gradient(self, p, h=None):
        h = h or self.voxel * 0.5
        e = np.array([[1, -1, -1], [-1, -1, 1], [-1, 1, -1], [1, 1, 1]], dtype=np.float64)
        g = np.zeros_like(p)
        for k in range(4):
            g += e[k] * self.sdf(p + e[k] * h)[:, None]
        n = norm(g)[:, None]
        return g / np.maximum(n, 1e-9)

    def bounds(self):
        lo = np.array([np.inf] * 3)
        hi = np.array([-np.inf] * 3)
        for part in self.parts:
            if part.op != "add":
                continue
            c, r = part.bounds
            c = np.asarray(c)
            cs = [c]
            if part.mirror:
                cs.append(c * np.array([-1, 1, 1]))
            for cc in cs:
                lo = np.minimum(lo, cc - r - part.k)
                hi = np.maximum(hi, cc + r + part.k)
        return lo, hi

    def material_of(self, idx):
        return self.materials[self.parts[idx].mat]

    def bone_index(self):
        return {b.name: i for i, b in enumerate(self.bones)}
