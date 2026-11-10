# Build Plan — Idle Space Company (full game, version 1.0)

This plan builds the complete game in `game_doc.md` (v0.2), not an MVP.
It is written so that cheap Haiku agents do most of the work, one small task card at a time.

---

## 1. How the work is split

| Role | Who | Does |
|---|---|---|
| **Lead** | You, in a main Claude Code session on a stronger model (Sonnet or Opus) | Dispatches cards, reviews at phase gates, tunes the economy, fixes what Haiku fails twice, commits |
| **godot-builder** | Haiku subagent (`.claude/agents/godot-builder.md`) | One GDScript task card |
| **blender-artist** | Haiku subagent (`.claude/agents/blender-artist.md`) | One asset script task card |
| **Human** | You | Accounts, signing keys, real-device tests, store uploads, final art and feel decisions |

### Why this split keeps cost low

- Haiku is good at small tasks with exact inputs and a pass/fail check. It is weak at design, balance, taste, and cross-file debugging. The cards remove those needs.
- Each agent starts with a fresh context and reads three small things: `conventions.md`, its card, and the design sections the card names.
- Game content is JSON data. Adding content is a data edit, not a code change.
- Every code card ends with `tools/verify.ps1`. The Lead does not review code that fails it.
- Cards list their files. Two cards with no shared files and no dependency can run in parallel.
- The stronger model is used only at gates and for the cards marked **Lead**.

### How to dispatch a card

In the main session, say:

```
Use the godot-builder agent for task T011.
```

For parallel work:

```
Run T041v, T041s, and T042v in parallel with blender-artist agents.
```

The agent returns the short report from `conventions.md`. If the status is `blocked`, the Lead resolves it. Do not send the same card to Haiku a third time.

### Codex CLI as a second worker

Codex CLI 0.153.4 is installed and logged in. It reads `AGENTS.md` at the repository root.

**Not working yet:** `~/.codex/config.toml` sets `model = "gpt-6-luna"`, and the ChatGPT login rejects that model (`model_not_found`). Set a model that your plan supports in that file, or pass one to the script with `-Model <name>`. Then run one card as a test. Check in that test that Godot can write its user data inside the sandbox.

```
powershell -ExecutionPolicy Bypass -File tools/codex_task.ps1 T040
```

The script runs one card with `codex exec` in the `workspace-write` sandbox and writes the report to `reports/<id>.md`. The Lead can start it in the background and continue to dispatch Haiku cards.

Use Codex for:

- Cards marked **Lead** that need no account or phone: T001, T018, T040, T060, T113, T120.
- A card that Haiku failed twice.
- A second track that shares no files with the Haiku track. Example: Codex does the art cards while Haiku does the core logic cards.
- A second opinion before a gate: `codex exec review`.

Rules: never give the same card, or two cards with a shared file, to two workers at the same time. Codex does not commit.

### Context budget

No tool can set a hard 100k-token limit on a subagent. The plan keeps each task small by design:

- One card is one file of about 1 KB. No agent reads this plan.
- Each agent has only file, search, and shell tools. It does not load the MCP tool lists.
- Cards touch one to four files. Large cards from the first plan are split (T013a–c, T020a–b, T071a–c, one card per model, one card per language).
- `verify.ps1` prints only failures and a summary.
- No `.gd` file may pass 300 lines, so no single read is large.
- The full rule list is in `conventions.md`, section "Context budget".

If a report says `blocked` because the task grew too large, split that card into two files before you dispatch it again.

### After each card

1. Read the report's NOTES line.
2. Run `tools/verify.ps1` yourself if the report looks doubtful.
3. Commit with the task id in the message.
4. Tick the card in the task index (section 4).

---

## 2. Architecture

```
                 +-----------------------------+
   JSON data --> |  core/ (pure logic, tested) |  economy, formatter, offline, prestige, contracts
                 +--------------+--------------+
                                |
                 +--------------v--------------+
                 | GameState (autoload)        |  the only owner of mutable state
                 +---+----------+----------+---+
                     |          |          |
              EventBus signals  |     SaveService / TimeService
                     |          |
        +------------v--+   +---v-----------------+
        | scenes/ui     |   | scenes/world (3D)   |
        +---------------+   +---------------------+
        AdService / Analytics / AudioService: interfaces with mock providers
```

Key decisions:

- **Tick model:** `GameState.tick(delta)` advances every division's cycle while the game is open. Offline earnings do not use `tick`; they use the single formula in design §7.
- **3D scene + 2D UI:** one `Node3D` world with a fixed camera, and a `CanvasLayer` for all UI.
- **Renderer:** Compatibility (OpenGL ES 3), for low-end Android phones.
- **Plugins are isolated:** only `AdService`, `Analytics`, and the notification service may call plugin code. The rest of the game sees the interface.

---

## 3. Phases and gates

| Phase | Content | Cards | Gate (Lead + Human) |
|---|---|---|---|
| 0 | Setup | T001–T004 | `verify.ps1` passes on an empty project |
| 1 | Core logic, no UI | T010–T018 | Simulator meets the pacing targets in design §4 |
| 2 | Playable UI with grey boxes | T020–T031 | Human plays stage 1 → 3 on desktop without confusion |
| 3 | Art and 3D world | T040–T062 | All nine stages look consistent; 60 fps on desktop |
| 4 | Meta systems | T070–T078 | Full first life and one prestige played by fast-forward |
| 5 | Audio | T080–T082 | Human sign-off on sound |
| 6 | Ads, consent, analytics | T090–T096 | Test ads show and pay rewards on a real phone |
| 7 | Localisation | T100–T102 | No clipped text in any language |
| 8 | Android release | T110–T117 | Internal-test build installed from Play |
| 9 | Launch and growth | T120–T126 | Metrics gate in design §14 |

Do not start a phase before the previous gate passes. Phase 3 art cards (T041v–T052) are the exception: they depend only on T040 and can run beside phases 1 and 2.

---

## 4. Task index

Each card is one file: `tasks/<id>.md`. An agent reads only its own card file.
Tick the **Done** box here when the Lead has committed the card.


### Phase 0 — Setup

| Done | Id | Title | Agent | Depends |
|---|---|---|---|---|
| [x] | [T001](tasks/T001.md) | Project skeleton | Lead | none |
| [x] | [T002](tasks/T002.md) | Test runner | godot-builder | T001 |
| [x] | [T003](tasks/T003.md) | Verify script | godot-builder | T002 |
| [x] | [T004](tasks/T004.md) | Autoload stubs and EventBus | godot-builder | T003 |

### Phase 1 — Core logic

| Done | Id | Title | Agent | Depends |
|---|---|---|---|---|
| [x] | [T010](tasks/T010.md) | Division data | godot-builder | T004 |
| [x] | [T011](tasks/T011.md) | Economy formulas | godot-builder | T010 |
| [x] | [T012](tasks/T012.md) | Number and height formatter | godot-builder | T002 |
| [x] | [T013a](tasks/T013a.md) | GameState: state, buying, unlocking | godot-builder | T011 |
| [x] | [T013b](tasks/T013b.md) | Launch cycle: pump, launch, tick | godot-builder | T013a |
| [x] | [T013c](tasks/T013c.md) | Managers, tap speed-up, income rate | godot-builder | T013b |
| [x] | [T014](tasks/T014.md) | Research | godot-builder | T013c |
| [x] | [T015](tasks/T015.md) | Save and load | godot-builder | T013c |
| [x] | [T016](tasks/T016.md) | Offline earnings | godot-builder | T015 |
| [x] | [T017](tasks/T017.md) | Economy simulator | godot-builder | T014, T016 |
| [x] | [T018](tasks/T018.md) | Tune the economy | Lead | T017 |

### Phase 2 — Playable UI (grey boxes)

| Done | Id | Title | Agent | Depends |
|---|---|---|---|---|
| [x] | [T020a](tasks/T020a.md) | Theme and font | godot-builder | T004 |
| [x] | [T020b](tasks/T020b.md) | UI kit controls | godot-builder | T020a |
| [x] | [T021](tasks/T021.md) | Main layout | godot-builder | T020b |
| [x] | [T022](tasks/T022.md) | HUD | godot-builder | T021, T012 |
| [x] | [T023](tasks/T023.md) | Pump and launch controls | godot-builder | T022, T013c |
| [x] | [T024](tasks/T024.md) | Divisions tab | godot-builder | T023 |
| [x] | [T025](tasks/T025.md) | Managers tab | godot-builder | T024 |
| [x] | [T026](tasks/T026.md) | Research tab | godot-builder | T024, T014 |
| [x] | [T027](tasks/T027.md) | Popup system and offline popup | godot-builder | T022, T016 |
| [x] | [T028](tasks/T028.md) | Stage-unlock popup and stage switching | godot-builder | T027 |
| [x] | [T029](tasks/T029.md) | Settings and More tab | godot-builder | T027 |
| [x] | [T030](tasks/T030.md) | Debug panel | godot-builder | T027 |
| [ ] | [T031](tasks/T031.md) | Screenshot tool | godot-builder | T030 |

**Gate 2:** Human plays from a new save to stage 3 on desktop. Lead reviews screenshots.

### Phase 3 — Art and 3D world

| Done | Id | Title | Agent | Depends |
|---|---|---|---|---|
| [x] | [T040](tasks/T040.md) | Blender style library | Lead | none |
| [x] | [T041v](tasks/T041v.md) | Vehicle: bottles | blender-artist | T040 |
| [x] | [T041s](tasks/T041s.md) | Launch site: bottles | blender-artist | T040 |
| [x] | [T042v](tasks/T042v.md) | Vehicle: model_rockets | blender-artist | T040 |
| [x] | [T042s](tasks/T042s.md) | Launch site: model_rockets | blender-artist | T040 |
| [x] | [T043v](tasks/T043v.md) | Vehicle: sounding | blender-artist | T040 |
| [x] | [T043s](tasks/T043s.md) | Launch site: sounding | blender-artist | T040 |
| [x] | [T044v](tasks/T044v.md) | Vehicle: orbital | blender-artist | T040 |
| [x] | [T044s](tasks/T044s.md) | Launch site: orbital | blender-artist | T040 |
| [x] | [T045v](tasks/T045v.md) | Vehicle: station | blender-artist | T040 |
| [x] | [T045s](tasks/T045s.md) | Launch site: station | blender-artist | T040 |
| [x] | [T046v](tasks/T046v.md) | Vehicle: moon | blender-artist | T040 |
| [x] | [T046s](tasks/T046s.md) | Launch site: moon | blender-artist | T040 |
| [x] | [T047v](tasks/T047v.md) | Vehicle: solar | blender-artist | T040 |
| [x] | [T047s](tasks/T047s.md) | Launch site: solar | blender-artist | T040 |
| [x] | [T048v](tasks/T048v.md) | Vehicle: galaxy | blender-artist | T040 |
| [x] | [T048s](tasks/T048s.md) | Launch site: galaxy | blender-artist | T040 |
| [x] | [T049v](tasks/T049v.md) | Vehicle: black_hole | blender-artist | T040 |
| [x] | [T049s](tasks/T049s.md) | Launch site: black_hole | blender-artist | T040 |
| [x] | [T050](tasks/T050.md) | Kid character | blender-artist | T040 |
| [x] | [T051](tasks/T051.md) | Memory bottle skins | blender-artist | T041v |
| [x] | [T052](tasks/T052.md) | Icon and store art sources | blender-artist | T044v |

**Art review (Lead):** open all previews together. Use the Blender MCP `look` tool if needed. Send back any asset that is off-style, with a one-line correction on the card.
| [x] | [T053](tasks/T053.md) | Art polish pass | Lead | T055 |
| [x] | [T055](tasks/T055.md) | World scene and camera | godot-builder | T021, T041v |
| [x] | [T056](tasks/T056.md) | Sky gradient per stage | godot-builder | T055 |
| [x] | [T057](tasks/T057.md) | Flight animation | godot-builder | T055 |
| [x] | [T058](tasks/T058.md) | Particle trails | godot-builder | T057 |
| [x] | [T059](tasks/T059.md) | Kid and pump animation | godot-builder | T055, T050 |
| [x] | [T060](tasks/T060.md) | Black hole | Lead | T056 |
| [x] | [T061](tasks/T061.md) | Prestige cinematic | godot-builder | T060, T059 |
| [x] | [T062](tasks/T062.md) | Juice pass | godot-builder | T057, T023 |

**Gate 3:** Lead reviews screenshots of all nine stages. Human checks frame rate.

### Phase 4 — Meta systems

| Done | Id | Title | Agent | Depends |
|---|---|---|---|---|
| [x] | [T070](tasks/T070.md) | Prestige logic | godot-builder | T015 |
| [x] | [T071a](tasks/T071a.md) | Echo Shop: data and buying | godot-builder | T070 |
| [x] | [T071b](tasks/T071b.md) | Echo Shop effects, part 1 | godot-builder | T071a |
| [x] | [T071c](tasks/T071c.md) | Echo Shop effects, part 2 | godot-builder | T071b |
| [x] | [T072](tasks/T072.md) | Echoes tab and prestige screen | godot-builder | T071c, T061 |
| [x] | [T073](tasks/T073.md) | Lifetime milestones | godot-builder | T070 |
| [x] | [T074](tasks/T074.md) | Boosts | godot-builder | T027 |
| [x] | [T075](tasks/T075.md) | Daily reward | godot-builder | T027 |
| [x] | [T076](tasks/T076.md) | Contracts | godot-builder | T075 |
| [x] | [T077](tasks/T077.md) | Stats, lives, and cosmetics | godot-builder | T071c, T051 |
| [x] | [T078](tasks/T078.md) | First-time guidance | godot-builder | T024 |

**Gate 4:** Lead repeats T018 with the Echo Shop. Human plays a full life with the debug time speed.

### Phase 5 — Audio

| Done | Id | Title | Agent | Depends |
|---|---|---|---|---|
| [x] | [T080](tasks/T080.md) | Audio service | godot-builder | T029 |
| [ ] | [T081](tasks/T081.md) | Sound and music assets | Human (with Lead help) | T080 |
| [ ] | [T082](tasks/T082.md) | Hook sounds | godot-builder | T081 |

### Phase 6 — Ads, consent, analytics

| Done | Id | Title | Agent | Depends |
|---|---|---|---|---|
| [x] | [T090](tasks/T090.md) | AdService interface and mock | godot-builder | T074 |
| [ ] | [T091](tasks/T091.md) | Wire every placement | godot-builder | T090, T072 |
| [ ] | [T092](tasks/T092.md) | AdMob accounts | Human | — |
| [ ] | [T093](tasks/T093.md) | AdMob plugin provider | Lead | T091, T092 |
| [ ] | [T094](tasks/T094.md) | Consent (UMP) | Lead | T093 |
| [x] | [T095](tasks/T095.md) | Analytics interface and events | godot-builder | T090 |
| [ ] | [T096](tasks/T096.md) | Analytics provider | Lead + Human | T095 |

### Phase 7 — Localisation

| Done | Id | Title | Agent | Depends |
|---|---|---|---|---|
| [ ] | [T100](tasks/T100.md) | String audit | godot-builder | phase 4 gate |
| [ ] | [T101-es](tasks/T101-es.md) | Translation: Spanish | godot-builder | T100 |
| [ ] | [T101-pt_BR](tasks/T101-pt_BR.md) | Translation: Brazilian Portuguese | godot-builder | T100 |
| [ ] | [T101-fr](tasks/T101-fr.md) | Translation: French | godot-builder | T100 |
| [ ] | [T101-de](tasks/T101-de.md) | Translation: German | godot-builder | T100 |
| [ ] | [T101-id](tasks/T101-id.md) | Translation: Indonesian | godot-builder | T100 |
| [ ] | [T101-tr](tasks/T101-tr.md) | Translation: Turkish | godot-builder | T100 |
| [ ] | [T101-ru](tasks/T101-ru.md) | Translation: Russian | godot-builder | T100 |
| [ ] | [T102](tasks/T102.md) | Layout check per language | Lead | all T101-*, T031 |

### Phase 8 — Android release

| Done | Id | Title | Agent | Depends |
|---|---|---|---|---|
| [ ] | [T110](tasks/T110.md) | Export preset | Lead + Human | phase 6 gate |
| [ ] | [T111](tasks/T111.md) | Device robustness | godot-builder | T110 |
| [ ] | [T112](tasks/T112.md) | Real-device test | Human | — |
| [ ] | [T113](tasks/T113.md) | Performance fixes | Lead | T112 |
| [ ] | [T114](tasks/T114.md) | Privacy policy and app-ads.txt | godot-builder (drafts) + Human (publishes) | — |
| [ ] | [T115](tasks/T115.md) | Store listing text | godot-builder | all T101-* |
| [ ] | [T116](tasks/T116.md) | Screenshots and video | Lead + Human | T031 |
| [ ] | [T117](tasks/T117.md) | Play Console release | Human | — |

### Phase 9 — Launch and growth

| Done | Id | Title | Agent | Depends |
|---|---|---|---|---|
| [ ] | [T120](tasks/T120.md) | Web build for itch.io | Lead | — |
| [ ] | [T121](tasks/T121.md) | Community posts and short videos | Human (Lead drafts text) | — |
| [ ] | [T122](tasks/T122.md) | Metrics gate (two weeks after release) | Lead + Human | — |
| [ ] | [T123](tasks/T123.md) | Remove Ads IAP | Lead | — |
| [ ] | [T124](tasks/T124.md) | Local notifications | Lead | — |
| [ ] | [T125](tasks/T125.md) | In-app review prompt | Lead | — |
| [ ] | [T126](tasks/T126.md) | Content update | Lead plans, Haiku builds | — |

---

## 5. Parallel work map

```
T001 → T002 → T003 → T004 ─┬─ T010 → T011 → T013a → T013b → T013c ─┬─ T014 ─┐
                           │                      ├─ T015 → T016 ─┴→ T017 → T018
                           ├─ T012                │
                           └─ T020a → T020b → T021 → T022 → T023 → T024 → T025, T026 (parallel)
                                                   └→ T027 → T028, T029, T030 (parallel) → T031

T040 → T041v/s … T049v/s (18 cards in parallel) → T050, T051, T052     (can start on day 1)
```

Cards that edit `game_state.gd` (T013a–c, T014, T015, T016, T070, T071a–c, T073–T077) must run **one at a time**.

---

## 6. Known risks

| Risk | Mitigation |
|---|---|
| Haiku writes a broken `.tscn` | Convention: nodes are built in code; `.tscn` stays minimal |
| Haiku "fixes" a failing test by weakening it | Rule in `conventions.md`; Lead checks test diffs at each gate |
| Art looks inconsistent between agents | One style library (T040) by the Lead; fixed palette; art review step |
| Economy feels wrong although tests pass | Simulator (T017), Lead tuning (T018) twice, Human play at gates 2 and 4 |
| Community AdMob plugin breaks on a Godot update | Godot is pinned to 4.5.1; plugin sits behind `AdProvider` |
| Game is finished but gets no installs | Phase 9 is part of the plan; web build, localisation, and store page are scheduled cards |
| Scope is large for one person | Phases 1–4 give a complete offline game; later phases are separable |

---

## 7. What only you can do

- AdMob and Play Console setup (T092, T117)
- Release keystore (T110)
- Real-phone testing (T112)
- Sound choices and final art approval (T081, T052, T060)
- Publishing the privacy page (T114)
- Community posts under your own name (T121)
