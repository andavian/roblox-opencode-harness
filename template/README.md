# __GAME_NAME__

Proyecto de juego Roblox generado por [roblox-opencode-harness](https://github.com/andavian/roblox-opencode-harness).

## Requisitos

- opencode >= 1.18 (`opencode --version`)
- Git
- Toolchain Roblox (instalar con `scripts/setup.sh` o manual):
  Rokit + `rojo-rbx/rojo`, `lune-org/lune`, `kampfkarren/selene`,
  `JohnnyMorganz/StyLua`, `JohnnyMorganz/luau-lsp`, `UpliftGames/wally`
- Roblox Studio (Windows/Mac) para lo visual y el playtest.

## Puesta en marcha

```bash
cd __GAME_NAME__
bash scripts/setup.sh    # verifica toolchain + descarga defs de tipos (.defs/)
bash scripts/validate.sh # puerta de calidad: selene + stylua + tipos + tests (exit 0)
rojo serve               # sync en vivo con Studio (puerto 34872)
```

## Uso con opencode

Abre opencode **dentro de este proyecto** (`cd __GAME_NAME__ && opencode`) y usa:

- `/roblox-nuevo-juego "<idea>"` — genera el diseño completo del juego
- `/roblox-feature "<sistema>"` — implementa una feature con el pipeline
- `/roblox-debug-loop "<síntoma>"` — bucle de debug iterativo

Tras cambiar `.opencode/`, agents, skills o commands: **salir y reiniciar
opencode** (la config se carga una sola vez al inicio).
