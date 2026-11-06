---
description: Implementa una feature (sistema, mecánica o contenido) con el pipeline corto lector-plan-ejecuta-testea-revisa-versiona.
agent: build
---

# Feature Roblox

**Feature:** $ARGUMENTS

> **Guard de harness:** si existe `scripts/new-game.sh`, estás en el harness
> generador de juegos — no implementes features de juego ni debug aquí.
> Genera un juego con `bash scripts/new-game.sh <nombre>` o cambia al
> directorio del juego; solo continúa con el orquestador si este marcador no
> existe.

Delega el pipeline completo al subagente `@roblox-orquestador` (modo
`feature`) con la herramienta Task en una sola llamada, pasándole la
feature de arriba verbatim. No ejecutes fases tú mismo.

Espera su reporte final y, si se detuvo en el CHECKPOINT con una pregunta
pendiente, preséntasela al usuario tal cual. Cierra con su resumen:
archivos cambiados, veredicto, rama, próximos pasos.
