# Roblox con opencode

Proyecto de juegos de Roblox con flujo agéntico completo:
lectura → búsqueda → planificación → ejecución → testeo → revisión →
versiones → seguimiento.

## Requisitos

- opencode >= 1.18 (`opencode --version`)
- Git
- Toolchain Roblox (instalar con `scripts/setup.sh` o manual):
  Rokit + `rojo-rbx/rojo`, `lune-org/lune`, `kampfkarren/selene`,
  `JohnnyMorganz/StyLua`, `JohnnyMorganz/luau-lsp`, `UpliftGames/wally`
- Roblox Studio (Windows/Mac) para lo visual y el playtest.
  En Linux, Studio no corre nativo: desarrolla aquí y sincroniza por git
  a una máquina con Studio.

## Puesta en marcha

```bash
cd roblox
bash scripts/setup.sh    # verifica toolchain + descarga defs de tipos (.defs/)
bash scripts/validate.sh # puerta de calidad: selene + stylua + tipos + tests (exit 0)
git init && git add -A && git commit -m "chore: scaffold inicial Rojo+opencode"
rojo serve               # sync en vivo con Studio (abre el place y conecta)
```

## Habilitar el MCP de Roblox Studio (Windows/Mac)

1. En Studio: Assistant → `⋯` → Manage MCP Servers → activar
   "Enable Studio as MCP server".
2. En este `opencode.json`, servidor `roblox-studio`: poner
   `"disabled": false` y ajustar `command` según tu SO:
   - Windows: `["cmd.exe", "/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"]`
   - macOS: el binario `StudioMCP` dentro de `RobloxStudio.app`
     (ver plugin oficial `Roblox/roblox-studio-agent-plugin`).
3. Reiniciar opencode y verificar con `opencode mcp list`.

## Uso

- `/roblox-nuevo-juego "un tycoon de pizzería con 3 niveles"` — pipeline completo
- `/roblox-feature "sistema de checkpoints con DataStore"` — una feature
- `/roblox-debug-loop "los jugadores atraviesan la puerta"` — fix iterativo
- O delega directo a un subagente (`@roblox-planificador`, `@roblox-testeador`…).

Tras cambiar `opencode.json`, agentes, skills o commands: **salir y reiniciar
opencode** (la config se carga una sola vez al inicio).
