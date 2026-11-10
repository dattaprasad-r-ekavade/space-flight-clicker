# Balance Log

The balance numbers live in `game/data/divisions.json` and `game/data/research.json`.
Do not edit those two files by hand. Change the tables in `tools/balance.py` and run it.

## Pass 1 (T018, first run)

Tool: `python tools/balance.py`. Simulator: `game/tools/sim_economy.gd`.

Inputs:

| Stage | base_cost | payback seconds at level 1 |
|---|---|---|
| bottles | 5 | 7.5 |
| model_rockets | 500 | 60 |
| sounding | 3.0e4 | 300 |
| orbital | 2.2e6 | 3,000 |
| station | 3.2e7 | 15,000 |
| moon | 3.0e8 | 40,000 |
| solar | 9.0e9 | 60,000 |
| galaxy | 3.0e11 | 80,000 |
| black_hole | 1.5e13 | 100,000 |

`base_rev = base_cost * base_flight_s / payback`. Research costs are multiples of `base_cost` (see the tool).

Results (time from install):

| Event | Target | casual | active |
|---|---|---|---|
| First manager | 2 min | 2 min | 2 min |
| Stage 2 | 4 min | 3 min | 3 min |
| Stage 3 | 15 min | 6 min | 6 min |
| Stage 4 | 45 min | 2 h 40 min (second session) | 18 min |
| Stage 6 | End of day 1 | 5 h 20 min | 2 h 40 min |
| Stage 9 | Day 2–3 | 1 d 13 h | 1 d 7 h |
| Black hole | Day 3 | 3 d 3 h | 2 d 11 h |
| Echoes gained | — | 411 | 476 |

Later lives (casual, with an assumed revenue multiplier):

| Profile | Assumed multiplier | Target | Result |
|---|---|---|---|
| life2_casual | ×3 | about 1 day | 1 d 5 h |
| life5_casual | ×20 | about 3 hours | 10 h 40 min |

## What the first attempt taught

- The starting values in the design document reached the black hole in under 11 hours. They were far too fast.
- The time for a stage depends mainly on the payback time of that stage's own levels, not on its cost. Raising cost and revenue together made the game faster.

## Open items for pass 2 (after phase 4)

- Stage 3 is early (6 min against 15 min). Acceptable: early speed helps retention.
- Stages 5 and 6 unlock in the same session for the casual profile. Raise the moon payback or cost.
- Life 5 is too slow (10 h 40 min against 3 h). The Echo Shop is not simulated yet. Simulate `head_start`, `fast_hands`, and the real Echo bonus before changing numbers.
- The multipliers ×3 and ×20 are guesses. With 411 unspent Echoes at +2 % each, life 2 has ×9.2.
- The simulator's buy policy is simple. A human play-test at gate 2 must confirm the first 15 minutes.
