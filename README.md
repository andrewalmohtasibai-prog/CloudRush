# ☁️⚡ CLOUD RUSH

Sprint **Sonic-style** across an **endless** dreamy sea of clouds that **bloom into
colour as you move**. Collect rings and just *keep running* to permanently raise your
**Speed** — the more you play, the faster you get forever (the keyboard-game loop).

> 📄 See **DEVELOPMENT_PLAN.md** (how/when we build) and **PRODUCTION_BIBLE.md**
> (economy, monetization, 2026 Roblox policy, launch). This is an early build — see
> "Status" below.

---

## The fusion (what this is)
| Pillar | Source | In CLOUD RUSH |
|---|---|---|
| Momentum + boost + high top speed | Sonic | Accel/friction model + boost burst |
| **+1 Speed forever** | "+1 Speed Keyboard Escape" | Rings **and** running distance give +1 Speed |
| Speed **milestones** | keyboard game | HUD celebrations at Speed thresholds |
| Dreamy, reactive world | your cloud reference | Colour-splat trail + Future lighting |
| See other players | Roblox social | Shared sky + everyone's colour speed **Trail** |

## Controls (authentic Sonic physics)
- **Move:** WASD / thumbstick — real momentum: accelerate, skid when you turn hard, coast when you let go
- **Jump:** Space / A
- **Spindash (charge & launch):** hold **Left Shift / R2 / CHARGE** to rev (pitch rises), **release** to fire
- **Roll:** **Left Ctrl / B / ROLL** — keep momentum, can't accelerate while rolling

> Movement is a custom velocity controller adapting the [Sonic Physics Guide](https://info.sonicretro.org/Sonic_Physics_Guide)
> (constants in `SonicPhysics.luau`). It's a first pass to **play-test and tune** — and
> run animations need a follow-up (the character slides until we add custom anims).
> 360° slope/loop physics are dormant until the world has ramps.

---

## How the endless world works (v2 architecture)
- **You can never fall:** a large **ground disc follows you** every frame (1 cheap part).
- **Endless motion:** a field of **cloud puffs wraps** around you beyond the fog line, so
  you feel like you're moving through infinite sky with no visible edge.
- **Reactive floor:** soft glowing **colour splats** drop at your feet (hue cycling as you
  move) and fade behind you.
- **Sky orb** follows you so it's always framed.

## Project layout
```
CloudRush/
├── default.project.json                 ← Rojo + Lighting/Atmosphere/post-FX (depth-tuned)
└── src/
    ├── ReplicatedStorage/
    │   ├── CloudConfig.luau              ← ALL tunable numbers + helpers
    │   ├── Net.luau                      ← RemoteEvents (RingCollected/Milestone/Boosted)
    │   └── ClientState.luau              ← shared table between the 2 client scripts
    ├── ServerScriptService/
    │   ├── WorldBuilder.luau             ← ground / puff / ring factories + volumetric clouds
    │   └── CloudRushServer.server.luau   ← following world, rings, speed, milestones, DataStore
    └── StarterPlayerScripts/
        ├── MovementController.client.luau← Sonic momentum + boost + spawn camera framing
        └── CloudFX.client.luau           ← colour trail + sky orb + HUD + FOV + VFX
```

## Run it
### Rojo (recommended)
`rojo serve` in this folder → connect from the Studio Rojo plugin → **Play**.

### Studio (manual)
Recreate the tree above (matching names), set **Lighting.Technology = Future** and add the
effects listed in `default.project.json`, enable **Studio Access to API Services**
(Game Settings → Security) for DataStore, then **Play**.

## Add sounds
Paste asset ids into `CloudConfig.Sounds` (`Ring`, `Boost`, `Milestone`, `Music`). `0` = silent.

## Quick tuning (all in CloudConfig)
- **Feel:** `Acceleration`, `Friction`, `MaxTopSpeed`, `BoostSpeed`.
- **Grind pace:** `SpeedPerRing`, `StudsPerSpeed`.
- **Colour trail:** `SplatSpacing`, `SplatLife`, `HuePerStud`.
- **World size / no-fall margin:** `GroundRadius`, `FieldHalf` (keep `FieldHalf` beyond the fog).

## Status
Early build (~5%). Working: endless no-fall world, depth lighting, momentum + boost,
colour trail, rings + running → Speed, persistence, HUD. Missing: real audio, tuned feel,
retention systems, content, monetization, compliance, analytics, launch — all mapped in
**DEVELOPMENT_PLAN.md**.
