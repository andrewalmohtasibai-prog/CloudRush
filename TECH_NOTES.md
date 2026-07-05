# CLOUD RUSH — Technical Notes

The advanced/high-end Roblox techniques used here, why, and where to push further.

## Rendering / look (the "dreamy" factor)
- **Future lighting** (`Lighting.Technology = Future`) for real-time shadows +
  per-pixel lighting — the modern baseline for high-end Roblox visuals.
- **Atmosphere** (Density/Haze/Decay/Glare) does the soft horizon blend so the cloud
  floor melts into the sky. This is what sells "above the clouds."
- **Volumetric `Terrain.Clouds`** for sky depth — near-free perf, huge payoff.
- **Post-processing stack:** Bloom (makes the neon rings + color trails glow),
  DepthOfField (dreamy focus falloff), ColorCorrection (gentle saturation lift),
  SunRays. Tuned subtle, not cranked.
- Colors on the reactive floor use **SmoothPlastic + Bloom** rather than Neon, so bright
  hues glow without the whole floor being a light source.

## Performance discipline (mobile-first, since the audience is kids)
- Floor is **2,304 tiles** but each has **`CastShadow = false`** — thousands of shadow
  casters is the classic Roblox FPS killer. ([devforum](https://devforum.roblox.com/t/how-to-optimize-your-game-explained/4708702))
- The **reactive coloring is bounded**: we only touch tiles within `BloomRadiusCells`
  of the player and keep a small "active/fading" set — O(radius²), not O(all tiles).
- Decorative clouds are cheap `SmoothPlastic` balls; sky depth comes from Atmosphere +
  volumetric clouds, not geometry.
- Ring spin + speed lines are **client-side/local** (no replication cost).

## Movement (Sonic momentum)
- Momentum via an **acceleration/friction scalar** driving `Humanoid.WalkSpeed`, with a
  boost burst. Input read from the **ControlModule `GetMoveVector()`** so it's robust
  even when WalkSpeed dips to 0. ([momentum controls](https://devforum.roblox.com/t/momentum-controls/2597046))
- **Upgrade path — true physics momentum:** for real inertia on turns, slopes, and
  loop-de-loops, move to a **custom `ControllerManager` + `GroundSensor`** physics
  character, or drive `LinearVelocity`/`AlignPosition`. That unlocks Sonic-style loops
  and wall-running. ([physics character controllers](https://devforum.roblox.com/t/how-to-actually-use-robloxs-physics-character-controllers/3092097))

## Networking / architecture
- **Server-authoritative** rings + speed + persistence; client owns movement + FX
  (standard Roblox split).
- Speed **Trails are server-created** so all players see each other's streaks (social).
- Cross-LocalScript comms use a **shared cached ModuleScript** (`ClientState`) — zero
  network traffic between the movement and FX scripts.
- **DataStore** with `pcall` guards + autosave + `BindToClose` so progress survives.

## Reactive floor — the next-level version
Current floor recolors discrete tiles. The **high-end upgrade** is an **EditableImage**
painted onto one big SurfaceAppearance/texture on a single floor mesh: paint colored
"footprints" into the pixel buffer where players walk and blur/fade them over time. That
gives smooth, per-pixel color trails on a *single* draw call instead of thousands of
tiles. Requires the in-experience Image APIs. ([EditableImage guide](https://devforum.roblox.com/t/a-complete-guide-to-editableimages/3858566/1))

## Known simplifications (prototype scope)
- Speed gates open **globally** (community unlock) rather than per-player, and are
  cosmetic (don't physically block on the open field).
- No slopes/loops yet (needs the physics-controller upgrade above).
- Trail color is a fixed gradient server-side; per-player hue-cycling would need a
  replicated driver.
