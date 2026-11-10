**Idle Space Company — Game Design Document (v0.1)**

### 1. High Concept
You play as the founder of a space company (player-named, default “SpaceZ”). You start as a kid on a hill pumping air into message bottles and launching them. Through successive jobs and companies you climb from model rockets → payloads → orbital stations → moon bases → solar system networks → galaxy gates. The endgame is flying into a black hole and returning as a child again, carrying permanent “Echoes” of previous lives.

**Genre**: Idle / Incremental  
**Platform**: Android (portrait)  
**Monetization**: Free + Rewarded Ads (primary) + optional IAP  
**Session length**: 1–5 minutes active, strong offline progress  
**Target**: Casual / hybrid-casual, 8+

### 2. Core Loop
1. **Pump** — Tap (or hold) to fill the Fuel/Charge bar.  
2. **Launch** — When full, tap Launch. Vehicle flies, generates Height + Revenue.  
3. **Spend** — Use Revenue to buy managers, speed upgrades, research, and automation.  
4. **Progress** — Hit Height milestones to unlock the next stage.  
5. **Prestige** — Reach the Black Hole stage, enter it, and reset as a child with permanent Echoes.

### 3. Currencies

| Currency | Type | Source | Use | Notes |
|----------|------|--------|-----|-------|
| **Fuel / Charge** | Active | Tapping / auto-pumpers | Fill bar to launch | Visual bar that fills. Resets per launch. |
| **Height** | Secondary / Progress | Every launch | Unlock stages, milestones, some research | Persistent across prestige with multipliers. Displayed as meters → km → AU → light-years. |
| **Revenue** | Tertiary / Soft | Launches + offline | Managers, upgrades, research, speed | Main spending currency. Scales exponentially. |
| **Echoes** | Prestige | Black Hole reset | Permanent multipliers, starting bonuses, new bottle skins | Hard currency of the meta. |

**Optional later**: Event currency or “Contracts” for limited-time challenges.

### 4. Stages (Progression)

| # | Stage | Vehicle | Height Unit | Key Fantasy | Unlock Condition |
|---|-------|---------|-------------|-------------|------------------|
| 1 | Kid on the Hill | Message bottles | meters | Pure childhood wonder | Start / Prestige return |
| 2 | Drone Startup | Model rockets & drones | km | First real engineering | Reach 500 m |
| 3 | Aerospace Startup | Sounding rockets / payloads | 100 km | Suborbital | Reach 50 km |
| 4 | Agency Era | Orbital rockets | Low Earth Orbit | Real space company | Reach 200 km |
| 5 | Station Builder | Modules & crew | ISS altitude | Permanent presence | Reach 400 km |
| 6 | Moon Base | Landers + habitats | 384,000 km | Another world | Reach Moon |
| 7 | Solar System Network | Probes & colonies | AU | Multi-planet | Reach Mars |
| 8 | Galaxy Gate | FTL ships | light-years | Interstellar | Reach 1 ly |
| 9 | Black Hole | Final craft | Event horizon | Prestige trigger | Reach black hole |

Each stage changes background, vehicle sprite, particle trail, and resource name flavor, but reuses the same UI systems.

### 5. Monetization

**Primary (Rewarded Ads)**  
- Double Revenue for the next X launches  
- Instant fill of Fuel/Charge bar  
- Claim offline earnings with 2×–3× multiplier  
- Extra Echoes after prestige (e.g. +20%)  
- Speed boost (2× launch rate for 5–10 min)

**Secondary**  
- Interstitial ads after prestige or major milestone (low frequency, skippable after 5s)  
- Optional “Remove Ads” IAP  
- Small IAP packs: Echo starter packs, permanent Height multiplier, cosmetic vehicle skins  

**Design goal**: Ads feel like helpful boosts, not interruptions. Idle games monetize best when rewarded ads are tied to the core loop (fuel, offline, prestige).

### 6. Art & Visual Design Direction

**Style**: Stylized 2D, clean vector / soft cel-shaded. Charming and slightly whimsical rather than photorealistic. Think “AdVenture Capitalist meets a children’s science book.”

**Color palette**  
- Early stages: Warm greens, sky blues, soft yellows (hill, clouds, sunshine)  
- Mid stages: Deep blues, oranges (rocket flames), metallic greys  
- Late stages: Deep space purples, blacks, bright cyan/white accents (stars, warp, black hole)

**Key visual elements (buildable)**  
- Simple side-view or slight perspective launch scene that upgrades per stage  
- Vehicle sprite that swaps and gets particle trails (smoke → flame → plasma → warp)  
- Fuel bar with satisfying fill animation and launch “pop”  
- Height counter that dramatically changes units  
- Prestige cinematic: screen warps → fade to white → kid on the hill again with faintly glowing bottles

**Production note**: Keep one consistent UI kit. Only swap backgrounds, vehicle sprites, and particle colors between stages. This keeps art scope realistic for a solo developer.

### 7. Systems Summary

- **Managers**: Auto-pump and auto-launch. Bought with Revenue.  
- **Research tree**: Permanent upgrades within a run (cheaper pumps, better revenue per launch, etc.).  
- **Offline progress**: Based on current automation level + Height multiplier.  
- **Milestones**: Height thresholds that give permanent small bonuses even after prestige.  
- **Prestige (Black Hole)**: Resets stage progress, keeps Echoes. Echoes buy permanent Height multiplier, starting Revenue, and cosmetic “memory” bottles.  
- **Company name**: Player can rename their company; it appears on vehicles and in UI.

### 8. MVP Scope (Recommended First Build)

1. Stages 1–4 only  
2. Basic tap-to-pump → launch loop  
3. Revenue + Height currencies  
4. 4–5 managers  
5. Simple research  
6. One prestige layer (even if black hole is just a placeholder cinematic)  
7. Rewarded ads for double offline + double launch  
8. Basic 2D art (one hill, one sky, one rocket)

This is enough to soft-launch, test retention, and iterate.
