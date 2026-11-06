---
description: Construye un juego Roblox completo desde una descripción, corriendo el pipeline de 8 fases.
agent: build
---

# Nuevo juego Roblox

**Idea:** $ARGUMENTS

## Bifurcación: harness vs juego

Si existe `scripts/new-game.sh`, estás en el **harness** generador de juegos,
no en un juego concreto. Aquí no se implementa el juego: se genera el
proyecto.

1. Deriva un `<nombre>` en kebab-case a partir de `$ARGUMENTS` (ej.
   "tycoon de pizzería" → `tycoon-de-pizzeria`).
2. Por defecto crea el repo privado en GitHub: invoca
   `bash scripts/new-game.sh "<nombre>" --github`.
   Si el usuario pidió explícitamente no crear remoto, usa `--github --no-push`.
   Si pidió solo scaffold local, omite `--github`.
3. No delegues al orquestador en este contexto.
4. Indica al usuario que abra opencode dentro de `../<nombre>/` y corra allí
   `/roblox-nuevo-juego "<idea>"`.

Si `scripts/new-game.sh` **no** existe, estás dentro de un proyecto de juego
ya generado: delega el pipeline completo al subagente `@roblox-orquestador`
(modo `nuevo-juego`) con la herramienta Task en una sola llamada, pasándole
la idea de arriba verbatim. No ejecutes fases tú mismo.

Espera su reporte final y, si se detuvo en el CHECKPOINT con una pregunta
pendiente, preséntasela al usuario tal cual. Cierra con su resumen:
archivos cambiados, veredicto, rama, próximos pasos.
