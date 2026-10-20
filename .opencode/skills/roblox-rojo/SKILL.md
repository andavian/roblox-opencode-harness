---
name: roblox-rojo
description: "Use when setting up, extending, or debugging a Rojo filesystem project synced with Roblox Studio. Trigger keywords: Rojo, default.project.json, rojo serve, rojo build, Wally, Rokit, Packages, project structure, sync."
license: MIT
compatibility: opencode
---

# Roblox Rojo

Estructura y toolchain filesystem-first. Inspirada en `KanzeroG/rojo-roblox-skill`.

## Layout canónico (este repo ya lo implementa)

```
src/server/   → ServerScriptService   (*.server.luau, init.server.luau)
src/client/   → StarterPlayerScripts  (*.client.luau, init.client.luau)
src/shared/   → ReplicatedStorage     (módulos, tipos, configs)
src/workspace → Workspace             (modelos .rbxmx, sin scripts sueltos)
default.project.json  → mapa de sync (no duplicar rutas)
```

Reglas: un feature = un módulo; nada suelto en la raíz de un servicio;
`$path` único por carpeta (sin solapamientos); los `.rbxmx` viven en
`src/workspace`, nunca mezclados con código.

## Toolchain (Rokit + Wally)

```bash
rokit add rojo-rbx/rojo lune-org/lune kampfkarren/selene \
  JohnnyMorganz/StyLua UpliftGames/wally
rojo serve     # sync en vivo con Studio (puerto 34872 por defecto)
rojo build -o build/game.rbxlx   # artefacto versionable
```

`wally.toml` para dependencias (`Packages/` y `_Index/` NO se versionan,
`wally.lock` SÍ). `selene.toml` con `std = "roblox"` y `stylua.toml` del repo
son la puerta de calidad antes de cada sync.

## Sync y solución de problemas

- Rojo sincroniza código y modelos; NO sincroniza Terrain/BinaryData en
  live-sync (eso se edita en Studio y se guarda en el `.rbxl`).
- Conflicto two-way sync: la fuente de verdad es `src/` (git). Si Studio y
  disco divergen, se re-aplica desde disco.
- Tras actualizar Studio o Rojo: `rojo serve` de prueba + playtest de humo
  antes de seguir (la cadena Rojo/Studio es el punto frágil conocido).
