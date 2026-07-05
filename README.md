# ☁️⚡ CLOUD RUSH

Sprint **Sonic-style** across an endless, dreamy **sea of clouds** that **bloom into
color as you move**. Collect rings and just *keep running* to permanently raise your
**Speed** — the more you play, the faster you get forever (the keyboard-game loop),
Sonic-flavored, in a color-reactive sky world.

---

## The fusion (what this actually is)

| Pillar | Source | In CLOUD RUSH |
|---|---|---|
| Momentum + boost + high top speed | Sonic | Accelerate/friction model + boost burst |
| **+1 Speed forever** | "+1 Speed Keyboard Escape" | Rings **and** running distance give +1 Speed |
| Speed **gates** ("reach X to pass") | keyboard game | Neon arches that open at Speed thresholds |
| Dreamy, reactive world | your cloud reference | Color-reactive cloud floor + Future lighting |
| See other players | Roblox social | Shared world + everyone's colored speed **Trail** |

---

## Controls
- **Move:** WASD / thumbstick (hold to build momentum)
- **Jump:** Space / A button
- **Boost:** Left Shift / R2 / the on-screen **BOOST** button

---

## Project layout
```
CloudRush/
├── default.project.json                 ← Rojo + all Lighting/Atmosphere/post-FX
└── src/
    ├── ReplicatedStorage/
    │   ├── CloudConfig.luau              ← ALL tunable numbers + cell math
    │   ├── Net.luau                      ← RemoteEvents
    │   └── ClientState.luau              ← shared table between the 2 client scripts
    ├── ServerScriptService/
    │   ├── WorldBuilder.luau             ← builds floor / clouds / orb / rings / gates
    │   └── CloudRushServer.server.luau   ← players, rings, speed, gates, DataStore
    └── StarterPlayerScripts/
        ├── MovementController.client.luau← Sonic momentum + boost
        └── CloudFX.client.luau           ← reactive floor + HUD + FOV + VFX
```

## Run it

### Rojo (recommended)
1. Install [Rojo](https://rojo.space/) + the Studio plugin.
2. `rojo serve` in this folder, connect from Studio. Press **Play**.

### Studio (manual)
1. New Baseplate. In **Lighting**, set `Technology = Future`, add an **Atmosphere**,
   **BloomEffect**, **DepthOfFieldEffect**, **ColorCorrectionEffect**, **SunRaysEffect**,
   **Sky** (values are listed in `default.project.json`).
2. **ReplicatedStorage:** `ModuleScript`s `CloudConfig`, `Net`, `ClientState`.
3. **ServerScriptService:** `ModuleScript` `WorldBuilder` + `Script` `CloudRushServer`.
4. **StarterPlayerScripts:** `LocalScript`s `MovementController`, `CloudFX`.
5. Enable **Studio Access to API Services** (Game Settings → Security) so the
   DataStore save/load works. Press **Play**.

> Names must match exactly — scripts require each other by name.

## Add sounds
Paste asset ids into `CloudConfig.Sounds` (`Ring`, `Boost`, `Gate`). `0` = silent.

## Quick tuning
- **Faster/floatier Sonic feel:** raise `Acceleration`, `MaxTopSpeed`, lower `Friction`.
- **Grind pace:** `SpeedPerRing`, `StudsPerSpeed`.
- **More color trail:** raise `BloomRadiusCells` / `ColorFadeTime` (watch mobile perf).
- **Color speed:** `HuePerStud`.
