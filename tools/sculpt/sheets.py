"""
Hojas de revisión de los iniciales (entregables de la Biblia p. 118) a partir de los activos
finales de assets/Creatures/Initials y de esculturas de revisión (expresiones y estilos).

  python3 tools/sculpt/sheets.py <ruta three/package> [--skip-builds]

Salida: docs/phase3/creatures/<especie>-*.jpg y proposals-*.jpg
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
OUT = ROOT / "docs" / "phase3" / "creatures"
TMP = ROOT / "build" / "sculpt" / "sheets"
SPECIES = [("kuachi", "Kuachi", "Ascuacho"), ("xolumi", "Xolumi", "Xolossus"), ("teselo", "Teselo", "Mitlaxis")]
EXPR = ["neutral", "desafio", "ataque", "victoria", "cansado", "carino"]
EXPR_LABEL = {"neutral": "Neutral", "desafio": "Desafío", "ataque": "Ataque", "victoria": "Victoria", "cansado": "Cansado", "carino": "Cariño"}
# encuadre de la cabeza por forma (centro x, y, z y radio)
HEAD = {
    ("kuachi", "brote"): (0, 1.10, 0.62, 0.55),
    ("kuachi", "tallado"): (0, 1.14, 1.70, 0.62),
    ("xolumi", "brote"): (0, 0.62, 0.50, 0.70),
    ("xolumi", "tallado"): (0, 1.95, 1.10, 1.00),
    ("teselo", "brote"): (0, 0.82, 1.42, 0.52),
    ("teselo", "tallado"): (0, 1.30, 2.20, 0.75),
}
BIOME_BG = "56705a"


def font(size):
    for f in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def run_builds(skip):
    jobs = []
    for sp, _, _ in SPECIES:
        for form in ("brote", "tallado"):
            for e in EXPR:
                jobs.append(["preview", sp, form, e, "", str(TMP / f"{sp}_{form}_{e}.glb")])
            for style in ("juguete", "facetado"):
                jobs.append(["preview", sp, form, "neutral", "", str(TMP / f"{sp}_{form}_style_{style}.glb"), style])
    if skip:
        return

    def go(j):
        out = Path(j[5])
        if out.exists():
            return
        env = dict(os.environ)
        if len(j) > 6:
            env["SCULPT_STYLE"] = j[6]
        subprocess.run([sys.executable, str(HERE / "build.py")] + j[:6], check=True, env=env, stdout=subprocess.DEVNULL)

    TMP.mkdir(parents=True, exist_ok=True)
    with ThreadPoolExecutor(3) as ex:
        list(ex.map(go, jobs))


def asset_path(name, form):
    tag = f"CR_{name}_{'Brote' if form == 'brote' else 'Tallado'}_v01.glb"
    return ROOT / "assets" / "Creatures" / "Initials" / name / tag


def render(three, jobs):
    spec = TMP / "jobs.json"
    spec.write_text(json.dumps({"three": three, "jobs": jobs}))
    subprocess.run(["node", str(HERE / "render.cjs"), str(spec)], check=True)


def label(img, text, size=26, pos=(16, 12)):
    d = ImageDraw.Draw(img)
    f = font(size)
    x, y = pos
    d.text((x + 2, y + 2), text, font=f, fill=(0, 0, 0))
    d.text((x, y), text, font=f, fill=(255, 244, 222))


def grid(paths, cols, cell, labels=None, title=None):
    rows = (len(paths) + cols - 1) // cols
    top = 56 if title else 0
    W = Image.new("RGB", (cols * cell, rows * cell + top), (27, 22, 18))
    if title:
        label(W, title, 30, (16, 12))
    for i, p in enumerate(paths):
        im = Image.open(p).convert("RGB").resize((cell, cell), Image.LANCZOS)
        if labels:
            label(im, labels[i], 22)
        W.paste(im, ((i % cols) * cell, top + (i // cols) * cell))
    return W


def card(render_png, name, form, out):
    """Maqueta de carta: fondo del bioma (Valle), pedestal de luz, marco Común liso, gema y elemento."""
    W, H = 600, 840
    c = Image.new("RGB", (W, H), (60, 70, 56))
    d = ImageDraw.Draw(c)
    for y in range(H):
        t = y / H
        d.line([(0, y), (W, y)], fill=(int(120 - 60 * t), int(150 - 70 * t), int(110 - 60 * t)))
    im = Image.open(render_png).convert("RGB").resize((560, 560), Image.LANCZOS)
    c.paste(im, (20, 110))
    d.rounded_rectangle([6, 6, W - 7, H - 7], 26, outline=(214, 204, 186), width=12)  # marco Común (liso)
    d.ellipse([22, 22, 70, 70], fill=(196, 182, 160), outline=(90, 80, 70), width=3)  # gema Común
    d.ellipse([W - 72, 22, W - 24, 70], fill=(236, 112, 50))  # icono de Fuego/Agua/Tierra (color)
    d.rounded_rectangle([20, H - 150, W - 20, H - 24], 18, fill=(42, 28, 21))
    label(c, name, 44, (40, H - 140))
    label(c, f"{form} · Común", 26, (42, H - 82))
    c.save(out, quality=88)


def main():
    three = sys.argv[1]
    skip = "--skip-builds" in sys.argv
    OUT.mkdir(parents=True, exist_ok=True)
    run_builds(skip)
    jobs = []
    R = TMP / "r"
    for sp, b, t in SPECIES:
        for form, name in (("brote", b), ("tallado", t)):
            m = str(asset_path(name, form))
            for v in ("34", "front", "side", "back"):
                jobs.append({"model": m, "out": str(R / f"{sp}_{form}_{v}.png"), "w": 640, "h": 640, "params": f"view={v}"})
            jobs.append({"model": m, "out": str(R / f"{sp}_{form}_sil64.png"), "w": 64, "h": 64, "params": "view=side&sil=1"})
            jobs.append({"model": m, "out": str(R / f"{sp}_{form}_sil64_34.png"), "w": 64, "h": 64, "params": "view=34&sil=1"})
            hx, hy, hz, hr = HEAD[(sp, form)]
            if form == "tallado":
                for v in ("front", "side", "34"):
                    jobs.append({"model": m, "out": str(R / f"{sp}_head_{v}.png"), "w": 640, "h": 640, "params": f"view={v}&focus={hx},{hy},{hz},{hr}"})
            for e in EXPR:
                jobs.append({"model": str(TMP / f"{sp}_{form}_{e}.glb"), "out": str(R / f"{sp}_{form}_expr_{e}.png"), "w": 480, "h": 480, "params": f"view=34&focus={hx},{hy},{hz},{hr}"})
            for style in ("juguete", "facetado"):
                jobs.append({"model": str(TMP / f"{sp}_{form}_style_{style}.glb"), "out": str(R / f"{sp}_{form}_style_{style}.png"), "w": 640, "h": 640, "params": "view=34"})
            for i, tt in enumerate((0.0, 0.26, 0.52, 0.78)):
                jobs.append({"model": m, "out": str(R / f"{sp}_{form}_walk{i}.png"), "w": 480, "h": 480, "params": f"view=side&anim=walk&t={tt}"})
            jobs.append({"model": m, "out": str(R / f"{sp}_{form}_card.png"), "w": 640, "h": 640, "params": f"view=34&bg={BIOME_BG}&zoom=0.95"})
    R.mkdir(parents=True, exist_ok=True)
    render(three, jobs)

    for sp, b, t in SPECIES:
        # 1) hoja de giro de ambas formas + comparativa
        paths, labels = [], []
        for form, name in (("brote", b), ("tallado", t)):
            for v, lab in (("34", "3/4"), ("front", "Frente"), ("side", "Perfil"), ("back", "Espalda")):
                paths.append(R / f"{sp}_{form}_{v}.png")
                labels.append(f"{name} · {lab}")
        grid(paths, 4, 480, labels, f"{b} → {t} · hoja de giro (activos v01, propuesta)").save(OUT / f"{sp}-turnaround.jpg", quality=84)
        # 2) cabeza del Tallado en tres vistas
        grid([R / f"{sp}_head_{v}.png" for v in ("front", "side", "34")], 3, 520, ["Frente", "Perfil", "3/4"], f"{t} · cabeza en tres vistas").save(OUT / f"{sp}-head.jpg", quality=86)
        # 3) seis expresiones por forma
        for form, name in (("brote", b), ("tallado", t)):
            grid([R / f"{sp}_{form}_expr_{e}.png" for e in EXPR], 3, 400, [EXPR_LABEL[e] for e in EXPR], f"{name} · seis expresiones (escultura de revisión)").save(OUT / f"{sp}-{form}-expressions.jpg", quality=84)
        # 4) siluetas a 64 px (ampliadas sin suavizar) + prueba del rig
        sil = Image.new("RGB", (4 * 256 + 40, 256 + 70), (255, 255, 255))
        label(sil, f"{b} / {t} · siluetas reales a 64 px (perfil y 3/4)", 22, (12, 10))
        for i, (form, v) in enumerate((("brote", "sil64"), ("brote", "sil64_34"), ("tallado", "sil64"), ("tallado", "sil64_34"))):
            im = Image.open(R / f"{sp}_{form}_{v}.png").convert("RGB").resize((256, 256), Image.NEAREST)
            sil.paste(im, (8 + i * 262, 56))
        sil.save(OUT / f"{sp}-silhouettes.jpg", quality=90)
        paths = [R / f"{sp}_{form}_walk{i}.png" for form in ("brote", "tallado") for i in range(4)]
        grid(paths, 4, 360, [f"t={x}" for x in ("0", "1/4", "1/2", "3/4")] * 2, f"{b} / {t} · prueba del esqueleto: ciclo de paso procedural sobre el GLB").save(OUT / f"{sp}-rig-walk.jpg", quality=82)
        # 5) cartas
        card(R / f"{sp}_brote_card.png", b, "Brote", OUT / f"{sp}-card-brote.jpg")
        card(R / f"{sp}_tallado_card.png", t, "Tallado", OUT / f"{sp}-card-tallado.jpg")
    # 6) tres propuestas visuales (A artesanal = activo final; B juguete; C facetado)
    for form in ("brote", "tallado"):
        paths, labels = [], []
        for sp, b, t in SPECIES:
            name = b if form == "brote" else t
            paths += [R / f"{sp}_{form}_34.png", R / f"{sp}_{form}_style_juguete.png", R / f"{sp}_{form}_style_facetado.png"]
            labels += [f"A · Artesanal · {name}", f"B · Juguete · {name}", f"C · Facetado · {name}"]
        grid(paths, 3, 460, labels, f"Tres propuestas visuales · {'Brotes' if form == 'brote' else 'Tallados'} (A recomendada)").save(OUT / f"proposals-{form}.jpg", quality=82)
    print("hojas en", OUT)


if __name__ == "__main__":
    main()
