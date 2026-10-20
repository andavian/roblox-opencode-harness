# AGENTS.md — Proyecto Roblox con opencode

Stack: **Luau (`--!strict`) + Rojo + Roblox Studio**. El código vive en `src/` y se
sincroniza a Studio con Rojo. Studio sigue siendo la herramienta visual
(modelado, terreno, iluminación, escena); opencode trabaja el código.

## Layout Rojo (no inventar otra estructura)

- `src/server/` → `ServerScriptService` (lógica de servidor, DataStores, validación)
- `src/client/` → `StarterPlayer > StarterPlayerScripts` (UI, input, controllers)
- `src/shared/` → `ReplicatedStorage` (módulos, tipos, constantes, RemoteEvents)
- `src/workspace/` → `Workspace` (modelos `.rbxmx`, nunca scripts sueltos)
- `default.project.json` es el mapa sync. No poner scripts sueltos en la raíz
  de `ServerScriptService`: un sistema = un ModuleScript + requires.

## Reglas duras de Luau

- Siempre `--!strict` al inicio de cada archivo nuevo.
- `task.wait()` / `task.spawn()` — NUNCA `wait()` ni `spawn()` (deprecados).
- **Nunca confiar en el cliente**: validar TODO input de RemoteEvent/RemoteFunction
  en el servidor (tipos, rangos, rate limits). Moneda, items, XP y daño solo los
  otorga el servidor.
- Nombres: `init.server.luau`, `init.client.luau`, `*.server.luau`,
  `*.client.luau`, `*.luau` para módulos.

## Pipeline obligatorio (orquestado)

Los commands (`/roblox-feature`, `/roblox-nuevo-juego`, `/roblox-debug-loop`)
delegan en `@roblox-orquestador`, que invoca a los 8 subagentes en orden,
aplica fast-path en cambios triviales y reintenta el loop revisor→ejecutor
(máx 2 rondas). Se puede invocar a cada subagente directo con `@` para
usos puntuales.

1. `roblox-lector` → mapa del repo y lagunas
2. `roblox-buscador` → docs oficiales + codebase (con fuentes)
3. `roblox-planificador` → plan con criterios de aceptación
4. `roblox-ejecutor` → implementa
5. `roblox-testeador` → valida (selene, stylua, luau-lsp; MCP Studio si disponible)
6. `roblox-revisor` → code review + auditoría de seguridad (bloqueante)
7. `roblox-versiones` → git (rama por feature, commits convencionales).
   Solo corre tras el CHECKPOINT: el orquestador pide confirmación con la
   herramienta `question` y sin "commitear" explícito no hay commit.
8. `roblox-seguimiento` → bitácora en `docs/seguimiento.md`

Ningún código llega a `main` sin pasar por revisor. Ningún RemoteEvent llega
al servidor sin validación.

## Skills disponibles (se activan por keywords)

- `roblox-dev`: Luau, arquitectura cliente-servidor, seguridad, DataStores, MCP Studio
- `roblox-game`: plantillas por género, monetización, checklists de publicación
- `roblox-rojo`: layout, toolchain (Rokit/Wally), sync y build con Rojo

## MCP Roblox Studio

- Servidor `roblox-studio` en `opencode.json` viene **deshabilitado** a propósito:
  Studio solo corre en Windows/Mac y el MCP usa stdio (misma máquina).
- En Linux el flujo es Rojo + CLI; Studio corre en otra máquina y el código
  viaja por git. Ver `README.md` para habilitarlo en Windows/Mac.
- Con MCP activo, herramientas esperadas: `script_read`, `multi_edit`,
  `execute_luau`, `screen_capture`, `start_stop_play`, `get_console_output`,
  `generate_mesh`, `search_asset`, `insert_asset`, `http_get` (docs).
- Reglas con MCP: jamás escribir en Play mode sin confirmar; leer `screen_capture`
  y consola antes de declarar algo "funcionando"; no insertar assets del Creator
  Store sin revisar scripts incluidos.

## Validación mínima antes de cada sync

1. `selene` (std roblox) sin errores
2. `stylua --check` limpio
3. `luau-lsp` / análisis de tipos sin errores
4. Revisión de seguridad de remotes (ver skill `roblox-dev`)
