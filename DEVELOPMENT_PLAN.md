# ☁️⚡ CLOUD RUSH — Development Plan & Working Method

> The **PRODUCTION_BIBLE.md** is the *what* (features, economy, policy, launch).
> This document is the *how and when*: how we work, and a realistic ~6-month
> milestone plan so we build deliberately instead of improvising.

---

## 0. Why a plan (and why we stop rushing)
Good Roblox games aren't written in one sitting — they're built in **small, tested,
reviewed increments** over months. Rushing produces exactly what we had: a build that
"runs" but isn't playable. From here we work in **milestones**, each ending at a
**stable, play-tested commit**. Speed is not the metric. **A playable, polished slice is.**

---

## 1. How we work together (every session)
A tight, repeatable loop:

1. **Pick ONE milestone/system** from the plan below (never "do everything").
2. **I research** the current best Roblox approach for it (docs, devforum, patterns).
3. **I implement it one file/system at a time**, config-driven, commented.
4. **You play-test in Studio** and give real feedback (screenshots + "how it feels").
5. **We iterate** until that system hits its **Definition of Done**.
6. **Commit at a stable point** — the repo is never left broken.
7. Only then move to the next system.

### Ground rules (best practices we follow)
- **Never leave the codebase broken.** Every commit builds and runs.
- **One concern per commit**, clear messages, push to `main` (or a branch for big changes) so you can `git pull`.
- **All tuning lives in `CloudConfig`** — no magic numbers scattered around.
- **Server-authoritative** for anything that matters (Speed, rings, saves); client for feel.
- **Test on mobile early** — the audience is on phones; 30+ FPS is a requirement, not a nice-to-have.
- **Play-test each milestone with real people** before calling it done.
- **Cut scope, never quality.** If a month is tight, we ship fewer features polished, not more features broken.

### Definition of Done (template — every system must pass)
- [ ] Works on PC **and** mobile
- [ ] No errors in the Output window
- [ ] Feels good in a blind play-test (not just "functions")
- [ ] Tunable from `CloudConfig`
- [ ] Committed + pushed at a stable point

---

## 2. Where we are now (honest status)
**~5% complete.** We have: momentum movement, an endless following ground (no more
falling), a wrapping cloud field, depth-tuned lighting, a color-splat trail, a following
sky orb, rings + running → Speed, persistence, and a HUD.
**Not yet:** real audio, tuned feel, retention systems, content, monetization,
compliance, analytics, QA, launch. That's what the plan below covers.

---

## 3. The ~6-month milestone plan
Each month = one theme. Weekly sub-goals inside. Times are realistic for a small team;
adjust to your pace.

### 🌥️ Month 0 — Foundations & Feel *(in progress)*
**Goal:** it's genuinely *fun to just run around* for 2 minutes.
- Endless no-fall world ✅, depth lighting ✅, spawn/camera ✅, color trail ✅
- **Next:** real SFX (footsteps/wind/ring/boost) + music; tune momentum, boost, turn feel; add a jump/air feel; a readable ring model (torus); a short "run this way → grab rings" intro.
- **DoD:** a new player, given no instructions, runs, boosts, grabs rings, and smiles.

### 🎯 Month 1 — Core Loop & Retention Scaffolding
**Goal:** reasons to come back tomorrow.
- Tune Speed economy (rings vs running vs top speed)
- **Daily login rewards + streak**, **quests** (daily + one-time), **leaderboards** (global + friends), **codes redeem box**
- Free-Speed for social actions (group/like/Discord)
- **DoD:** D1 retention looks healthy in a small test; players have a clear next goal on login.

### 🌈 Month 2 — Content & Progression
**Goal:** depth that keeps players for weeks.
- **Rebirth ("Re-Fly")** with permanent multiplier + prestige display
- Multiple **cloud zones/biomes** (color themes, unlock by Speed)
- **Skins + trails** (your fruit cast), **pets** that give % Speed — **sold directly, no loot boxes** (policy, see Bible §6)
- **DoD:** a returning player always has "one more unlock" to chase.

### 💰 Month 3 — Monetization & Economy
**Goal:** it earns, fairly.
- Game passes (×2 Speed, Auto-Run, VIP…), dev products (boosts, Starter Pack), optional subscription
- Shop UI, first-session offer, economy sinks so Rings stay meaningful
- **DoD:** clean shop, purchases grant correctly, free players still progress.

### ✨ Month 4 — Polish & Juice
**Goal:** it *feels* premium.
- Full audio pass, VFX polish, UI/UX pass, loading screen, icon + thumbnails
- **Performance pass**: mobile FPS, part counts, draw calls; accessibility (reduce-motion, colorblind-safe, text scale)
- **DoD:** looks and feels like a top-chart game on a mid phone.

### 🛡️ Month 5 — Compliance, Analytics, QA, Hardening
**Goal:** safe, measurable, unbreakable.
- Maturity & Compliance Questionnaire (target Minimal / All Ages), PolicyService checks
- **DataStore hardening** (session-lock, retries), **anti-cheat** (validate Speed/teleport, rate-limit rings)
- **Analytics events** + funnel (Bible §8); QA pass; original-IP audit
- **DoD:** no data loss under stress, no obvious exploits, metrics flowing, questionnaire submitted.

### 🚀 Month 6 — Soft Launch → Public Launch
**Goal:** launch well, not early.
- **Soft launch privately/unlisted**; watch D1 + session + FPS; iterate 1–2 weeks
- Store page final; **go Public only when retention + perf are solid**
- **Marketing spike:** TikTok/IG drops + codes + Roblox Ads Manager (Acquire + Retain)
- **DoD:** healthy retention at soft launch → public + coordinated marketing.

*(After launch = live-ops forever: weekly updates, events, seasons — Bible §11.)*

---

## 4. Milestone board (quick view)
| Month | Theme | Ship when… |
|---|---|---|
| 0 | Feel | running around is fun |
| 1 | Retention | there's a reason to return |
| 2 | Content | there's always a next unlock |
| 3 | Money | it earns fairly |
| 4 | Polish | it feels premium |
| 5 | Safe & measured | no data loss / exploits, metrics on |
| 6 | Launch | retention proven, then public |

---

## 5. What I need from you each round
- **Play-test and report feel** (screenshots + "too fast / too slow / boring / confusing").
- **Decisions** when I flag a fork (e.g., a design or monetization choice).
- **Assets you want** (sound ids, your fruit-character art) when we reach those systems.
- Patience on the pace — we trade speed for a game that actually lands.

---

## 6. Immediate next step (Month 0 finish)
Pick ONE to do next, done *properly*:
- **A) Audio + juice pass** (SFX/music/tune the run+boost so it feels alive), or
- **B) A proper ring model (torus) + a 20-second intro moment**, or
- **C) Movement deep-tune** (accel/friction/turn/air) until the running feels perfect.

I'll research the best approach for whichever you pick, implement it carefully, you
play-test, we iterate, then commit. One solid step at a time.
