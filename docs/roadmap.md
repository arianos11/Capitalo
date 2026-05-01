# Capitalo — Roadmap

Milestones M1–M5 (Phase 1 MVP) + Phase 2-4 outline. Source: GDD §3 + §13.

Status legend: `[ ]` todo, `[~]` in progress, `[x]` done.

---

## Phase 1 — MVP (cel: 2-3 mies part-time)

**Goal phase**: grywalna gra solo: 3 sklepy, 4 kampanie, 1 tech branch, prestige cycle, lokalny save. Bez online/ads/IAP.

### M1 — Sprint 1: Foundation (Tydzień 1-2, ~30h)

**Goal**: Godot project boots, save/load works, BigNumber tested, placeholder UI shows money.

- [x] Project Godot 4.3+ skeleton + autoloady (`project.godot` istnieje)
- [x] `BigNumber.gd` + `BigNumberTest.gd` (12 grup testów)
- [x] `GameState.gd` autoload (money, shops, IP, prestige stub)
- [x] `SaveSystem.gd` z JSON save/load + offline calc stub
- [x] `EventBus.gd` z core sygnałami
- [x] **Scena CityView** — 3 sloty na sklepy (Fashion, Tech, Food), placeholder rectangles
- [x] **ShopBuilding** scene — sprite + level label + tap → opens upgrade modal (covered by ShopSlot for M1; sprite-based building → M5 polish)
- [x] **ShopUpgradeModal** — cost, current income, "Upgrade" / "Buy"
- [x] **HUD** — cash label, IPS label, settings button
- [x] **Floating numbers** — pool 30 reusable labels, "+$Y" co tick nad sklepem
- [x] **Tutorial first-run** — "Tap the shop to buy your first store!"
- [x] **Save round-trip test** — quit → reopen → kasa + sklepy zachowane
- [ ] **Offline earnings test** — clock +2h → restart → dostań earnings

**Acceptance**: kliknij 100 razy, zamknij grę, otwórz, kasa zachowana. BigNumberTest 🟢.

### M2 — Sprint 2: Core Loop (Tydzień 3-4)

**Goal**: marketing campaigns work, shops generate passive income.

- [ ] `ShopData.gd` class
- [ ] `EconomyManager.gd` `calculate_shop_income` + tick 10Hz
- [ ] `CampaignData.gd` + ładuj `data/campaigns.json` (4 kampanie Faza 1: Flyers, FB, Google, Influencer)
- [ ] `CampaignSystem.gd` z `launch_campaign` + roll mechanic (success/viral/fail)
- [ ] UI `CampaignBar` — 4 przyciski + cooldown indicator
- [ ] Customer spawning — basic, na success campaign
- [ ] SFX — click, coin, viral stinger

**Acceptance**: klik Flyers → -$5 → roll → spawn customers → income rośnie. Viral hit działa wizualnie + mechanicznie.

### M3 — Sprint 3: Shops & Managers (Tydzień 5-6)

**Goal**: 3 kategorie sklepów upgrade'owalne, managerowie hire'owalni.

- [ ] `ShopDetailModal` UI
- [ ] Shop level upgrade + cost calc (per GDD §5.3 formula)
- [ ] Buy new shop mechanic (unlock criteria)
- [ ] `ManagerData.gd` class + `data/managers.json` integracja
- [ ] Hire manager flow (z kosztem)
- [ ] Manager level upgrades 1-10
- [ ] Pixel art assety dla 3 sklepów (lub finalne placeholdery)
- [ ] Animacja klientów wchodzących/wychodzących

**Acceptance**: Fashion + Tech do Lvl 10, Fashion ma manager Lvl 5, wszystko persistent.

### M4 — Sprint 4: Tech Tree + Prestige (Tydzień 7-8)

**Goal**: pierwszy prestige cycle działa, Marketing tech branch (10 nodów).

- [ ] `TechNode.gd` class + `data/tech_tree.json` Marketing branch (10 nodów)
- [ ] TechTree UI — scrollable canvas z nodami + connections
- [ ] Research mechanic — deduct IP, unlock node, apply effects via EventBus
- [ ] Effects integration — modyfikatory do `CampaignSystem`, `EconomyManager`
- [ ] Prestige flow — warning modal → reset → IP gain calc → multiplier applied
- [ ] Prestige stats screen — total prestiges, IP earned, multiplier history

**Acceptance**: gra do $1B, Prestige, dostaję IP, kupuję 1 node, restart, multiplier działa.

### M5 — Sprint 5: Polish & MVP Launch (Tydzień 9-10)

**Goal**: MVP gotowy do wewnętrznego testu (NIE publiczny release).

- [ ] Tutorial system — kontekstowy hints (nie modal blocking)
- [ ] Achievements system — 20 podstawowych
- [ ] Settings ekran — sound on/off, music volume, reset save
- [ ] Credits ekran
- [ ] Stats ekran — total earned, time played, prestige count
- [ ] Performance pass — frame profile na mid-tier Android
- [ ] Bug fixes z playtestów (5h+ session bez crashy)
- [ ] Eksport Android APK + test na realnym telefonie
- [ ] Eksport iOS (Mac + Xcode required)

**Acceptance**: gra grywalna 5h+ bez bugów, zainstalowana na Twoim Androidzie + iPhone.

---

## Phase 2 — Soft Launch (cel: +1-2 mies)

Sprinty 6-12 obejmują:
- [ ] Pozostałe 7 kategorii sklepów (Home, Beauty, Books, Toys, Sports, Luxury, Marketplace)
- [ ] 3 pozostałe gałęzie tech tree (Operations, HR, Innovation) — łącznie 38 nodów
- [ ] AI Competitors — 3-5 NPC firm + market share
- [ ] Eventy sezonowe (Black Friday, Christmas, etc.)
- [ ] Daily rewards + 7-day login streak
- [ ] Achievements rozbudowa do ~50
- [ ] Tutorial system pełny (interaktywny FTUE)
- [ ] AdMob integration (rewarded + opcjonalny banner)
- [ ] Analytics (Firebase / Unity Analytics)
- [ ] **Soft launch PL + CZ + RO** (małe rynki = tani test)

**Acceptance Phase 2**: D1 retention >30%, D7 >10%, avg session >8 min, crash-free >99%, pierwsza sprzedaż IAP.

---

## Phase 3 — Global Launch (cel: +1 mies)

- [ ] System reputacji + PR Crisis events
- [ ] Premium IAP (Remove Ads + Premium Pack)
- [ ] Push notifications (1-2 dziennie max, nie spam)
- [ ] Comeback bonus po 3+ dniach offline
- [ ] Localization: EN, PL, DE, ES, PT-BR, RU
- [ ] Performance optimization pass #2
- [ ] **Global launch — App Store + Google Play**

**Acceptance Phase 3**: 1000+ downloads/mies, 100+ DAU stable, $50+/mies revenue, 4.0+ rating.

---

## Phase 4 — Live Ops (ongoing)

- [ ] Cloud save (Firebase Realtime DB lub Firestore)
- [ ] Leaderboardy + podgląd miast znajomych
- [ ] Battle pass / Sezony (3-mies)
- [ ] Regularne content updates (new shops, managers, events)
- [ ] Discord community + social channels
- [ ] (Opcja) C# port wybranych hot path systems

**Acceptance Phase 4**: $200+ MRR, 1000+ DAU, 4.3+ rating, Discord 100+.

---

## Risk register (z GDD §14, skrót)

| Ryzyko | P×I | Mitigation |
|---|---|---|
| Balans zły, gra nudzi | H×H | Spreadsheet sim PRZED kodem, playtest co tydzień |
| Pixel art niespójny | H×M | Master palette, każdy asset cleanup w Aseprite |
| App Store rejection | M×H | Studiuj guidelines wcześnie, prepare privacy/screens/desc |
| Brak DAU po launch | H×H | Soft launch + ASO + organic content (TikTok dev journey) |
| Burnout solo | H×H | Hard scope (Faza 1 = MVP), no scope creep, rest days |
| Godot mobile export bugs | M×M | Test exportów wcześnie, nie zostawiaj na koniec |
