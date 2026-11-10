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
5a. Files in `game/autoload/` and `game/core/` must never name a UI class (`PopupHost`, any `Popup…`, any tab) or a world class. This breaks compilation at start. To show a short message from logic, use `gs._emit_bus("toast_requested", [text])`.
6. No magic numbers for balance. Read balance values from `game/data/*.json`.
7. Money and height are `float` (64-bit). Do not store them in `Vector2`, `Color`, or shader parameters, because those are 32-bit.
8. Wrap every player-visible English text in `tr()`, for example `tr("Launch")`. Do not create or edit `game/locale/strings.csv`; task T100 builds it from the `tr()` calls. For names that come from JSON data, show the English field (for example `stage_name`) through `tr()`.
9. Use the current time only through `TimeService.now_unix()`.
10. Do not add addons or plugins unless the task card says so.

## Existing classes (use these; do not write a second copy)

| Class | File | Use |
|---|---|---|
| `DataLoader` | `game/core/data_loader.gd` | `DataLoader.divisions()` returns the nine division Dictionaries; `load_json(path)` |
| `Economy` | `game/core/economy.gd` | Static formulas: `apogee`, `level_cost`, `bulk_cost`, `max_affordable`, `level_mult`, `flight_time`, `launch_revenue`, `manager_cost` |
| `NumFormat` | `game/core/formatter.gd` | `NumFormat.money(v)`, `NumFormat.height(metres)`, `NumFormat.duration(seconds)` |
| `TestRunner` | `game/tests/run_tests.gd` | Test assertions |
| `LaunchOps`, `OfflineOps` | `game/core/*_ops.gd` | The pattern for state-changing features |
| `Research` | `game/core/research.gd` | `Research.nodes()`, `find(id)`, multipliers |
| `UiTheme` | `game/scenes/ui/ui_theme.gd` | `UiTheme.build()` and colour / size constants (`BG`, `PANEL`, `ACCENT`, `TEXT`, `TEXT_DIM`, `FONT_BODY`, `PAD`, `TOUCH`, …) |
| `BigButton`, `PanelCard`, `FillBar`, `TabStrip` | `game/scenes/ui/kit/` | UI kit. Use these in every UI file; do not style raw controls by hand |

UI files reach the game through the autoloads `GameState` and `EventBus` (for example `GameState.buy_levels(id, 1)`, `EventBus.revenue_changed.connect(...)`). To see the GameState methods, Grep `^func [a-z]` in `game/autoload/game_state.gd`. To see the signals, read `game/autoload/event_bus.gd`.

To learn a function signature, Grep `^static func` in the file. Do not read the whole file.

## How UI files are attached

`game/scenes/main.gd` adds a UI part automatically when its script file exists. The paths are in the constants `HUD_PARTS`, `OVERLAY_PARTS`, and `TAB_PARTS` at the top of `main.gd`. A UI card only creates its own file. Do not edit `main.gd`.

- Each part is a script that `extends Control`, has no `.tscn`, and builds its children in `_ready()`.
- `main.gd` gives the part a full-rect layout in its area. HUD parts must set `mouse_filter = MOUSE_FILTER_IGNORE` on themselves and on containers that only do layout, so that taps reach the controls below.
- Popups are not parts. A popup is a Control class that the code shows with the popup host.

The 3D world works the same way. `game/scenes/world/world.gd` (class `World`) adds a world part when its script exists; the paths are in its `WORLD_PARTS` constant. A world part `extends Node` or `Node3D`, finds the world with `get_parent() as World`, and uses `World.vehicle()`, `World.camera()`, `World.current_stage()`. Do not edit `world.gd`. The `Flight` part (`game/scenes/world/flight.gd`) has the signals `lifted_off(id)` and `landed(id, revenue, apogee)`.

## Parallel work

Other agents may work in this tree at the same time. If `verify.ps1` fails only because of an error in a file that is NOT on your card, do not edit that file. Wait 30 seconds and run verify again (two retries at most). If it still fails, report it under NOTES and finish.

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
- Autoload names (`GameState`, `EventBus`, …) are NOT available inside test files. To test an autoload script, make an instance: `var gs = load("res://autoload/game_state.gd").new()`, call `gs.new_game()`, and call `gs.free()` at the end. Copy the pattern from `game/tests/test_game_state_buy.gd`.
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
9. `game_state.gd` holds state fields and one-line methods only. For a feature that changes state, write `game/core/<feature>_ops.gd` with static functions that take the GameState node `gs` as the first argument (untyped). Copy the pattern from `game/core/launch_ops.gd`. Then add one-line methods to `game_state.gd` that call them. Pure maths with no state goes in its own `game/core/` file. A card may add at most 15 lines to `game_state.gd`.
   - Add income only with `gs.add_revenue(amount)`. Read values with `gs.revenue_per_launch(id)`, `gs.flight_time(id)`, `gs.income_per_second()`.
   - New saved fields must also be added to `game/core/state_codec.gd` (add it to your Files if the card does not list it) and reset in `new_game()`.
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
