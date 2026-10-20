# Seguimiento del proyecto

Bitácora del ciclo de desarrollo. El subagente `roblox-seguimiento` la
actualiza al cierre de cada feature o juego.

| Fecha | Hito | Intervenciones humanas | Ciclo (idea→jugable) | Estado | Notas |
|-------|------|------------------------|----------------------|--------|-------|
| 2026-10-20 | Leaderboard con DataStore (Coins/Wins, autosave, BindToClose) | 0 (pendiente confirmación humana para push/merge + playtest Studio) | idea→código listo sin playtest (1 ciclo, 2 rondas revisor) | Código en rama, sin merge | Rama `feat/leaderboard-datastore` @ `c80cd4b`; testeador PASS; revisor R2 APROBADO |

## Kill-criteria activos (del pre-mortem)

- [ ] Crear un juego simple toma igual o más tiempo que Studio + IA integrada.
- [ ] Intervenciones humanas > 20% por feature tras el spike inicial.
- [ ] Costos de API superan la ganancia de productividad del creador indie.
- [ ] Roblox lanza asistencia first-party que anula la ventaja del flujo.

Si se cumple alguno de forma sostenida: archivar o pivotar.

## 2026-10-20 — Feature leaderboard con DataStore

- **Feature:** leaderboard server-authoritative con `leaderstats` Coins/Wins, persistencia DataStore, autosave y `BindToClose`.
- **Archivos (4, +542 inserciones):**
  - `src/shared/LeaderboardConfig.luau`
  - `src/server/Leaderboard/PlayerDataStore.luau`
  - `src/server/Leaderboard/LeaderstatsService.luau`
  - `src/server/Leaderboard/init.server.luau`
- **Rama/commit:** `feat/leaderboard-datastore` @ `c80cd4b` `feat(leaderboard): DataStore con leaderstats Coins/Wins, autosave y BindToClose`.
- **Veredicto testeador:** PASS (selene 0, stylua limpio, `rojo build` OK, seguridad OK).
- **Veredicto revisor:** Ronda 1 RECHAZADO → Ronda 2 APROBADO tras fixes:
  - B1: `require(script.Parent)` roto → requires por nombre vía config/servicios.
  - B2: race que borraba ceros → guard de sesión/carga.
  - B3: load fallido cacheaba defaults → no cachear en fallo, reintento en save.
  - B4: Version hardcodeado → versión desde config.
- **Métricas:** 4 archivos | 2 rondas de revisor | 4 validaciones PASS (selene, stylua, rojo build, seguridad).
- **Estado:** sin push ni merge (pendiente confirmación humana + playtest Studio con API Services).
- **Próximos pasos priorizados:**
  1. `git push -u origin feat/leaderboard-datastore` + abrir PR a `main` (requiere humano).
  2. Playtest manual en Studio con API Services activado, guion: join → grant Coins/Wins → leave → rejoin (verifica persistencia) → cierre con jugadores dentro (verifica `BindToClose`).
  3. Deuda/observaciones (~) del revisor pendientes de confirmar en PR antes del merge.
