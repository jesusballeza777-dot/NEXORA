#!/usr/bin/env bash
# Verificación completa del repositorio (lo que corre CI y lo que corre Claude antes de cada commit).
# Requiere: rokit install (rojo, lune, stylua, selene) y Node 18+.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "▸ Formato (StyLua)";            stylua --check src tests tools/web-preview/build.luau
echo "▸ Lint (Selene)";               selene src tests
echo "▸ Pruebas (Lune)";              lune run tests/runner
echo "▸ Proyecto Rojo";               mkdir -p build && rojo build default.project.json -o build/NEXORA.rbxlx
echo "▸ Vista previa web";            lune run tools/web-preview/build
echo "▸ Paridad motor Luau ↔ JS";     node tools/web-preview/parity.mjs
echo "✔ Todo en orden"
