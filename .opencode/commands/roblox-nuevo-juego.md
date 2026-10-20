---
description: Construye un juego Roblox completo desde una descripción, corriendo el pipeline de 8 fases.
agent: build
---

# Nuevo juego Roblox

**Idea:** $ARGUMENTS

Delega el pipeline completo al subagente `@roblox-orquestador` (modo
`nuevo-juego`) con la herramienta Task en una sola llamada, pasándole la
idea de arriba verbatim. No ejecutes fases tú mismo.

Espera su reporte final y, si se detuvo en el CHECKPOINT con una pregunta
pendiente, preséntasela al usuario tal cual. Cierra con su resumen:
archivos cambiados, veredicto, rama, próximos pasos.
