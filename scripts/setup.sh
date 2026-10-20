#!/usr/bin/env bash
# Verifica los requisitos del proyecto roblox. No instala nada solo:
# informa qué falta y cómo conseguirlo.
set -euo pipefail

ok=1
need() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "OK   $1 ($($1 --version 2>/dev/null | head -n1))"
  else
    echo "FALTA $1 -- $2"
    ok=0
  fi
}

need git "https://git-scm.com/downloads"
need opencode "https://opencode.ai (ya instalado si lees esto)"
need rokit "cargo install rokit  |  brew install rokit  |  https://github.com/rojo-rbx/rokit"
need rojo "rokit add rojo-rbx/rojo  (tras instalar rokit)"
need lune "rokit add lune-org/lune"
need selene "rokit add kampfkarren/selene"
need stylua "rokit add JohnnyMorganz/StyLua"
need wally "rokit add UpliftGames/wally"

if [ ! -f default.project.json ]; then
  echo "FALTA default.project.json en la raíz del proyecto"
  ok=0
fi

if [ "$ok" -eq 1 ]; then
  echo "Todo listo: ejecuta 'rojo serve' y conecta Roblox Studio."
else
  echo "Instala lo marcado como FALTA y vuelve a ejecutar este script."
  exit 1
fi
