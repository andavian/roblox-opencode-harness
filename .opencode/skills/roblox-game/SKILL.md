---
name: roblox-game
description: "Use when designing a Roblox game, picking a genre template, planning monetization, or running pre-launch checklists. Trigger keywords: obby, tycoon, simulator, RPG, horror, battle royale, game pass, developer product, publish checklist, game design, monetization, retención."
license: MIT
compatibility: opencode
---

# Roblox Game

Diseño y producción de juegos. Inspirada en `brockmartin/roblox-game-skill`.

## Plantillas por género (sistemas mínimos)

- **Obby**: checkpoints + respawn, 5 obstáculos base, timer/speedrun, leaderboard.
- **Tycoon**: claim de parcela, droppers/collectors, botones comprables por nivel,
  income, tiers.
- **Simulator**: recolección, mascotas (hatch + rareza), zonas, upgrades,
  prestige/rebirth.
- **RPG**: stats + niveles, quests, NPC con diálogo/estados, zonas.
- **Horror**: atmósfera (iluminación/sonido), monstruo con FSM simple
  (idle/patrulla/persigue/ataca), eventos, linterna.
- **Battle Royale**: lobby + matchmaking, tormenta que se cierra, loot spawn,
  tracking de vivos, espectador.

Cada sistema: servidor autoritativo, persistencia si hay progresión, UI mínima
jugable con gamepad/teclado/táctil.

## Flujo "juego nuevo" (8 pasos)

1. Género + fantasía central en 1 frase ("tycoon de pizzería donde…").
2. Loop de juego (acción → recompensa → progresión) en ≤ 5 pasos.
3. Sistemas necesarios mapeados a `src/server|client|shared`.
4. Assets: lista de qué se genera (`generate_mesh`), qué viene del Creator Store
   y qué requiere modelado humano.
5. Implementación por sistemas (un sistema = un módulo testeable).
6. Playtest con MCP: consola + capturas, fix iterativo.
7. Auditoría de seguridad (skill `roblox-dev`) + performance móvil.
8. Checklist de publicación (ver abajo) + `docs/seguimiento.md`.

## Monetización

- Game passes (beneficios permanentes) vs Developer Products (consumibles):
  precios probados contra el loop, nunca pay-to-win que rompa balance.
- `ProcessReceipt`: entregar UNA vez, idempotente, con log.
- Premium payouts y engagement: sesiones > 10 min como objetivo.

## Checklist pre-lanzamiento (resumen)

- [ ] Sin errores en consola en server y cliente tras 5 min de playtest
- [ ] Remotes auditados (validación + rate limit)
- [ ] DataStore: entra/sale sin pérdida, `BindToClose` ok
- [ ] UI legible en móvil (botones ≥ 44px, safe areas)
- [ ] Icono + thumbnails competitivos, descripción con keywords
- [ ] Precios de passes/productos configurados y probados con compra real
- [ ] `docs/seguimiento.md` actualizado con métricas del ciclo
