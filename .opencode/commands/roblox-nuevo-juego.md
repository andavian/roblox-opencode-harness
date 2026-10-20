---
description: Construye un juego Roblox completo desde una descripción, corriendo el pipeline de 8 fases.
agent: build
---

# Nuevo juego Roblox

**Idea:** $ARGUMENTS

Ejecuta el pipeline completo delegando en subagentes, en orden. No saltes
fases. Si una fase falla, detente y reporta antes de seguir.

## Fase 1 — Lectura

Delega a `@roblox-lector`. Si el repo es scaffold vacío, continúa igual.

## Fase 2 — Búsqueda

Delega a `@roblox-buscador` con: género pedido + APIs que el juego necesitará
(remotes, DataStores, tipos de assets). Exige fuentes.

## Fase 3 — Planificación

Delega a `@roblox-planificador` con mapa + hallazgos + idea. Exige el flujo
de 8 pasos de la skill `roblox-game` y criterios de aceptación por fase.

## Fase 4 — Ejecución

Delega a `@roblox-ejecutor` fase por fase del plan.

## Fase 5 — Testeo

Delega a `@roblox-testeador`: puerta de calidad + playtest (MCP si disponible,
guion manual si no). Máximo 5 intentos por bug.

## Fase 6 — Revisión

Delega a `@roblox-revisor`. Si RECHAZADO: vuelve a Fase 4 con los
bloqueadores. Solo 2 rondas; a la tercera, re-planifica (Fase 3).

## Fase 7 — Versiones

Delega a `@roblox-versiones` (requiere APROBADO). Sin push sin confirmación.

## Fase 8 — Seguimiento

Delega a `@roblox-seguimiento` y reporta el resumen del ciclo al usuario.
