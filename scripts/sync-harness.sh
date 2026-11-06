#!/usr/bin/env bash
# Propaga archivos de harness a un proyecto de juego.
# Uso: bash scripts/sync-harness.sh <game-dir> [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
    echo "Uso: bash scripts/sync-harness.sh <game-dir> [--dry-run]"
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

GAME_DIR="$1"
shift

DRY_RUN=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=1
            ;;
        *)
            fail "flag desconocido: $1"
            ;;
    esac
    shift
done

# --- Validación del destino ---
if [ ! -d "$GAME_DIR" ]; then
    fail "directorio destino no existe: $GAME_DIR"
fi

GAME_ABS="$(cd "$GAME_DIR" && pwd)"
if [ ! -f "$GAME_ABS/default.project.json" ]; then
    fail "destino no parece un proyecto de juego (falta default.project.json): $GAME_ABS"
fi

# --- Helpers ---
should_propagate() {
    local f="$1"
    case "$f" in
        .opencode/.gitignore) return 0 ;;
        .opencode/*) return 0 ;;
        scripts/setup.sh) return 0 ;;
        scripts/validate.sh) return 0 ;;
        selene.toml) return 0 ;;
        stylua.toml) return 0 ;;
        *) return 1 ;;
    esac
}

report() {
    local action="$1"
    local file="$2"
    printf '%s %s\n' "$action" "$file"
}

copy_file() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
}

# --- Iterar archivos tracked del harness ---
cd "$ROOT"

declare -a actions=()

while IFS= read -r -d '' f; do
    if ! should_propagate "$f"; then
        continue
    fi

    src="$ROOT/$f"
    dst="$GAME_ABS/$f"

    if [ -f "$dst" ]; then
        if cmp -s "$src" "$dst"; then
            report "UNCHANGED" "$f"
        else
            report "UPDATE" "$f"
            if [ "$DRY_RUN" -eq 0 ]; then
                copy_file "$src" "$dst"
            fi
        fi
    else
        report "ADD" "$f"
        if [ "$DRY_RUN" -eq 0 ]; then
            copy_file "$src" "$dst"
        fi
    fi
done < <(git ls-files -z)

# .opencode/.gitignore explícito desde template
GITIGNORE_SRC="$ROOT/template/.opencode/.gitignore"
GITIGNORE_DST="$GAME_ABS/.opencode/.gitignore"
if [ -f "$GITIGNORE_DST" ]; then
    if cmp -s "$GITIGNORE_SRC" "$GITIGNORE_DST"; then
        report "UNCHANGED" ".opencode/.gitignore"
    else
        report "UPDATE" ".opencode/.gitignore"
        if [ "$DRY_RUN" -eq 0 ]; then
            copy_file "$GITIGNORE_SRC" "$GITIGNORE_DST"
        fi
    fi
else
    report "ADD" ".opencode/.gitignore"
    if [ "$DRY_RUN" -eq 0 ]; then
        copy_file "$GITIGNORE_SRC" "$GITIGNORE_DST"
    fi
fi

# --- Actualizar .harness-version ---
SHORT_SHA="$(git rev-parse --short HEAD)"
DATE_NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NEW_VERSION="harness=$SHORT_SHA date=$DATE_NOW"

if [ -f "$GAME_ABS/.harness-version" ]; then
    OLD_VERSION="$(cat "$GAME_ABS/.harness-version")"
    if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
        report "UNCHANGED" ".harness-version"
    else
        report "UPDATE" ".harness-version ($OLD_VERSION -> $NEW_VERSION)"
        if [ "$DRY_RUN" -eq 0 ]; then
            printf '%s\n' "$NEW_VERSION" > "$GAME_ABS/.harness-version"
        fi
    fi
else
    report "ADD" ".harness-version ($NEW_VERSION)"
    if [ "$DRY_RUN" -eq 0 ]; then
        printf '%s\n' "$NEW_VERSION" > "$GAME_ABS/.harness-version"
    fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] no se escribió nada"
else
    echo "OK - sync-harness.sh completado"
fi
