# aura-arena — design (Aura-native)

The product is a live Soft FlatAST world: one 2D box, one ball, and two
physics rule packs that race it. A thin C program would only blit frames.
It is not the simulator. M0 does not ship that viewport.

This is the same loop aura-evolve and aura-go already play. Soft owns the
state. Rule packs are what a later hot-strategy swap would replace.
Worldlines race. A bad line is dropped. The surviving pack is stamped
into the main world. The tape says why.

## One sentence

Two gravity/bounce laws play the same seeded ball. The one that stays in
play longer is KEEP. The one that sticks and dies is DROP. `fiber_live`
is printed only when both joins land.

## North star

1. **FlatAST owns the world.** Position, velocity, gravity, bounce, friction,
   and the main rule slot are workspace data.
2. **Bad pack: DROP.** Its score is recorded. Its final position is not the
   main world. The slot is not updated to it.
3. **Surviving pack: KEEP.** The winning parameters are the main slot, then
   that pack is run again from the same seed so the live world is the kept
   tape.
4. **Replayable tape.** `TAPE`, `RACE`, `KEEP`, `DROP`, `WORLD` are the audit.
   A later C blit may draw them. It does not choose the winner.
5. **Honest fibers.** The race tries `fiber:spawn` / `fiber:join`. The stamp
   is `fiber_live` only when both fiber ids are distinct, both joins return
   a number, the join count equals the spawn count, and `fiber:spawn-backend`
   is greater than 0. Otherwise the same thunks run host-sequential and the
   line is `host-sequential`. A label with no join is not a worldline.
   `backend=2` is the CLI thread fallback, not serve-async.

M0 does not call `hot-strategy:swap!`, `hot-strategy:heal!`, `mutate:rebind`,
or `eval-current`. aura-go already saw `eval-current` wipe a live board.

## What M0 actually does

```
m0_smoke.aura
    │  load world + rules
    ▼
same seed, two packs
    │  rules-heavy (mid 1)   g=4, bounce 1/3, friction 2
    │  rules-light (mid 2)   g=1, bounce 2/3, friction 1
    ▼
compare integer scores
    │  score = alive * 1000000 + energy
    │  alive  = ticks before the ball sticks (y=0 and ke=0)
    │  energy = sum of vx²+vy² on those ticks
    │  KEEP longer survival (energy breaks a survival tie)
    │  DROP the shorter life
    ▼
replay winner into the main world
    │  TAPE every 10 in-play ticks
    ▼
ARENA_M0_OK
```

The stuck frame is not committed. That is the rollback of the death tick.

## Soft vs C

| Soft owns | C may do (later) |
|-----------|------------------|
| box, ball, rule slot, score | blit of the tape |
| which pack is main | nothing about KEEP/DROP |
| the fiber stamp | nothing about joins |

C must not keep a second arena.

## Soft ≠ Restricted

| | This product | Not this product |
|--|----------------|------------------|
| World | FlatAST workspace defines | A native plugin / `.so` region |
| Sandbox | **off** (same as aura-go / aura-evolve smoke) | Restricted mode as the play loop |
| Fibers | honest `fiber_live` or `host-sequential` | a label with no join |

## Score

`alive * 1000000 + energy`.

- The ball starts at `(16, 36)`. One LCG step from seed `20261005`
  (`(seed * 75 + 74) mod 65537`) sets `vx = 2 + rng mod 3`, `vy = rng mod 5`.
- Each tick: `vy = vy - g`, then integrate, then walls.
- Wall and floor bounce replace the outward velocity with
  `-quotient(v * bounce-num, bounce-den)` (toward zero).
- Floor contact also pulls `vx` toward 0 by `fric`.
- Kinetic energy is `vx*vx + vy*vy` after the bounce.
- When `y = 0` and that energy is 0, the ball is out of play. Later ticks
  do not add to `alive`.

KEEP uses the greater score. On this seed the lives differ, so the reason
is `longer-survival-stamp` / `shorter-survival-rollback`. A survival tie
would use `higher-energy-stamp`. A full tie keeps heavy.

## Non-goals

- Not a rigid-body engine, not Box2D, not a game.
- Not a C viewport in M0.
- Not a fake `fiber_live`.
- Not a second strategy language. Packs are Soft parameters in this file.
- No keys in the tree.

## Files

| Path | Role |
|------|------|
| `soft/arena/world.aura` | box, integer step, live tick, score, tape |
| `soft/arena/rules.aura` | two packs, race, KEEP/DROP, honest world line |
| `soft/arena/hot.aura` | `ar:law` hot-strategy seed / swap / heal |
| `soft/arena/propose.aura` | propose gate / KEEP / DROP |
| `soft/arena/m0_smoke.aura` | evidence, `ARENA_M0_OK` |
| `soft/arena/m1_smoke.aura` | evidence, `ARENA_M1_OK` |
| `soft/arena/m2_propose_smoke.aura` | fixture propose, `ARENA_M2_PROPOSE_OK` |
| `docs/m0.md` / `m1.md` / `m2.md` | scripted numbers |
| `scripts/smoke_soft.sh` | M0 docker tip binary |
| `scripts/smoke_m1.sh` | M1 evidence |
| `scripts/smoke_m2.sh` | M2 fixture evidence |
| `scripts/burn.sh` | multi-round burn |

## 中文

产品是同一颗球上的两套物理规则赛。活得更久的 KEEP 进主世界，先粘死的
DROP。Soft 拥有盒子和规则槽。M0 没有 C 视口。只有两条 fiber 都 join 到
分数、且 backend > 0 时才印 `fiber_live`，否则是 `host-sequential`。

## M1 / M2

M1 registers `ar:law` as a real `std/hot-strategy` slot, swaps and heals
mid-run, prints `MUTATE tick=8 fric-boost=1`, then races heavy vs light
with the same honest `fiber_live` rule as M0. Detail: `docs/m1.md`.

M2 gates a host-written `(lambda () (list g bn bd fric))` from MiniMax
(`api.minimax.cn` only), KEEPs only on a strict score improvement, else
DROP + `heal!`. Detail: `docs/m2.md`. No keys in the tree.
