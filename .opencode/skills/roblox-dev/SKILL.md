---
name: roblox-dev
description: "Use when writing or reviewing Luau code, RemoteEvents, DataStores, or client-server architecture for Roblox. Trigger keywords: Luau, RemoteEvent, RemoteFunction, DataStore, ServerScriptService, ReplicatedStorage, Studio MCP, --!strict, task.wait. Covers strict typing, server-authoritative security, and the official Studio MCP tools."
license: MIT
compatibility: opencode
---

# Roblox Dev

Referencia técnica para generar Luau correcto y seguro. Inspirada en
`MSayib/roblox-dev-skill` y `RBSmithy` (verificar contra
https://create.roblox.com/docs antes de afirmar límites o APIs).

## Fundamentos Luau

- Todo archivo nuevo empieza con `--!strict`.
- `task.wait()`, `task.spawn()`, `task.defer()` — nunca `wait()`/`spawn()`.
- Servicios vía `game:GetService("...")`. Tipos del New Type Solver
  (`Instance`, `RBXScriptConnection`, etc.).
- Módulos: un sistema = un ModuleScript en `src/shared` o `src/server`,
  con API mínima y sin estado global mutable salvo stores explícitos.

## Arquitectura cliente-servidor

- Servidor (`ServerScriptService`): autoridad total — economía, inventario,
  daño, progresión, DataStores, validación de remotes.
- Cliente (`StarterPlayerScripts`): input, cámara, UI, efectos; NUNCA otorga
  nada (ni moneda, ni items, ni XP).
- Compartido (`ReplicatedStorage`): tipos, constantes, configs, utilidades puras.
- Comunicación: `RemoteEvent` (sin respuesta) / `RemoteFunction` (con respuesta,
  usar con moderación) / `BindableEvent` solo dentro del mismo contexto.

## Seguridad (bloqueante en revisión)

Todo `RemoteEvent.OnServerEvent` DEBE validar antes de actuar:

1. Tipos de cada argumento (`typeof(x) == "number"`, etc.).
2. Rangos y coherencia (cantidad > 0, item existe en catálogo del servidor).
3. Rate limit por jugador (rechazar spam).
4. Distancia/estado (¿el jugador está cerca del objeto? ¿vivo? ¿en la zona?).
5. Jamás `require()` de un ModuleScript enviado por el cliente.

Patrones prohibidos: moneda en LocalScript, `ProcessReceipt` que entrega sin
verificar, guardar payloads crudos del cliente en DataStore, `BindToClose`
sin guard.

## DataStores y persistencia

- Session locking (ProfileService/ProfileStore o equivalente): una sola
  escritura activa por jugador.
- Esquema versionado + migraciones + defaults; guardado con reintentos y
  `game:BindToClose()` en Studio/ShutDown.
- Nunca perder datos por error de tipos: validar antes de `SetAsync`.

## MCP oficial de Roblox Studio (cuando está habilitado)

| Grupo | Herramientas |
|---|---|
| Scripts | `script_read`, `multi_edit`, `script_search`, `script_grep` |
| Ejecución Luau | `execute_luau` (Edit / Client / Server) |
| Assets | `generate_mesh`, `generate_material`, `generate_procedural_model`, `search_asset`, `insert_asset`, `upload_image` |
| Exploración | `search_game_tree`, `inspect_instance`, subagent `explore` |
| Playtest | `start_stop_play`, `get_console_output`, `screen_capture`, `character_navigation`, `user_keyboard_input`, `user_mouse_input`, subagent `playtest` |
| Docs | `http_get` (Engine API, Creator docs, guías de performance) |
| Sesión | `list_roblox_studios` (toda llamada lleva `studio_id`) |

Reglas: no escribir en Play mode; revisar scripts de assets del Creator Store
antes de usarlos; leer consola + captura antes de declarar éxito; usar
`http_get` para confirmar APIs en lugar de confiar en memoria.

## Performance (chequeo rápido)

- Object pooling en spawns frecuentes; nada de `Instance.new` en loops calientes.
- `StreamingEnabled` en mapas grandes; LOD/colisiones simples en móviles.
- Remotes con payload mínimo; evitar `RemoteFunction` en hot paths.
