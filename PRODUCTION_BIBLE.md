# ☁️⚡ CLOUD RUSH — Production Bible (0 → 100% Launch Plan)

> The complete study for taking CLOUD RUSH from a prototype to a finished, monetized,
> policy-compliant Roblox game that can compete with "+1 Speed Keyboard Escape."
> Every number and policy here is sourced to 2026 Roblox facts (see §13 Sources).
> *Content from external sources was rephrased for licensing compliance.*

---

## 0. How to read this
This is organized as a **checklist you can execute**. Each section has a ✅ **Definition
of Done**. When every section's DoD is met, you're at 100% and ready to launch.
Priorities: **P0** = must-have for launch, **P1** = strong for launch, **P2** = post-launch.

---

## 1. Vision & pillars
**Pitch:** Sprint Sonic-style across a dreamy, color-reactive sea of clouds. Rings and
running permanently raise your Speed — the more you play, the faster you get forever.

**Three pillars (never break these):**
1. **Satisfying speed** — momentum, boost, color trails, "number goes up."
2. **Endless progression** — Speed → top speed → gates → rebirth, forever.
3. **Show-off social** — a shared sky, visible trails, leaderboards, flexing skins.

**Target audience:** kids/tweens (the fruit-drama + Sonic + clouds crowd). This drives
every policy and monetization choice below (kid-safe, no gambling mechanics).

---

## 2. Competitor teardown — what to match & beat
"+1 Speed Keyboard Escape" (SecretVerse) wins on:
- **Incremental +1 dopamine** on every step (we have: +1 per ring/run).
- **ASMR/satisfaction** (we need: real splat/whoosh/ring sounds — currently silent).
- **Speed gates** ("reach X to pass") — we have arches; make them *hard* gates.
- **Free-Speed social codes** (join group / like / Discord = free Speed) — **copy this.**
- **Simple, near-zero skill floor** — keep it.

**Where we beat it:** a *prettier, reactive, moving* world (color clouds), true movement
feel (Sonic momentum), and a built-in TikTok/IG character funnel. Our job: match its
retention hooks, win on feel + vibe + marketing.

---

## 3. The 0→100 feature completeness checklist

### 3.1 Core gameplay — **P0**
- [x] Momentum movement + boost
- [x] Rings + running → +1 Speed
- [x] Reactive cloud floor
- [ ] **Real audio** (ring, boost, gate, ambient music) — biggest missing "feel"
- [ ] **Hard speed-gates** (physically block until threshold, per-player)
- [ ] Jump/air control tuning; coyote time; landing feel
- [ ] Death/fall recovery (you can run off the floor edge — add soft respawn or bounds)
- [ ] Tutorial/first-30-seconds guided moment (arrow to first rings + first gate)

### 3.2 Progression & content — **P0/P1**
- [ ] **Rebirth ("Re-Fly")**: reset Speed for a permanent multiplier + prestige badge (P0 — this is the long-term hook)
- [ ] Multiple **cloud zones/biomes** beyond the first field (P1)
- [ ] **Quests/missions** (daily + one-time): "collect 100 rings", "reach Speed 500" (P0)
- [ ] **Daily login rewards** with a streak (P0 — retention)
- [ ] **Pets/companions** that give % Speed (P1) — **sold directly, not via loot boxes** (see §6/§7)
- [ ] Collectible **skins/trails** (P1)

### 3.3 Economy — **P0**
- [ ] Two currencies: **Rings** (soft, earned) + **Robux** (hard). Optionally **Gems** (premium soft).
- [ ] Clear **sinks** for Rings (buy trails, pets, cosmetic upgrades) so the economy isn't flat
- [ ] Balance pass so free players progress but paying accelerates (see §5)

### 3.4 Social / multiplayer — **P0/P1**
- [x] Shared world + replicated speed trails
- [ ] **Global + friends leaderboards** (Most Speed, Deepest/Farthest) with weekly reset (P0)
- [ ] Player **name tags + Speed/rebirth badges** overhead (P1)
- [ ] **Emotes** (P2), **co-op speed boost near friends** (P2)

### 3.5 Retention / live-ops — **P0/P1**
- [ ] Daily rewards, quests, streaks (P0)
- [ ] **Codes system** (redeem box) for free Speed → your TikTok captions (P0 — viral loop)
- [ ] Free-Speed for **social actions** (join group, like/favorite, join Discord) (P0)
- [ ] Weekly/seasonal **events** + **Season Pass** (P1)
- [ ] Update cadence plan (see §10)

### 3.6 UI/UX — **P0**
- [ ] Clean HUD (have basic) + polished shop UI, quests UI, rewards popups, settings
- [ ] Mobile-first layout (buttons reachable, readable text, safe-area aware)
- [ ] Loading screen + branded title + game icon/thumbnails (see §9)

### 3.7 Audio — **P0**
- [ ] Ring/boost/gate SFX, ambient music loop, UI clicks, rebirth stinger
- [ ] Volume settings + mute

### 3.8 Technical — **P0**
- [x] DataStore persistence (basic)
- [ ] **Session-locking + retry/backoff** on DataStore (prevent data loss/duplication)
- [ ] **Anti-cheat**: server-authoritative Speed (movement is client — validate suspicious speed/teleport; rate-limit ring claims)
- [ ] **Analytics events** (see §8)
- [ ] **Performance pass**: mobile FPS target 30+; StreamingEnabled if world grows; keep draw calls low
- [ ] Error handling / graceful degradation (already pcall-wrapped DataStore)

### 3.9 Accessibility & platform — **P1**
- [ ] Full **mobile + gamepad + PC** parity (boost button exists; verify all controls)
- [ ] Colorblind-friendly HUD; text scaling; reduce-motion option (the reactive floor can be intense)

✅ **DoD for §3:** every P0 box checked and play-tested with 5+ testers.

---

## 4. Economy design
**Currencies**
- **Rings** — earned; spent on cosmetics, pet upgrades, minor boosts.
- **Gems** (optional premium soft currency) — from quests/events/purchase; premium cosmetics.
- **Robux** — real hard currency (passes, products, subscription).

**Sources → Sinks (must balance):**
- Sources: rings from pickups + running, quest payouts, daily rewards, events.
- Sinks: cosmetics, pets, trails, rebirth costs, cosmetic upgrades. **Without sinks the
  economy inflates and Rings become meaningless** — design at least 3 strong sinks.

**Balance targets (tune with data):**
- New player should feel a Speed gain within the **first 20 seconds**.
- First **rebirth reachable in ~1 session** (15–30 min) to teach the loop; later rebirths
  scale up.
- Paying should feel like a **2–5× accelerator**, never a hard requirement.

---

## 5. Monetization (with real 2026 numbers)

### 5.1 The money math (know this cold)
- Roblox takes a **30% marketplace fee**; you net **70%** in Robux on passes & dev products. ([pricing guide](https://generalistprogrammer.com/tutorials/roblox-game-pass-pricing-guide))
- Cash out via **DevEx at $0.0038 per Earned Robux** (2026 standard rate). ([DevEx calc](https://devex.gg/))
- ⚠️ **The 42%-boosted rate ($0.0054/Robux) only applies to age-checked 18+ US players** — a **kids' game does NOT qualify**, so budget with **$0.0038**. ([Roblox newsroom](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42))
- **Example:** player spends **100 Robux** → you keep **70** → DevEx = **~$0.27**.
- **DevEx minimum:** 30,000 Earned Robux (~$114) + 13+, verified email, tax form. ([DevEx FAQ](https://en.help.roblox.com/hc/en-us/articles/203314100-Developer-Exchange-DevEx-FAQs))
- **Cross-game sales of passes/products were disabled (May 2026)** — passes only sell inside the experience. ([announcement](https://devforum.roblox.com/t/disabling-cross-game-sales-of-passes-and-dev-products-and-introducing-the-transfers-api/4618396/))

### 5.2 Game passes (permanent, one-time) — suggested Robux
| Pass | Suggested price (R$) | Notes |
|---|---|---|
| **×2 Speed** | 299–499 | flagship seller |
| **Auto-Run / Auto-Collect** (idle) | 499–999 | huge in sims |
| **×2 Rings** | 199–399 | |
| **VIP** (skin + VIP area + daily bonus + tag + hub fly) | 499–799 | status + value |
| **Mega Boost** (longer/stronger boost) | 249–349 | |
| **Lucky** (better pet/cosmetic value) | 249–349 | keep away from gambling — see §6 |

### 5.3 Developer products (repeatable) — suggested Robux
| Product | Price (R$) |
|---|---|
| ×3 Speed Boost (15 min) | 25–49 |
| Instant Speed pack S/M/L/XL | 49 / 99 / 199 / 499 |
| Ring pack | 49–499 |
| **Starter Pack** (one-time bundle, best value) | 99 |
| Skip/teleport to next zone | 49 |

### 5.4 Subscriptions (new 2026) — **P1/P2**
Roblox now supports recurring subscriptions. Offer a **"Sky Club"** monthly (e.g., ~199
R$/mo): daily bonus, rotating exclusive skin, small permanent perk. Recurring revenue +
a monthly marketing beat. ([2026 economy shift](https://www.msn.com/en-us/news/other/the-2026-roblox-economy-is-shifting-to-r15-boosted-payouts-and-recurring-revenue/gm-GM0DA16154))

### 5.5 Conversion strategy
- **First-session offer:** show the Starter Pack early — first-session conversion drives sims.
- Sell **acceleration + expression**, never *only* pay-to-win, or the social/free loop dies.
- Track **ARPDAU** and payer conversion; most Roblox games sit low — treat any lift as a win.

---

## 6. ⚠️ Paid Random Items — the policy that shapes your monetization
This is the single most important compliance decision.

- If players can pay (Robux, or currency bought with Robux) to get a **random** item
  (loot boxes, gacha eggs, random-chance rewards), Roblox now requires you to **disclose
  the exact numerical odds (%) of every outcome before purchase** — a global rule pushed
  by Korea's loot-box law. ([Tech Times](https://www.techtimes.com/articles/319148/20260626/koreas-loot-box-rules-push-roblox-disclose-item-odds-worldwide.htm), [Roblox docs](https://create.roblox.com/docs/en-us/production/monetization/virtual-items))
- You must **declare it in the Maturity & Compliance Questionnaire** and gate it with
  **`PolicyService` (`ArePaidRandomItemsRestricted`)**, or the experience becomes
  **unavailable to under-18 users in the UK, Australia, and other regions.** ([UK restriction](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-uk-users-under-18/3072183), [promoting to younger audiences](https://en.help.roblox.com/hc/en-us/articles/47965190783892-Promoting-Items-to-Younger-Audiences))

**➡️ Recommendation for CLOUD RUSH (kids audience): DO NOT use paid random items.**
- **Sell pets/skins directly** (fixed price, you know what you get). No gacha/eggs bought
  with Robux.
- This keeps the game **available to the youngest, widest audience**, avoids gambling
  optics, and removes a whole compliance/odds-disclosure burden.
- If you *ever* add random rewards, make them **earned with free/soft currency only**
  (Rings from play), never Robux — that sidesteps the "paid" rule.

---

## 7. Roblox policy & compliance checklist — **P0**
- [ ] **Complete the Maturity & Compliance Questionnaire.** Unrated experiences are
      filtered out of search/recommendations for under-13. ([policy update](https://devforum.roblox.com/t/updating-experience-guideline-policies-to-keep-our-younger-users-safe/3249079))
- [ ] **Target a "Minimal" content label / All Ages.** Under-9 accounts default to only
      Minimal/Mild; Roblox Kids (5–8) & Select (9–15) accounts only see labels up to
      Moderate that pass selection. Keep it clean = maximum reach. ([content maturity](https://en.help.roblox.com/hc/en-us/articles/8862768451604-Content-Maturity-Labels), [age-based accounts](https://about.roblox.com/newsroom/2026/04/introducing-roblox-kids-and-select-accounts))
- [ ] **No paid random items** (see §6). If any randomness, free-currency only.
- [ ] **Original IP only.** Do NOT use "Sonic," Sega assets, or the actual fruit-drama
      characters/names. Build your **own** cast/world so nothing can be DMCA'd or moderated.
- [ ] **Community Standards:** no misleading thumbnails/titles, no fake "free Robux," safe
      chat (use Roblox TextChatService + default filtering), no off-platform solicitation
      of minors, no collecting personal info (PII) from players.
- [ ] **Ads policy:** follow Roblox Ads Manager content rules; no deceptive creatives.
- [ ] **DevEx eligibility & tax:** 13+, 30k Earned Robux, verified email, W-9/W-8 on file.
- [ ] **Test on a fresh/child account** to confirm the experience is actually visible to
      your target age after the questionnaire.

✅ **DoD for §7:** questionnaire submitted, Minimal label confirmed, no paid-random
mechanics, original assets verified, chat/safety on.

---

## 8. Analytics & KPIs — **P0**
**Instrument these events** (Roblox AnalyticsService + your own):
- Session start/end, playtime, FTUE completion, first Speed gain, first purchase.
- Ring collected, gate opened, rebirth done, boost used, code redeemed.
- Funnel: install → first ring → first gate → first rebirth → first purchase.

**Target KPIs (aim high; median games are much lower):**
| Metric | Why | Target to chase |
|---|---|---|
| **D1 retention** | do they come back tomorrow | 30%+ (great = 40%+) |
| **D7 retention** | habit forming | 10–15%+ |
| **D30 retention** | long-term (RFY weights this!) | 4–6%+ |
| **Avg session** | engagement | 12–20+ min |
| **Payer conversion** | monetization | 1–3%+ |
| **ARPDAU** | revenue/user/day | track & grow |

The **Recommended-For-You algorithm now heavily weights 28-day+ retention**, so your
whole live-ops plan should optimize for players coming back for a *month*, not a day.
([RFY improvements](https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575/1), [discovery = value×personalization](https://devforum.roblox.com/t/my-research-on-the-roblox-algorithm-discovery-for-experiencesgames/2707618/))

---

## 9. Store presence (conversion happens here)
- [ ] **Game icon** — bold, readable at thumbnail size (the fruit character + rainbow trail + clouds).
- [ ] **3–5 thumbnails** — show the color-reactive floor, boost, "get FASTER", a big Speed number.
- [ ] **Title** — keyword-rich, e.g. include "Speed", "Run", trend words (but no trademarks).
- [ ] **Description** — hook + features + code note + social links; front-load keywords.
- [ ] Genre/tags set correctly; age recommendation set.

---

## 10. Launch plan

### 10.1 Golden rule
**Do NOT flip the game Public until it's production-ready.** The discovery algorithm
starts scoring you (and tracking retention) the moment you're Public — a rough public
launch permanently drags your metrics. Polish in **Private/soft-launch first.**
([discovery flaw discussion](https://devforum.roblox.com/t/roblox-discovery-is-flawed-how-this-one-issue-enrages-players-and-hurts-platform-profits/3811654))

### 10.2 Phases
1. **Alpha (private):** core loop + audio + save + basic shop. 5–10 testers. Fix crashes/data bugs.
2. **Soft launch (unlisted / small):** invite your Discord + a few TikTok followers.
   Watch D1/session/FPS. Iterate 1–2 weeks until D1 and playtime look healthy.
3. **Go Public** only once retention + performance are solid and the store page is done.
4. **Marketing spike:** coordinate TikTok/IG drops + codes with the public launch day.

### 10.3 The marketing engine (your unfair advantage)
- **TikTok/IG:** short clips of the color trails + boost + your fruit characters' drama;
  every caption drops a **code** that gives free Speed → funnels straight into the game.
- **Free-Speed social loop:** reward join-group / like-favorite / join-Discord with Speed
  — this farms the **favorites, likes, and engagement signals the algorithm rewards.**
- **Roblox Ads Manager:** use **"Acquire New Users"** to seed players and **"Drive
  Retention (30 days)"** to bring them back — nearly half the top-100 earners use it.
  ([Ads Manager](https://devforum.roblox.com/t/ads-manager-updates-acquire-new-users-continuous-campaigns-and-more/3862159))
- **Influencers:** small Roblox YouTubers/TikTokers for early plays.

### 10.4 Launch-day checklist
- [ ] Servers/DataStore load-tested; no data-loss bug
- [ ] Codes live + posted in socials
- [ ] Store page final (icon/thumbnails/desc)
- [ ] Questionnaire done, Minimal label live
- [ ] Analytics firing
- [ ] Ads campaign scheduled
- [ ] A pinned "known issues / update coming" plan for feedback

---

## 11. Post-launch live-ops
- **Update cadence:** ship something every **1–2 weeks** (new skin, code, event, zone).
  Consistency signals a live game to both players and the algorithm.
- **Events & seasons:** limited skins tied to your TikTok drama arcs = urgency + a fresh
  marketing beat each time.
- **Listen to data:** where do players drop? What converts? Cut what's unused, double down
  on what retains.
- **A/B test** prices, first-session offers, tutorial variants.

---

## 12. Roadmap (phased, effort-tagged)
| Phase | Goal | Key work | Rough effort |
|---|---|---|---|
| **P0 — Feel** | fun in 30s | audio, hard gates, tutorial, edge-bounds | 1–2 wks |
| **P0 — Retain** | come back | daily rewards, quests, leaderboards, codes | 1–2 wks |
| **P0 — Money & Policy** | earn safely | passes/products, starter pack, questionnaire, anti-cheat, DataStore hardening | 1–2 wks |
| **P1 — Depth** | stay a month | rebirth, zones, pets/skins (direct-sale), season pass | 2–4 wks |
| **Launch** | go public | soft launch → polish → public + marketing spike | 1–2 wks |
| **P2 — Scale** | grow | events, subscriptions, emotes, true Sonic loops (physics controller) | ongoing |

---

## 13. Risk register
- **Data loss** → session-lock + backups (P0). Nothing kills a sim faster.
- **Exploiters** (fake Speed) → server validation + rate limits.
- **Poor D1 at public launch** → soft-launch first; don't go public early.
- **Policy miss** (random items / unrated) → follow §6/§7 exactly.
- **IP claim** → original cast/world only.
- **Performance on mobile** → profile early; the reactive floor + trails must stay cheap.
- **Monetization dependence on kids** → remember the standard $0.0038 DevEx rate; volume + retention is the game, not high ARPU.

---

## 14. Sources (2026)
- DevEx rate & 18+ boost: [Roblox newsroom](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42), [DevEx help](https://www.roblox.com/developer-exchange/help), [devex.gg](https://devex.gg/)
- Marketplace fee / passes vs products: [pricing guide](https://generalistprogrammer.com/tutorials/roblox-game-pass-pricing-guide), [monetization guide](https://generalistprogrammer.com/tutorials/roblox-game-monetization-complete-revenue-strategy-guide)
- Cross-game sales disabled: [announcement](https://devforum.roblox.com/t/disabling-cross-game-sales-of-passes-and-dev-products-and-introducing-the-transfers-api/4618396/)
- Paid random items: [clarifying requirements](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622), [odds disclosure](https://create.roblox.com/docs/en-us/production/monetization/virtual-items), [UK under-18 restriction](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-uk-users-under-18/3072183), [Tech Times](https://www.techtimes.com/articles/319148/20260626/koreas-loot-box-rules-push-roblox-disclose-item-odds-worldwide.htm)
- Content maturity / age: [content maturity labels](https://en.help.roblox.com/hc/en-us/articles/8862768451604-Content-Maturity-Labels), [younger-users policy](https://devforum.roblox.com/t/updating-experience-guideline-policies-to-keep-our-younger-users-safe/3249079), [Roblox Kids/Select](https://about.roblox.com/newsroom/2026/04/introducing-roblox-kids-and-select-accounts)
- Discovery / RFY / ads: [RFY improvements](https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575/1), [optimizing discovery](https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox), [Ads Manager](https://devforum.roblox.com/t/ads-manager-updates-acquire-new-users-continuous-campaigns-and-more/3862159)

> *Note: percentages/targets are industry guidance, not guarantees. Verify live figures on
> the Creator Hub, and treat your own analytics as the source of truth.*
