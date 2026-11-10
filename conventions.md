# Conventions

Read this file before every task. It is short on purpose.

## Tools

| Tool | Path / command |
|---|---|
| Godot 4.5.1 (console build) | `D:\Godot\Godot_v4.5.1-stable_win64_console.exe` — called `GODOT` below |
| Blender 5.2 LTS | `blender` (on PATH) |
| Shell | PowerShell |

Do not upgrade either tool. Do not use Godot 4.4.

## Repository layout

```
game_doc.md            Design (what the game is). Read only the sections your task names.
build_plan.md          Phases and task index. For the Lead only.
tasks/                 One task card per file: tasks/<id>.md.
reports/               Codex task reports (one file per task).
conventions.md         This file.
CREDITS.md             Every third-party asset, with licence and source URL.
game/                  The Godot project (project.godot is here).
  autoload/            Singletons: EventBus, GameState, SaveService, TimeService, AdService, Analytics, AudioService
  core/                Pure logic with no node access: economy.gd, formatter.gd, offline.gd, prestige.gd ...
  data/                JSON content: divisions.json, research.json, echo_shop.json, milestones.json, contracts.json
  locale/              strings.csv (translations)
  scenes/world/        3D launch scene
  scenes/ui/           HUD, panels, popups
  assets/models/       .glb files exported from Blender
  assets/audio/  assets/fonts/  assets/ui/
  tests/               run_tests.gd and test_*.gd
  tools/               sim_economy.gd, screenshot.gd
art/
  scripts/             Blender Python scripts. One script builds one asset.
  previews/            PNG preview renders (for review by the Lead)
tools/verify.ps1       Runs import + tests + smoke run. Must pass before a task is done.
```

## GDScript rules

1. Use static typing everywhere: `var level: int = 0`, `func cost(level: int) -> float:`.
2. `snake_case` for files, functions, and variables. `PascalCase` for `class_name`. `UPPER_CASE` for constants.
3. Files in `game/core/` are pure logic. They must not touch nodes, the scene tree, autoloads, or the clock. Pass values in as arguments. This makes them testable.
4. All mutable game state lives in `GameState`. UI reads state and calls `GameState` methods. UI never changes state directly.
5. Components talk through `EventBus` signals. Do not use `get_node("../../..")` paths across scenes.
6. No magic numbers for balance. Read balance values from `game/data/*.json`.
7. Money and height are `float` (64-bit). Do not store them in `Vector2`, `Color`, or shader parameters, because those are 32-bit.
8. Wrap every player-visible English text in `tr()`, for example `tr("Launch")`. Do not create or edit `game/locale/strings.csv`; task T100 builds it from the `tr()` calls. For names that come from JSON data, show the English field (for example `stage_name`) through `tr()`.
9. Use the current time only through `TimeService.now_unix()`.
10. Do not add addons or plugins unless the task card says so.

## Scene rules

- Hand-written `.tscn` files break easily. Keep each `.tscn` minimal: the root node and its script.
- Build child nodes in code inside `_ready()`.
- Base resolution is 1080×1920, portrait. Stretch mode `canvas_items`, aspect `expand`.
- Minimum touch target: 96×96 px.
- Use anchors and containers. Do not use fixed pixel positions for layout.

## Blender rules

1. Every asset is built by a script: `art/scripts/<asset_id>.py`. Run it with `blender --background --python art/scripts/<asset_id>.py`.
2. Import helpers from `art/scripts/lib_style.py` (palette, primitives, export, preview). Do not define colours in asset scripts.
3. Low-poly, flat colours, no textures, no UVs, no modifiers left unapplied.
4. Units are metres. +Z is up in Blender. The vehicle's nose points +Z. The origin is at the bottom centre of the asset.
5. One material per palette colour, named `mat_<colour_name>`. Colour goes on the Principled BSDF base colour input. Find the node by `type == "BSDF_PRINCIPLED"`, not by name.
6. Stay inside the triangle budget on the task card. Print the triangle count at the end of the script.
7. Export to `game/assets/models/<asset_id>.glb` and render a preview to `art/previews/<asset_id>.png`.

## Tests and verification

- Every file in `game/core/` has a test file `game/tests/test_<name>.gd`.
- A test file has `extends RefCounted`. Test functions start with `test_`.
- Assertions are static: `TestRunner.assert_eq(a, b, msg)`, `TestRunner.assert_true(v, msg)`, `TestRunner.assert_near(a, b, rel_tol, msg)`. Copy the pattern from `game/tests/test_sanity.gd`.
- Before you report a task as done, run:

```
powershell -ExecutionPolicy Bypass -File tools/verify.ps1
```

- The task is done only when this command exits with code 0. Paste the last 15 lines of its output in your report.
- Do not delete, skip, or weaken a test to make it pass. If a test looks wrong, stop and report it.

## Context budget (keep each task below 100k tokens)

1. Never read `build_plan.md`. Never read all of `game_doc.md`.
2. To read a design section, use Grep on its heading with 40 lines of context after it (for example pattern `^## 7\.` with `-A 40`).
3. Read a file only if it is under **Files** or **Reads** on your card.
4. For a file above 200 lines, use Grep to find the function, then Read with `offset` and `limit`. Do not read the whole file.
5. Do not read a file again after you edit it.
6. Never open `.glb`, `.import`, `.godot/`, `.png` (except one Blender preview), or `user://` files.
7. Run `verify.ps1` at most three times in one task. It prints only failures and a summary. Do not run Godot with `--verbose`.
8. No `.gd` file may grow above 300 lines. If your change would pass that limit, stop and report so that the Lead can split the file.
9. `game_state.gd` holds state and thin methods only. Put rules and maths in a `game/core/` file.
10. If you are far into a task and it is still growing, stop and report `blocked` with what is done. A second agent continues from your report.

## Task rules for agents

1. Do exactly one task card. Your card is the file `tasks/<id>.md` (for example `tasks/T011.md`).
2. Read only: this file, your card, the files the card lists, and the design sections the card names.
3. Create or change only the files listed under **Files** on the card. If you need another file changed, stop and report.
4. Do not redesign. If the card conflicts with the design or the code, stop and report the conflict.
5. If you fail the same step twice, stop and report. Do not try a third approach.
6. Do not commit. The Lead commits after review.
7. End with a report in this format, 12 lines or fewer:

```
TASK: T0xx
STATUS: done | blocked
FILES: <changed files>
VERIFY: <pass/fail + last lines>
NOTES: <conflicts, guesses you made, things the Lead must check>
```
