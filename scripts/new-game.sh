#!/usr/bin/env bash
# Genera un proyecto de juego Roblox autónomo en ../<nombre>/.
# Uso: bash scripts/new-game.sh <nombre> [--github] [--no-push]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
    echo "Uso: bash scripts/new-game.sh <nombre> [--github] [--no-push]"
    exit 1
}

fail() {
    echo "FAIL - $1" >&2
    exit 1
}

# --- Parseo de argumentos ---
if [ "$#" -lt 1 ]; then
    usage
fi

RAW_NAME="$1"
shift

GITHUB=0
NO_PUSH=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --github)
            GITHUB=1
            ;;
        --no-push)
            NO_PUSH=1
            ;;
        *)
            fail "flag desconocido: $1"
            ;;
    esac
    shift
done

if [ "$NO_PUSH" -eq 1 ] && [ "$GITHUB" -eq 0 ]; then
    fail "--no-push solo se puede usar junto con --github"
fi

# --- Validaciones previas ---
command -v git >/dev/null 2>&1 || fail "git no está disponible (https://git-scm.com/downloads)"

# Verificar working tree válido del harness
if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    fail "$ROOT no es un working tree git válido"
fi

# --- Normalización del nombre ---
normalize_name() {
    local s="$1"
    # trim
    s="$(printf '%s' "$s" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    # minúsculas
    s="$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]')"
    # espacios y _ → -
    s="$(printf '%s' "$s" | tr '[:space:]_' '-')"
    # colapsar guiones múltiples
    s="$(printf '%s' "$s" | sed 's/-\+/-/g')"
    # quitar guiones iniciales/finales
    s="$(printf '%s' "$s" | sed 's/^-//;s/-$//')"
    printf '%s' "$s"
}

NAME="$(normalize_name "$RAW_NAME")"

# Rechazos explícitos
if [ -z "$NAME" ]; then
    fail "nombre vacío tras normalizar"
fi
if printf '%s' "$RAW_NAME" | grep -q '[/\\]'; then
    fail "el nombre no puede contener / ni \\"
fi
if printf '%s' "$RAW_NAME" | grep -q '\.\.'; then
    fail "el nombre no puede contener .."
fi
# detectar no-ASCII o símbolos en el original (salvo espacios, _ y -)
if printf '%s' "$RAW_NAME" | grep -qE '[^[:ascii:]]'; then
    fail "el nombre contiene caracteres no ASCII"
fi
if printf '%s' "$RAW_NAME" | grep -qE '[^[:alnum:][:space:]_-]'; then
    fail "el nombre contiene símbolos no permitidos"
fi

if ! printf '%s' "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then
    fail "nombre inválido tras normalizar: '$NAME'"
fi
if [ "${#NAME}" -gt 48 ]; then
    fail "nombre demasiado largo (${#NAME} chars, máx 48): '$NAME'"
fi

# --- Destino ---
DEST="$(cd "$ROOT/.." && pwd)/$NAME"

if [ -e "$DEST" ]; then
    # está vacío si solo tiene . o .. (o no tiene nada)
    if [ -n "$(ls -A "$DEST" 2>/dev/null || true)" ]; then
        fail "destino no vacío: $DEST"
    fi
fi

mkdir -p "$DEST"

# --- Copia base desde git tracked files ---
cd "$ROOT"

while IFS= read -r -d '' f; do
    # Exclusiones
    case "$f" in
        src/*) continue ;;
        docs/*) continue ;;
        tests/lune/test-leaderboard-config.luau) continue ;;
        template/*) continue ;;
        scripts/new-game.sh) continue ;;
        scripts/sync-harness.sh) continue ;;
    esac

    target="$DEST/$f"
    mkdir -p "$(dirname "$target")"
    cp -a "$f" "$target"
done < <(git ls-files -z)

# --- Overlay del template ---
cp -a "$ROOT/template/." "$DEST/"

# --- Reemplazos quirúrgicos ---
if [ -f "$DEST/default.project.json" ]; then
    sed -i "s/\"roblox-game\"/\"$NAME\"/g" "$DEST/default.project.json"
fi
if [ -f "$DEST/README.md" ]; then
    sed -i "s/__GAME_NAME__/$NAME/g" "$DEST/README.md"
fi

# --- .harness-version ---
SHORT_SHA="$(git rev-parse --short HEAD)"
DATE_NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'harness=%s date=%s\n' "$SHORT_SHA" "$DATE_NOW" > "$DEST/.harness-version"

# --- Git en destino ---
cd "$DEST"

GIT_USER_NAME="$(git config user.name || true)"
GIT_USER_EMAIL="$(git config user.email || true)"
if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
    fail "identidad git no configurada. Ejecuta:\n  git config --global user.name \"Tu Nombre\"\n  git config --global user.email \"tu@email.com\""
fi

git init -b main
git add -A
if ! git commit -m "chore: scaffold desde roblox-opencode-harness@$SHORT_SHA"; then
    fail "git commit inicial falló"
fi

# --- GitHub opcional ---
if [ "$GITHUB" -eq 1 ]; then
    command -v gh >/dev/null 2>&1 || fail "gh (GitHub CLI) no está disponible"
    gh auth status >/dev/null 2>&1 || fail "gh no está autenticado. Ejecuta: gh auth login"

    if [ "$NO_PUSH" -eq 1 ]; then
        gh repo create "andavian/$NAME" --private --source .
    else
        gh repo create "andavian/$NAME" --private --source . --push
    fi
fi

# --- Output final ---
echo ""
echo "Juego generado en: $DEST"
echo "Abre opencode dentro del proyecto:"
echo "  cd ../$NAME && opencode"
echo "Y pasa la idea del juego:"
echo "  /roblox-nuevo-juego \"<idea del juego>\""
