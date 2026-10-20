---
description: Implementa una feature (sistema, mecánica o contenido) con el pipeline corto lector-plan-ejecuta-testea-revisa-versiona.
agent: build
---

# Feature Roblox

**Feature:** $ARGUMENTS

Pipeline corto (sin fase de juego completo):

1. `@roblox-lector` — mapa del área afectada.
2. `@roblox-buscador` — APIs/docs necesarias, con fuentes.
3. `@roblox-planificador` — alcance, archivos exactos, criterios de aceptación.
4. `@roblox-ejecutor` — implementa según plan.
5. `@roblox-testeador` — puerta de calidad + prueba de la feature.
6. `@roblox-revisor` — veredicto. Si RECHAZADO, vuelve al paso 4 (máx 2 rondas).
7. `@roblox-versiones` — rama `feat/<nombre>`, commits convencionales.
8. `@roblox-seguimiento` — bitácora y métricas.

Reporta al final: archivos cambiados, veredicto, rama, próximos pasos.
