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
(máx 2 rondas). Requiere `"subagent_depth": 2` en `opencode.json` (con el
default 1 el orquestador no puede despachar subagentes). Se puede invocar a cada subagente directo con `@` para
usos puntuales.

## Harness vs juegos

Este repositorio es el **harness**: una plantilla generadora de proyectos de
juego Roblox, no un juego jugable. Cada juego concreto vive en un directorio
hermano (`../<nombre>/`) generado por `scripts/new-game.sh`.

Flujo:

1. En el harness: `bash scripts/new-game.sh <nombre> [--github] [--no-push]`.
2. `cd ../<nombre>` y abre opencode dentro del proyecto generado.
3. Dentro del juego: `/roblox-nuevo-juego "<idea>"` para ejecutar el pipeline.

Marcador: `scripts/new-game.sh` solo existe en el harness. Si un command lo
detecta, debe generar el juego, no implementar features.

`scripts/sync-harness.sh <game-dir>` propaga actualizaciones del harness al
juego:

- Propaga: `.opencode/**` (tracked), `scripts/setup.sh`,
  `scripts/validate.sh`, `selene.toml`, `stylua.toml` y
  `.opencode/.gitignore`.
- Protege: `src/`, `docs/`, `default.project.json`, `README.md`,
  `rokit.toml`; nunca borra archivos extra del juego.

Tras cambiar commands/skills en `.opencode/`: salir y reiniciar opencode.

### Optimización de modelos (OpenCode Go)

Cada subagente declara `model` y `temperature: 0.1`. Repartimos los agentes
entre distintos modelos para (1) usar el mínimo costo según la tarea y (2)
spread de buckets mensuales (en Go cada modelo tiene su propio límite en
dólares; el límite manda más que el precio por token):

- **Fuertes** (calidad bloqueante): revisor en `glm-5.2` (bucket $60/mes,
  probado atrapando bugs); ejecutor en `kimi-k2.7-code` (bucket $60/mes,
  code-specialized); planificador en `gpt-5.6-luna` (bucket $15/mes, una sola
  llamada por ciclo).
- **Flash** (mecánicos): lector, testeador y orquestador en `mimo-v2.6-flash`
  / `glm-5.3-flash`; buscador en `longcat-2.0` (cache read barato para
  releer contextos grandes).
- **Gratis** (triviales): versiones y seguimiento en `minimax-m3.1-flash-free`
  (promo, fallback a `mimo-v2.6-flash` si se acaba).

Nunca poner modelos caros de poca calidad: `glm-5.3` tiene el mismo precio que
`glm-5.2` pero bucket $15/mes (¼ de capacidad); `kimi-k3` es $3/$15 y bucket
$15/mes. Ambos quedan prohibidos para estos agentes.

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

Puerta única: `bash scripts/validate.sh` (exit 0). Corre, en orden:
`ensure_defs` (defs de tipos para luau-lsp) → `selene src/` →
`stylua --check src/ tests/lune/` → `rojo sourcemap` +
`luau-lsp analyze` (tipos estrictos con defs de Roblox, `tests/lune` excluido) →
`lune run tests/lune/run-all.luau`. Cada gate imprime `== ... ==` y ante un
fallo imprime `FAIL` + sale 1.

Regla lune: solo los módulos puros son lune-testeables — sin `game:`, sin
`Instance`, sin `task` (Lune no los provee). Hoy solo `LeaderboardConfig`
cumple; el servidor (`PlayerDataStore`, `LeaderstatsService`, `init.server`)
se valida con tipos estrictos + playtest en Studio, no con Lune.

Revisión de seguridad de remotes: ver skill `roblox-dev` (bloqueante).
