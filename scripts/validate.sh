#!/usr/bin/env bash
# Puerta de calidad del proyecto: linters + tipos + tests Lune.
# Uso: bash scripts/validate.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.rokit/bin:$PATH"

fail() {
    echo "FAIL - $1" >&2
    exit 1
}

gate() {
    echo "== $1 =="
}

ensure_defs() {
    local url="${DEFS_URL:-https://luau-lsp.pages.dev/type-definitions/globalTypes.PluginSecurity.d.luau}"
    local dest=".defs/globalTypes.PluginSecurity.d.luau"
    mkdir -p .defs
    if [ -s "$dest" ]; then
        echo "OK   defs ($dest)"
        return 0
    fi
    echo "Descargando defs: $url -> $dest"
    if command -v curl >/dev/null 2>&1 && curl -fsSL "$url" -o "$dest"; then
        echo "OK   defs ($dest)"
    else
        echo "FAIL - no se pudo descargar $dest desde $url" >&2
        echo "  Descarga manual: curl -fsSL '$url' -o '$dest'" >&2
        echo "  O define DEFS_URL con un mirror interno y reintenta." >&2
        rm -f "$dest"
        return 1
    fi
}

gate "toolchain (rokit install + probes de ayuda)"
rokit install || fail "rokit install"
luau-lsp analyze --help >/dev/null || fail "luau-lsp analyze --help"
rojo sourcemap --help >/dev/null || fail "rojo sourcemap --help"
# Nota flags (verificado): `lune run --help` NO existe — lune interpreta
# `--help` como ruta de script ("Failed to resolve script ... --help").
# La ayuda real es `lune --help` y `lune help run`. Se prueba eso aquí.
lune --help >/dev/null || fail "lune --help"
lune help run >/dev/null || fail "lune help run"

gate "defs (globalTypes.PluginSecurity para luau-lsp)"
ensure_defs || fail "ensure_defs (ver mensaje de descarga manual arriba)"

gate "selene src/"
selene src/ || fail "selene src/"

gate "stylua --check src/ tests/lune/"
stylua --check src/ tests/lune/ || fail "stylua --check src/ tests/lune/"

gate "sourcemap + luau-lsp analyze"
rojo sourcemap default.project.json -o sourcemap.json || fail "rojo sourcemap"
DEFS_PATH=".defs/globalTypes.PluginSecurity.d.luau"
# Fallbacks verificados 2026-10-20 (luau-lsp 1.70.1):
# - --definitions=@NAME=PATH (canónico) -> --definitions=PATH -> --defs=PATH
# - --platform=roblox (minúsculas, válido) -> Roblox es INVÁLIDO
#   ("Invalid argument Roblox - allowed options: {standard, roblox}") ->
#   omitir --platform y documentarlo.
ANALYZE_OK=0
if luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json "--definitions=@roblox=${DEFS_PATH}" --ignore="tests/lune/**" src; then
    ANALYZE_OK=1
elif luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json "--definitions=${DEFS_PATH}" --ignore="tests/lune/**" src; then
    echo "nota: usado fallback --definitions=PATH (sin @roblox=)"
    ANALYZE_OK=1
elif luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json "--defs=${DEFS_PATH}" --ignore="tests/lune/**" src; then
    echo "nota: usado fallback --defs=PATH"
    ANALYZE_OK=1
elif luau-lsp analyze --sourcemap=sourcemap.json "--definitions=@roblox=${DEFS_PATH}" --ignore="tests/lune/**" src; then
    echo "nota: --platform omitido (documentar: ni roblox ni Roblox aceptados por este luau-lsp)"
    ANALYZE_OK=1
fi
[ "$ANALYZE_OK" -eq 1 ] || fail "luau-lsp analyze (todos los fallbacks de flags fallaron)"

gate "lune run tests/lune/run-all.luau"
lune run tests/lune/run-all.luau || fail "lune run tests/lune/run-all.luau"

echo "OK - validate.sh: todos los gates pasaron"
exit 0
