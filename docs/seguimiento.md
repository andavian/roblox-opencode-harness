# Seguimiento del proyecto

Bitácora del ciclo de desarrollo. El subagente `roblox-seguimiento` la
actualiza al cierre de cada feature o juego.

| Fecha | Hito | Intervenciones humanas | Ciclo (idea→jugable) | Estado | Notas |
|-------|------|------------------------|----------------------|--------|-------|
| 2026-10-20 | Leaderboard con DataStore (Coins/Wins, autosave, BindToClose) | 0 (pendiente confirmación humana para push/merge + playtest Studio) | idea→código listo sin playtest (1 ciclo, 2 rondas revisor) | Código en rama, sin merge | Rama `feat/leaderboard-datastore` @ `c80cd4b`; testeador PASS; revisor R2 APROBADO |
| 2026-10-20 | Toolchain luau-lsp + harness lune + validate.sh | 0 (pipeline ejecutado por primario directo; pendiente push/merge humano) | idea→puerta única verde mismo día (1 ciclo, 1 ronda revisor) | Código en rama, sin push (sin remoto) | Rama `feat/leaderboard-datastore` @ `aedee6e`; testeador PASS 26/0; revisor R1 APROBADO |

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

## 2026-10-20 — Feature luau-lsp + harness lune + validate.sh

- **Feature:** puerta única de validación `scripts/validate.sh` + tipos estrictos luau-lsp con defs cacheadas + harness de tests Lune zero-dep.
- **Archivos:**
  - `scripts/validate.sh` (ensure_defs → selene → stylua --check → rojo sourcemap + luau-lsp analyze → lune run-all)
  - `scripts/ensure_defs.sh`, `aftman.toml`/`rokit.toml` (luau-lsp 1.70.1), `selene.toml`, `.stylua.toml`
  - `tests/lune/run-all.luau` + `tests/lune/LeaderboardConfig.spec.luau` (harness propio)
  - `AGENTS.md` + `README.md`/`docs/*` (puerta única + regla lune-testeable: solo módulos puros sin `game:`/`Instance`/`task`)
- **Rama/commits (`feat/leaderboard-datastore`, sin push — no hay remoto):**
  - `b95a468` feat(toolchain, luau-lsp 1.70.1 + defs + validate.sh)
  - `06b191d` feat(tests, harness + 26 asserts)
  - `7831101` fix(types, requires sin cast + pcall anotado, sin cambio de comportamiento)
  - `aedee6e` docs(validacion, puerta única + regla lune-testeable)
  - Previo en la rama: `9986a32` chore(opencode, subagent_depth 2), `962e174` feat(orquestador), `c80cd4b` leaderboard + `91c6cf2` bitácora.
- **Veredicto testeador:** PASS (`setup.sh` OK; `validate.sh` 4 gates + `PASS 26/0`; sensibilidad propia FAIL + exit 1 con sabotaje 300→301 revertido; artefactos ignorados).
- **Veredicto revisor:** APROBADO ronda 1, 0 bloqueadores, 4 observaciones (~).
- **Métricas:** gates 4/4 verdes | asserts 26/0 | rondas revisor 1 | commits feature 4.
- **Deuda técnica / observaciones (~) pendientes (próximos pasos priorizados):**
  1. Extraer `ensure_defs` a `lib-defs.sh` compartida (duplicación con `setup.sh`).
  2. Unificar anotación `pcall` en helper tipado (hoy anotación inline por llamada).
  3. Session locking real en `PlayerDataStore` (hoy guard de sesión/carga mínimo).
  4. Blindar `assert` del harness contra tablas cíclicas (hoy sin protección).
- **Nota de proceso:** el orquestador nuevo falló 2 veces por `subagent_depth: 1` (sesión cacheada); se fijó a 2 + commit `9986a32`; el pipeline lo ejecutó el primario directo a la espera de reinicio para dogfood real del orquestador.
- **Estado:** sin push ni merge (sin remoto configurado; pendiente confirmación humana).
- **Próximos pasos priorizados:**
  1. Reiniciar opencode (tomar `subagent_depth: 2`) → dogfood del orquestador en la próxima feature.
  2. `git push -u origin feat/leaderboard-datastore` + PR a `main` cuando haya remoto (requiere humano).
  3. Playtest manual en Studio con API Services: join → grant Coins/Wins → leave → rejoin (persistencia) → cierre con jugadores dentro (`BindToClose`).
