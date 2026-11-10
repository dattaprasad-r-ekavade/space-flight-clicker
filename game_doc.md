# Idle Space Company — Game Design Document (v0.2)

Working title. Check Google Play for name conflicts before release.
v0.1 is kept in `game_doc_v0.1.md`. This version replaces it.

Related files:
- `conventions.md` — technical rules for everyone who writes code or art.
- `build_plan.md` — phases, task cards, and how the agents are used.

---

## 1. High Concept

You are the founder of a space company. You start as a kid on a hill who pumps air into message bottles and launches them. You grow through nine stages: bottles → model rockets → sounding rockets → orbital rockets → space stations → Moon base → solar system network → galaxy gate → black hole. You fly into the black hole and wake up as the kid on the hill again, carrying permanent **Echoes** of your previous lives.

| Item | Value |
|---|---|
| Genre | Idle / incremental |
| Platform | Android, portrait, phones first |
| Engine | Godot 4.5.1, GDScript, Compatibility renderer |
| Art tool | Blender 5.2 LTS, low-poly 3D exported as `.glb` |
| Monetization | Rewarded ads (primary), rare interstitials, "Remove Ads" IAP after launch |
| Session | 1–5 minutes active, strong offline progress |
| Audience | **13+** (not 8+; see section 12) |
| Default company name | "Bottle Rocket Co." (player can rename; do not use "SpaceZ") |

### Business target

- First target: **$100 total ad revenue**, which is also the AdMob payout threshold.
- Rough need: 2,000–5,000 installs from low-eCPM countries, or 300–500 from the US/EU. These are estimates, not measured data.
- The developer's earlier apps earned $3 in 3 months. That result points to an install problem, not only a product problem. So install growth (section 13) is part of the game's scope, not an afterthought.

---

## 2. Core Loop

1. **Pump** — Tap to fill the Fuel bar of the selected division.
2. **Launch** — When the bar is full, tap Launch. The vehicle flies, reaches its apogee, and pays Revenue.
3. **Spend** — Buy division levels, managers, and research with Revenue.
4. **Progress** — A division at level 25 reaches the height of the next stage and unlocks the next division.
5. **Automate** — Managers pump and launch for you. Divisions with managers also earn while the game is closed.
6. **Prestige** — Take division 9 to level 25, enter the black hole, and start a new life with Echoes.

All unlocked divisions keep running. The 3D scene shows the selected division. The player can switch the selected division at any time.

---

## 3. Currencies

| Currency | Reset on prestige | Source | Use |
|---|---|---|---|
| **Fuel** | n/a | Taps, managers | Fills the bar for one launch. One bar per division. |
| **Revenue** | Yes | Launches, offline earnings | Division levels, managers, research |
| **Record Height** | Yes | Highest apogee in this life | Unlocks stages. Shown large on the HUD. |
| **Lifetime Height** | **No** | Sum of all apogees in all lives | Permanent milestones (section 8) |
| **Echoes** | **No** | Black hole prestige | Passive revenue bonus and the Echo Shop |

This table removes the conflict in v0.1: Record Height resets, Lifetime Height does not.

Number format: `1,234` up to 999,999, then `1.23M`, `B`, `T`, then `aa`, `ab`, `ac` …
Height format: `m` below 1,000 m; `km` below 1e10 m; `AU` below 9.46e14 m; `ly` above.

---

## 4. Divisions (Stages)

Each stage adds one division. `h_start` is the apogee at level 1. `h_ceiling` is the apogee at level 25 and above, and it equals the next stage's `h_start`.

| # | id | Stage name | Vehicle | h_start (m) | h_ceiling (m) | Fantasy |
|---|---|---|---|---|---|---|
| 1 | bottles | Kid on the Hill | Message bottle | 1 | 100 | Childhood wonder |
| 2 | model_rockets | Backyard Rockets | Model rocket | 100 | 1e4 | First engineering |
| 3 | sounding | Aerospace Startup | Sounding rocket | 1e4 | 1e5 | Edge of space (100 km) |
| 4 | orbital | Agency Era | Orbital rocket | 1e5 | 4e5 | Orbit (400 km) |
| 5 | station | Station Builder | Station module | 4e5 | 3.844e8 | Permanent presence |
| 6 | moon | Moon Base | Lunar lander | 3.844e8 | 5.5e10 | Another world |
| 7 | solar | Solar System Network | Deep-space probe | 5.5e10 | 9.46e15 | Multi-planet (Mars → 1 ly) |
| 8 | galaxy | Galaxy Gate | FTL ship | 9.46e15 | 9.46e18 | Interstellar (1 → 1,000 ly) |
| 9 | black_hole | Event Horizon | Final craft | 9.46e18 | 2.46e20 | Galactic centre (26,000 ly) |

### Formulas

```
L_UNLOCK = 25
apogee(d, level)     = h_start * (h_ceiling / h_start) ^ ((min(level, 25) - 1) / 24)    # level >= 1
level_cost(d, level) = base_cost * growth ^ level          # cost to go from `level` to `level + 1`; level 0 -> 1 of division 1 is free
launch_revenue(d)    = base_rev * level * level_mult(level) * research_mult(d) * global_mult
level_mult(level)    = 2 ^ (count of thresholds in [10, 25, 50, 100, 150, 200, 300, 400] that are <= level)
flight_time(d)       = base_flight_s * 0.5 ^ (count of [25, 100, 200, 400] <= level) * flight_research_mult * echo_flight_mult
global_mult          = echo_mult * milestone_mult * boost_mult * global_research_mult
echo_mult            = 1 + echoes_owned * echo_power        # echo_power = 0.02 base
manager_cost(d)      = base_cost * 200
```

Division `d + 1` unlocks when division `d` reaches level 25. The player must then buy level 1 of the new division at `base_cost`.

### Starting balance values

These are **starting values**. Task T017 builds a simulator and task T018 tunes them. Final values live in `game/data/divisions.json`, which is the source of truth after T018.

| # | base_cost | growth | base_rev | base_flight_s | pump_taps |
|---|---|---|---|---|---|
| 1 | 5 | 1.08 | 1 | 1.5 | 5 |
| 2 | 100 | 1.14 | 40 | 3 | 8 |
| 3 | 2,000 | 1.13 | 500 | 6 | 10 |
| 4 | 40,000 | 1.12 | 6,000 | 10 | 12 |
| 5 | 800,000 | 1.12 | 80,000 | 20 | 15 |
| 6 | 2e7 | 1.11 | 1.2e6 | 45 | 15 |
| 7 | 6e8 | 1.10 | 2e7 | 120 | 20 |
| 8 | 2e10 | 1.09 | 4e8 | 300 | 20 |
| 9 | 1e12 | 1.08 | 1e10 | 600 | 25 |

### Pacing targets (first life, normal player)

| Event | Target time from install |
|---|---|
| First launch | 10 seconds |
| First manager | 2 minutes |
| Stage 2 unlocked | 4 minutes |
| Stage 3 unlocked | 15 minutes |
| Stage 4 unlocked | 45 minutes |
| Stage 6 unlocked | End of day 1 |
| Stage 9 unlocked | Day 2–3 |
| First black hole | Day 3 |
| Second life to black hole | About 1 day |
| Fifth life to black hole | About 3 hours |

Something new must unlock in every session for the first three days. This is the main retention tool before the first prestige.

---

## 5. Pump, Launch, and Managers

- A division without a manager needs `pump_taps` taps, then one Launch tap.
- Holding the pump button counts as 6 taps each second.
- A **manager** (one per division, bought once per life) pumps and launches without input. A managed cycle takes `flight_time(d)`; pump time is ignored.
- When the selected division has a manager, each tap removes 2 % of the current cycle's remaining time. Tapping stays useful but is never required.
- Buy buttons support ×1, ×10, and Max.

---

## 6. Research (resets on prestige)

Bought with Revenue. Defined in `game/data/research.json`. Each node has `id`, `name_key`, `effect`, `value`, `cost`, and `requires_stage`.

| Group | Count | Effect | Cost rule |
|---|---|---|---|
| Division boost | 9 × 2 | ×3 revenue for one division | `base_cost * 500`, then `base_cost * 50,000` |
| Global boost | 5 | ×2 all revenue | 1e5, 1e8, 1e11, 1e14, 1e17 |
| Faster flights | 3 | −15 % flight time, all divisions | 1e6, 1e10, 1e14 |
| Easier pumping | 3 | −20 % pump taps (minimum 2) | 500, 5e4, 5e6 |

Total: 29 nodes. The UI is a simple scrolling list, grouped, not a graph.

---

## 7. Offline Progress

- Only divisions with managers earn offline.
- `offline_revenue = sum(launch_revenue(d) / flight_time(d)) * min(seconds_away, offline_cap)`
- `offline_cap` = 4 hours base. The Echo Shop extends it to 12 hours.
- Offline time below 60 seconds shows no popup.
- On return, a popup shows time away and earnings, with **Claim** and **Watch ad: ×2**.
- If the device clock is earlier than the last save time, offline earnings are zero. Do not punish further.
- Boost time (section 11) does not count down while the game is closed.

---

## 8. Permanent Progress

### Echoes and prestige

```
echoes_gained = floor(10 * sqrt(run_revenue / 1e12))        # run_revenue = all Revenue earned in this life
```

- "Enter the Black Hole" appears when division 9 reaches level 25.
- A confirm screen shows Echoes to gain and exactly what resets.
- **Resets:** Revenue, division levels, managers, research, Record Height, active boosts.
- **Stays:** Echoes, Echo Shop purchases, Lifetime Height, milestones, life count, cosmetics, settings, company name, daily reward streak.
- Each owned (unspent) Echo gives +2 % all revenue. Spending Echoes in the shop lowers this bonus. This is a deliberate trade-off.

### Echo Shop (`game/data/echo_shop.json`)

Starting costs follow `base * 3 ^ level`. T018 tunes them.

| id | Effect per level | Max level | Base cost |
|---|---|---|---|
| head_start | Start a life with 1e3 × 100^level Revenue | 5 | 10 |
| old_friends | Managers of divisions 1–3 are free | 1 | 50 |
| muscle_memory | −20 % pump taps | 3 | 15 |
| long_nap | +2 h offline cap | 4 | 20 |
| deep_echo | +0.5 % bonus per Echo | 4 | 100 |
| fast_hands | −10 % flight time | 5 | 25 |
| lucky_bottle | +3 % chance a launch pays ×10 | 3 | 40 |
| memory_bottles | Unlocks one cosmetic bottle skin | 6 | 30 |

### Lifetime Height milestones

Twelve milestones at Lifetime Height `10 ^ (3 + 2k)` metres for `k = 0..11`. Each gives ×1.1 all revenue, permanent. Each has a name (for example "Higher than Everest", "Past the Moon").

### Lives

The HUD shows "Life N". Achievements for lives 2, 5, 10, and 25 give a cosmetic trail colour.

---

## 9. Daily Systems

### Daily reward

Seven-day cycle. Rewards are minutes of current income: 10, 15, 20, 30, 45, 60, then 120 plus 3 Echoes on day 7. Missing a day restarts the cycle at day 1.

### Contracts

Three contracts each day, chosen from templates in `game/data/contracts.json`:

- Launch N times
- Buy N division levels
- Hire a manager / buy a research node
- Claim offline earnings once
- Use one boost

Each pays 15 minutes of income. Completing all three pays 1 Echo. Contracts reset at local midnight.

---

## 10. Art and Audio Direction

**Style:** Low-poly 3D with flat colours. No textures, no UV work. Shapes come from simple primitives. Charming and a little whimsical, like a children's science book.

**Why 3D low-poly:** it is scriptable in Blender, small in file size, and consistent when many agents make the models.

**Scene:** Fixed side-on camera in portrait. The launch site sits in the lower third. The vehicle rises, the camera follows, and the sky gradient changes with height. The top 55 % of the screen is the 3D scene. The bottom 45 % is the UI panel.

**Palette**

| Stages | Colours |
|---|---|
| 1–2 | Warm greens, sky blue, soft yellow |
| 3–5 | Deep blue, orange flame, metallic grey |
| 6–9 | Space purple, black, cyan and white accents |

**Per stage, the only things that change:** vehicle model, launch-site model, sky gradient (two colours), particle trail colours, ambient sound.

**Models**

| Asset | Triangle budget |
|---|---|
| Vehicle (9) | 300–1,500 each |
| Launch site (9) | 500–3,000 each |
| Kid character (1) | 800 |
| Black hole (1) | Shader on a quad plus a ring mesh |

**Trails:** smoke puff (1) → white smoke (2–3) → orange flame (4–6) → blue plasma (7) → warp streaks (8–9).

**Prestige cinematic (6 seconds, skippable after the first time):** craft approaches the black hole → screen distortion → fade to white → the hill at dawn → the kid holds a faintly glowing bottle → "Life N" title.

**UI:** One UI kit. Rounded panels, one font family (Noto Sans), large touch targets (minimum 96 px at 1080×1920). All UI is 2D Control nodes above the 3D scene.

**Audio:** CC0 sound effects only (for example Kenney packs). One music loop for stages 1–5 and one for stages 6–9. Sounds: tap, bar full, launch, payout, buy, unlock fanfare, prestige. Music and SFX have separate toggles.

---

## 11. Monetization

### Rewarded ads

| Placement id | Where | Reward | Limit |
|---|---|---|---|
| `offline_double` | Offline popup | ×2 offline earnings | Once per popup |
| `boost_2x` | Boost button on HUD | ×2 all revenue for 30 min | Stacks up to 4 h |
| `time_warp` | Boost menu | Instantly pay 20 min of income | 15 min cooldown |
| `echo_bonus` | Prestige confirm screen | +25 % Echoes for this prestige | Once per prestige |

If no ad is loaded, the button shows "No ad available" and is disabled. The game never blocks progress behind an ad.

### Interstitials

- Shown only after a stage-unlock popup closes (stage 4 and later) or after the prestige cinematic.
- Never in the first 10 minutes after install. Maximum one per 15 minutes.

### IAP (post-launch, only if the metrics gate passes)

- "Remove Ads": no interstitials, and a permanent ×2 revenue in place of `boost_2x`.

### Design rule

Ads are boosts that the player chooses. The `offline_double` placement is expected to earn the most, so the offline popup must be reliable and clear.

---

## 12. Compliance

- **Age:** target 13+ in Play Console. Do not select any age group below 13. This keeps the game outside the Families policy.
- **Consent:** show the Google UMP consent form before the first ad request.
- **Privacy policy:** a public URL is required. Link it from the store page and from Settings.
- **app-ads.txt:** host it on the developer website that is listed in Play Console.
- **Data safety form:** declare advertising ID and analytics data.
- **Trademark:** no SpaceX-like names, logos, or vehicle copies. Vehicles are generic shapes.
- **Assets:** only original or CC0 assets. Record each third-party asset in `CREDITS.md`.

---

## 13. Install Growth

This section exists because earlier apps did not get installs.

1. **Store page (ASO):** title with keywords (for example "Idle Space Company: Rocket Tycoon"), icon with one clear rocket, five screenshots with captions, a 30-second video.
2. **Localisation:** game text and store listing in EN, ES, PT-BR, FR, DE, ID, TR, RU. Idle games have little text, so this is cheap and it opens more organic search traffic.
3. **Web build:** publish a free Godot web export on itch.io with a link to the Play page. Incremental-game players browse itch.io.
4. **Communities:** post in r/incremental_games (follow its self-promotion rules) and similar groups. Ask for feedback, not installs.
5. **Short videos:** record the bottle launch and the black-hole moment for YouTube Shorts, TikTok, and Reels.
6. **Metrics gate:** two weeks after release, check the numbers in section 14 before spending more time.

---

## 14. Success Metrics

| Metric | Minimum | Good |
|---|---|---|
| Day-1 retention | 30 % | 40 % |
| Day-7 retention | 8 % | 15 % |
| Rewarded ads per daily user | 1.5 | 3 |
| Crash-free sessions | 99 % | 99.5 % |
| Average session count per day | 3 | 5 |

If day-1 retention is below 30 %, fix the first 15 minutes before any promotion.

---

## 15. Technical Requirements (summary)

Details are in `conventions.md`.

- 60 fps on a low-end phone (2 GB RAM). Android App Bundle below 100 MB.
- Save file `user://save.json`, versioned, written to a temp file then renamed, with one backup. Autosave every 30 s and on pause.
- All numbers are 64-bit floats. The design never exceeds 1e300.
- All game content (divisions, research, shop, milestones, contracts, strings) is data in `game/data/`, not constants in code.
- Ads and analytics sit behind interfaces with mock providers, so the game runs and tests pass without any plugin.
- The Android back button opens a quit confirm. The game saves when it loses focus.

---

## 16. Out of Scope for Version 1.0

- Cloud save, accounts, leaderboards
- Limited-time events and event currency
- Second prestige layer
- iOS
- Banner ads
