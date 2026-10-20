---
description: Bucle de debug iterativo con evidencia (consola + capturas) hasta 5 intentos por bug.
agent: build
---

# Debug loop Roblox

**Síntoma:** $ARGUMENTS

Delega el bucle completo al subagente `@roblox-orquestador` (modo
`debug-loop`) con la herramienta Task en una sola llamada, pasándole el
síntoma de arriba verbatim. No ejecutes pasos tú mismo: el orquestador
repite reproducir → hipótesis → fix mínimo → verificar (máx 5 intentos),
escala a planificador si el 5.º falla, y cierra con revisor + seguimiento.

Espera su reporte final y, si se detuvo en un CHECKPOINT con una pregunta
pendiente, preséntasela al usuario tal cual. Cierra con su resumen:
causa raíz, fix aplicado, evidencia, rama, próximos pasos.
