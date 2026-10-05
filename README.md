# aura-arena

Aura Arena is a live Soft world. One box, one ball, and two physics rule
packs — heavy sticky gravity against light bounce — are a Soft FlatAST
program. A thin C viewport, later, only blits frames. There is no C binary
in this tree.

Design: [`docs/DESIGN.md`](docs/DESIGN.md).
Milestones: [`docs/m0.md`](docs/m0.md), [`docs/m1.md`](docs/m1.md), [`docs/m2.md`](docs/m2.md).
Repo: https://github.com/cybrid-systems/aura-arena

This is not a physics engine and not a game. The product is the Aura loop:
two laws race the same seed, the surviving pack is stamped into main, the
loser is dropped.

- **M0** races `rules-heavy` and `rules-light` on one ball. Score is
  time-in-play, with integrated kinetic energy as the tie break.
  `fiber_live` only when both fiber joins return scores (`joins` equals
  spawned, backend > 0). Otherwise `host-sequential`. No C viewport.
  No `hot-strategy`.
- **M1** swaps and heals the `ar:law` slot mid-run, then races the same
  two packs. `fiber_live` only when both fiber joins return scores.
  Otherwise `host-sequential`. See `docs/m1.md`.
- **M2** gates a proposed `(lambda () (list g bn bd fric))` and KEEPs it
  only when its score is strictly greater than the current main. A tie or
  a loss is DROP plus `hot-strategy:heal!`. HTTP is host-side only.

## Soft smoke

Image `ghcr.io/cybrid-systems/dev:v1.0.9`, Soft tip binary
`/workspace/aura-grok/build/aura` (host GLIBC is often too old — smoke always
runs Soft inside Docker with `--entrypoint /usr/local/bin/gosu`). Soft runs
natively in that container (no nested docker). Never `build_soft4132`.
Needs `AURA_SANDBOX=off`. `python3` is the host interpreter for
`scripts/propose_minimax.py` and `scripts/burn.sh`.

```bash
bash scripts/smoke_soft.sh    # M0 → ARENA_M0_OK
bash scripts/smoke_m1.sh      # SWAP / HEAL / MUTATE / KEEP / DROP → ARENA_M1_OK
bash scripts/smoke_m2.sh      # fixture propose → ARENA_M2_PROPOSE_OK
bash scripts/smoke.sh         # the stack, plus live MiniMax or LIVE_SKIP + burn
bash scripts/burn.sh          # 3 rounds, horizon 24; fixtures if ARENA_PROPOSE=0
```

Scripts may be mode `100644` in git. Always invoke them with `bash`.

Manual Soft run:

```bash
sudo docker run --rm --entrypoint /usr/local/bin/gosu \
  -v /workspace/aura-grok:/workspace/aura-grok \
  -v "$PWD":/workspace/aura-arena \
  -w /workspace/aura-arena \
  -e AURA_PATH=/workspace/aura-grok/lib \
  -e AURA_PIPELINE_STRICT=0 \
  -e AURA_SANDBOX=off \
  -e AURA_BIN=/workspace/aura-grok/build/aura \
  ghcr.io/cybrid-systems/dev:v1.0.9 \
  dev /workspace/aura-grok/build/aura /workspace/aura-arena/soft/arena/m0_smoke.aura
```

`scripts/run_soft.sh` is the same invocation. The source path is `$1`.
It forwards `ARENA_HORIZON`, `ARENA_BURN_ROUNDS`, `ARENA_ROUND_DIR`,
and `ARENA_PROPOSE_FILE` into the container.

On seed `20261005`, horizon 48, M0 keeps `rules-light` (mid 2, 35 ticks,
score `35000528`) and drops `rules-heavy` (mid 1, 8 ticks, score `8000423`).
On the tip binary that race is
`WORLD line=fiber_live backend=2 joins=2/2` (`backend=2` is CLI thread
fallback, not serve-async). If the joins do not land, the line is
`host-sequential` and `fiber_live` is not printed.

M1's mid-run swap prints `SWAP` / `HEAL` / `MUTATE tick=8 fric-boost=1`,
then the same heavy/light scores. M2's better fixture (`fric=0`) scores
`48000674` and is KEEP. The heavy fixture is DROP. Fixture burn (horizon
24) KEEPs round 1 (`24000552` vs light `24000502`) and DROPs a tie and a
worse body. Detail in `docs/m1.md` and `docs/m2.md`.

## Engine

| Path | Role |
|------|------|
| `soft/arena/world.aura` | integer ball step, live tick, score, `TAPE` |
| `soft/arena/rules.aura` | heavy vs light, honest race, KEEP/DROP |
| `soft/arena/hot.aura` | `ar:law` hot-strategy seed / swap / heal |
| `soft/arena/propose.aura` | gate → race vs shadow → KEEP / DROP |
| `soft/arena/m0_smoke.aura` | `ARENA_M0_OK` |
| `soft/arena/m1_smoke.aura` | `ARENA_M1_OK` |
| `soft/arena/m2_propose_smoke.aura` | `ARENA_M2_PROPOSE_OK` |
| `soft/arena/burn.aura` | multi-round propose burn |
| `scripts/run_soft.sh` | docker tip binary |
| `scripts/smoke_soft.sh` | M0 evidence |
| `scripts/smoke_m1.sh` | M1 evidence |
| `scripts/smoke_m2.sh` | M2 fixture evidence |
| `scripts/burn.sh` | burn rounds |
| `scripts/propose_minimax.py` | host MiniMax → lambda file |
| `scripts/smoke.sh` | stack entry |

Rules, short form (detail in `docs/m0.md`):

- Box is 64 by 48. Start is `(16, 36)` plus one LCG step from seed `20261005` (`vx=3`, `vy=2`).
- Heavy is `g=4`, bounce `1/3`, friction `2`. Light is `g=1`, bounce `2/3`, friction `1`.
- The ball is out of play when it rests on the floor with zero kinetic energy. That frame is not kept.
- Score is `alive * 1000000 + energy` (integers).
- KEEP requires the greater score. This seed is `longer-survival-stamp`.

## How to burn

```bash
# Offline fixtures (no key, no network):
ARENA_PROPOSE=0 bash scripts/burn.sh
# → ARENA_BURN_OK, MAIN score=24000552, joins=6/6

# Live MiniMax when ~/.config/aura-build/minimax_api_key exists:
bash scripts/burn.sh
# Uses api.minimax.cn only (never api.minimaxi.com)
```

## Soft tip

- Binary: `/workspace/aura-grok/build/aura`
- Image: `ghcr.io/cybrid-systems/dev:v1.0.9`
- Env: `AURA_SANDBOX=off AURA_PIPELINE_STRICT=0 AURA_PATH=/workspace/aura-grok/lib`

Soft is not Restricted mode. `fiber_live` is not printed unless the joins
landed. M0 does not register a hot-strategy.

License: Apache-2.0

---

# aura-arena（中文）

活世界在 Soft：一个盒子、一颗球、两套物理规则（重重力粘滞 vs 轻重力弹跳）。
同一颗种子上赛一轮。活得更久的留下（KEEP），先粘死的丢掉（DROP）。没有
C 视口。只有两条 fiber 都 join 到分数时才印 `fiber_live`（这次是
`backend=2 joins=2/2`，线程回退，不是假装的调度器）。没有 join 就印
`host-sequential`。

M1 中途 `swap!` / `heal!` 换 `ar:law` 规则包，第 8 拍印 `MUTATE`。
M2 由宿主脚本向 MiniMax 要一条 `(lambda () (list g bn bd fric))`，Soft
做门禁，分数不比当前主包高就 DROP 并 heal。密钥不进仓库，也不调用
`api.minimaxi.com`。

```bash
bash scripts/smoke.sh          # M0 + M1 + M2 + 实况或 SKIP + burn
ARENA_PROPOSE=0 bash scripts/burn.sh
```

种子 `20261005`、48 拍：M0 `rules-light` 分数 35000528 KEEP，`rules-heavy`
8000423 DROP。M2 更好包（fric=0）48000674 KEEP，heavy DROP。
镜像 `ghcr.io/cybrid-systems/dev:v1.0.9`，Soft 二进制
`/workspace/aura-grok/build/aura`。仓库里没有密钥。
