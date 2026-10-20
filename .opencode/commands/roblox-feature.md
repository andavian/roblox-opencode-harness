---
description: Implementa una feature (sistema, mecánica o contenido) con el pipeline corto lector-plan-ejecuta-testea-revisa-versiona.
agent: build
---

# Feature Roblox

**Feature:** $ARGUMENTS

Delega el pipeline completo al subagente `@roblox-orquestador` (modo
`feature`) con la herramienta Task en una sola llamada, pasándole la
feature de arriba verbatim. No ejecutes fases tú mismo.

Espera su reporte final y, si se detuvo en el CHECKPOINT con una pregunta
pendiente, preséntasela al usuario tal cual. Cierra con su resumen:
archivos cambiados, veredicto, rama, próximos pasos.
