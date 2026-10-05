# aura-arena

Aura Arena is a live Soft world. One box, one ball, and two physics rule
packs — heavy sticky gravity against light bounce — are a Soft FlatAST
program. A thin C viewport, later, only blits frames. There is no C binary
in this tree.

Design: [`docs/DESIGN.md`](docs/DESIGN.md).
Milestone: [`docs/m0.md`](docs/m0.md).
Repo: https://github.com/cybrid-systems/aura-arena

This is not a physics engine and not a game. The product is the Aura loop:
two laws race the same seed, the surviving pack is stamped into main, the
loser is dropped.

- **M0** races `rules-heavy` and `rules-light` on one ball. Score is
  time-in-play, with integrated kinetic energy as the tie break.
  `fiber_live` only when both fiber joins return scores (`joins` equals
  spawned, backend > 0). Otherwise `host-sequential`. No C viewport.
  No `hot-strategy`.

## Soft smoke

Image `ghcr.io/cybrid-systems/dev:v1.0.9`, Soft tip binary
`/workspace/aura-grok/build/aura` (host GLIBC is often too old — smoke always
runs Soft inside Docker with `--entrypoint /usr/local/bin/gosu`). Soft runs
natively in that container (no nested docker). Never `build_soft4132`.
Needs `AURA_SANDBOX=off`.

```bash
bash scripts/smoke_soft.sh    # M0 → ARENA_M0_OK
bash scripts/smoke.sh         # the same stack
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

On seed `20261005`, horizon 48, M0 keeps `rules-light` (mid 2, 35 ticks,
score `35000528`) and drops `rules-heavy` (mid 1, 8 ticks, score `8000423`).
On the tip binary that race is
`WORLD line=fiber_live backend=2 joins=2/2` (`backend=2` is CLI thread
fallback, not serve-async). If the joins do not land, the line is
`host-sequential` and `fiber_live` is not printed.

## Engine

| Path | Role |
|------|------|
| `soft/arena/world.aura` | integer ball step, score, `TAPE` |
| `soft/arena/rules.aura` | heavy vs light, honest race, KEEP/DROP |
| `soft/arena/m0_smoke.aura` | `ARENA_M0_OK` |
| `scripts/run_soft.sh` | docker tip binary |
| `scripts/smoke_soft.sh` | M0 evidence |
| `scripts/smoke.sh` | stack entry |

Rules, short form (detail in `docs/m0.md`):

- Box is 64 by 48. Start is `(16, 36)` plus one LCG step from seed `20261005` (`vx=3`, `vy=2`).
- Heavy is `g=4`, bounce `1/3`, friction `2`. Light is `g=1`, bounce `2/3`, friction `1`.
- The ball is out of play when it rests on the floor with zero kinetic energy. That frame is not kept.
- Score is `alive * 1000000 + energy` (integers).
- KEEP requires the greater score. This seed is `longer-survival-stamp`.

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

```bash
bash scripts/smoke_soft.sh
```

种子 `20261005`：`rules-light` 35 拍、分数 35000528 KEEP；`rules-heavy`
8 拍、分数 8000423 DROP。镜像 `ghcr.io/cybrid-systems/dev:v1.0.9`，Soft
二进制 `/workspace/aura-grok/build/aura`。仓库里没有密钥。
