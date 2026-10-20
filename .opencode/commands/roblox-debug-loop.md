---
description: Bucle de debug iterativo con evidencia (consola + capturas) hasta 5 intentos por bug.
agent: build
---

# Debug loop Roblox

**Síntoma:** $ARGUMENTS

Repite hasta 5 intentos por bug. Cada intento deja evidencia; sin evidencia
no se considera corregido.

## Por intento

1. **Reproducir**: `@roblox-testeador` con los pasos de reproducción.
   Con MCP: `start_stop_play` + `get_console_output` + `screen_capture`.
   Sin MCP: pide al humano el log de consola de Studio y lo analiza.
2. **Hipótesis**: causa raíz candidata (1 sola por intento, la más probable).
   Consultar `@roblox-buscador` si la API es sospechosa.
3. **Fix mínimo**: `@roblox-ejecutor` con el cambio más pequeño que elimine
   la causa raíz. Prohibido reescribir sistemas enteros en un debug.
4. **Verificar**: `@roblox-testeador` repite la reproducción. Pass solo con
   consola limpia + comportamiento observado.
5. Si falla 5 veces: escalar a `@roblox-planificador` (probable error de
   diseño) y reportar al humano en lugar de seguir iterando.

Al cerrar: `@roblox-revisor` verifica que el fix no introdujo remotes
inseguros ni deprecaciones, y `@roblox-seguimiento` lo registra.
