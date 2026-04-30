# Capitalo

> **Idle pixel tycoon dla mobile.** Zbuduj retail empire od pojedynczego sklepu z modą do globalnego marketplace. Marketing-driven gameplay zamiast tap-the-shop. Retro 16-bit pixel art aesthetic.

**Status**: Phase 1 (MVP) — pre-production complete, gotowy do Sprint 1.

---

## 🎯 Co to jest

Capitalo to mobilna gra idle/clicker tycoon, gdzie zamiast tapać na sklepy żeby zarobić, **odpalasz kampanie marketingowe** które rolują na success/viral/fail. Tycoon meta to deep tech tree (48 nodes, 4 branches), seasonal events, AI competitors, PR crisis decisions.

**Target audience**: 25-40 lat, gracze idle games (AdVenture Capitalist, Idle Miner Tycoon), nostalgia za pixel art, lubią strategy depth.

**Key differentiator**: marketing-as-core-loop. Nikt inny tego nie zrobił dobrze w idle space.

---

## 🛠 Tech stack

- **Engine**: Godot 4.3+ (mobile renderer)
- **Language**: GDScript
- **Save format**: JSON (z `BigNumber` serialization)
- **Target platforms**: iOS, Android
- **Asset pipeline**: Stable Diffusion (PixelArtRedmond) → Aseprite cleanup → atlas via TexturePacker

---

## 📁 Struktura projektu

```
capitalo/
├── project.godot           # Główny config Godot (autoloady, display, input)
├── README.md              # Ten plik
├── .gitignore
│
├── assets/                # Wszystkie zasoby
│   ├── sprites/          # PNG z pixel art (po Aseprite cleanup)
│   ├── audio/            # music/, sfx/
│   ├── fonts/            # m5x7.ttf, PixelOperator.ttf, PressStart2P.ttf
│   ├── palettes/         # Master Palette w 4 formatach (gpl, json, svg)
│   └── sources/          # Aseprite source files (.aseprite)
│
├── scenes/                # Sceny Godot (.tscn)
│   ├── main/             # Main.tscn — entry point
│   ├── city/             # CityView, ShopBuilding scenes
│   ├── ui/               # HUD, modals, screens
│   └── tutorial/         # First-run tutorial
│
├── scripts/               # Cały kod
│   ├── autoload/         # Globalne singletony (EventBus, GameState, SaveSystem...)
│   ├── classes/          # Reusable classes (BigNumber, ShopData, ...)
│   └── utils/            # Helpers (Formatters, DataLoader)
│
├── data/                  # JSON-y z game data (read-only)
│   ├── shops.json        # 10 kategorii sklepów + specjalizacje
│   ├── managers.json     # 18 managerów (planowane 30)
│   ├── campaigns.json    # 7 typów kampanii marketingowych
│   └── tech_tree.json    # 48 tech nodes w 4 branches
│
├── tests/                 # Unit tests (BigNumber, etc.)
└── docs/                  # GDD, economy spec, style guide
```

---

## 🚀 Quickstart

### 1. Otwórz w Godot

1. Pobierz [Godot 4.3+](https://godotengine.org/download)
2. Open Godot → Project Manager → **Import** → wybierz `project.godot`
3. Po imporcie: **F5** (Run Project) — odpali się scena Main z placeholder UI

### 2. Pierwsze uruchomienie powinno pokazać:

- Tło dark navy (`#1D2B53`)
- Title "CAPITALO"
- "$0" (cash)
- "$0/sec" (income per second)
- DEBUG button "+$1,000" — dodaje kasę do testowania
- Status label

To jest minimalny placeholder. **Wszystkie systemy bazowe (autoloady) działają już teraz** — Save/Load, BigNumber, EventBus, EconomyManager, CampaignSystem, AudioManager.

### 3. Test BigNumber

W konsoli Godot uruchom:
```gdscript
var test = BigNumberTest.new()
test.run_all_tests()
```
Powinno wyświetlić: `✓ All tests passed!` (12 grup testów).

---

## 🧠 Architektura (must-read przed kodowaniem)

### Autoloady — globalne singletony

| Autoload | Plik | Purpose |
|----------|------|---------|
| **EventBus** | `scripts/autoload/EventBus.gd` | Hub sygnałów. Każdy ważny event przechodzi przez EventBus. |
| **GameState** | `scripts/autoload/GameState.gd` | Single source of truth dla player progress. Money, shops, managers, tech, prestige. |
| **SaveSystem** | `scripts/autoload/SaveSystem.gd` | JSON save/load + offline earnings (cap 8h). Auto-save co 30s. |
| **EconomyManager** | `scripts/autoload/EconomyManager.gd` | Income tick co 0.1s. Calculate per-shop income (level + manager + tech + prestige + reputation). |
| **CampaignSystem** | `scripts/autoload/CampaignSystem.gd` | Marketing campaigns: launch, roll outcome (success/viral/fail), cooldowns. |
| **AudioManager** | `scripts/autoload/AudioManager.gd` | Wrapper na sounds (subscribed do EventBus). |

### Pattern komunikacji

**ZAWSZE przez EventBus, NIGDY direct references między systemami.**

```gdscript
# ❌ BŁĄD: shop bezpośrednio woła HUD
hud.update_money_label(GameState.money)

# ✅ OK: shop emituje sygnał, HUD słucha
GameState.add_money(amount)  # to robi: EventBus.money_changed.emit(money)
# w HUD: EventBus.money_changed.connect(_on_money_changed)
```

### BigNumber

Idle games operują na liczbach 10^100+. `float` w GDScript pęka. Używaj `BigNumber`:

```gdscript
var cost = BigNumber.from_float(1234.0)
var current = GameState.money
if current.is_greater_or_equal(cost):
    GameState.try_spend_money(cost)

# Display:
print(current.to_display())  # "1.23K"
```

**Wszystkie operacje arytmetyczne ZWRACAJĄ NOWĄ instancję** (immutable pattern). Nie modyfikują self.

### Save format

`user://savegame.json` — pretty-printed JSON. Backup: `user://savegame_backup.json`.

GameState ma `to_dict()` / `from_dict()`. BigNumber też ma `to_dict()` / `from_dict()`. **Wszystkie nowe pola w GameState dodawaj do obu funkcji.**

---

## 📖 Dokumentacja źródłowa

W folderze `docs/` (oraz w głównym repo `/mnt/user-data/outputs/`):

| Dokument | Co zawiera |
|----------|-----------|
| **Capitalo_GDD.md** | Pełny Game Design Document (1233 linijki, 17 sekcji) |
| **Capitalo_Economy_v1.xlsx** | Spreadsheet ekonomii — 986 formuł, 5 zakładek, kalibracja progresji |
| **STYLE_GUIDE.md** | Pixel art style guide (748 linijek, 14 sekcji) |
| **LOGO_SPEC.md** | Logo specification + AI prompts + ASO + social media |
| **data/shops.json** | 10 kategorii sklepów: Fashion, Tech, Food, Home, Beauty, Books, Toys, Sports, Luxury, Marketplace |
| **data/managers.json** | 18 managerów (z planowanych 30) — perki, flavor, archetypy |
| **data/campaigns.json** | 7 typów kampanii: Flyers, Facebook, Google, Influencer, TV Spot, TikTok, Super Bowl |
| **data/tech_tree.json** | 48 nodes w 4 branches: Marketing (12, 125 IP), Operations (14, 193 IP), HR (10, 208 IP), Innovation (12, 397 IP) |

---

## 📋 Sprint 1 — co robić następnie

Z GDD §13.1 — **MVP Sprint 1** (~2 tygodnie part-time, ~30h):

### Goal Sprint 1
Działający loop: kup sklep → sklep zarabia kasę → upgrade → odblokuj 2-gi sklep. Save/load działa.

### Deliverables Sprint 1
1. **Scena CityView** — pokazuje 3 sloty na sklepy (Fashion, Tech, Food)
2. **ShopBuilding** scene — wyświetla sprite, level label, tap → opens upgrade modal
3. **ShopUpgradeModal** — pokazuje cost, current income, "Upgrade" / "Buy" button
4. **HUD** — cash label, IPS label, settings button
5. **Floating numbers** — co X sekund "+$Y" floating up nad sklepem
6. **Tutorial state** — first-run shows "Tap the shop to buy your first store!"
7. **Save/load test** — quit game, reopen, kasa i sklepy się zachowują
8. **Offline earnings test** — zmień system clock o 2h forward, restart, dostań offline earnings

### Out of scope Sprint 1
- ❌ Marketing campaigns (Sprint 2)
- ❌ Managers (Sprint 2)
- ❌ Tech tree (Sprint 3)
- ❌ Prestige (Sprint 3)
- ❌ AI competitors / events (Sprint 4)
- ❌ Ads / IAP (Phase 2)

### Asset minimum dla Sprint 1
- 3 sklepy x 3 levele = 9 sprite'ów (Fashion, Tech, Food)
- Tła wieś (placeholder OK)
- Tile trawy 16x16
- 2-3 UI buttony
- 1 coin particle (8x8)

Wszystko można robić **placeholder** w Sprint 1 — flat color rectangles z tekstem. Pixel art finalny dopiero w Sprint 5.

---

## 🎨 Workflow produkcji assetów

Per STYLE_GUIDE.md §5:

1. **Stable Diffusion** (lokalnie lub via Replicate) — generate 4-8 wariantów per asset
2. **Wybierz najlepszy** wariant
3. **Aseprite cleanup** (15-30 min):
   - Load palette: `assets/palettes/capitalo_master_palette.gpl`
   - Resize do target size (Nearest Neighbor!)
   - Force palette: Color Mode → Indexed
   - Manual fixes: outline, floating pixels, missing details
4. **Export PNG** (8-bit indexed, transparent)
5. **Add to atlas** via TexturePacker (Phase 2)
6. **Reference w scenie**

---

## 🧪 Testing

### Unit tests
- `tests/BigNumberTest.gd` — 12 grup testów dla BigNumber

Run: w GameState `_ready()` dorzuć tymczasowo:
```gdscript
BigNumberTest.new().run_all_tests()
```

### Integration testing
- Save/load round-trip
- Offline earnings calculation
- Income tick accuracy (10x/sec)

### Future (Phase 2+)
- GUT framework (https://github.com/bitwes/Gut)
- CI: GitHub Actions running tests headless

---

## 🛣 Roadmap

| Phase | Cel | Czas |
|-------|-----|------|
| **Phase 1: MVP** | 3 sklepy, 4 kampanie, 1 tech branch, prestige | 2-3 mies part-time |
| **Phase 2: Soft Launch** | Wszystkie 10 sklepów, full tech tree, AdMob, soft launch PL/CZ/RO | +1-2 mies |
| **Phase 3: Global** | Reputation, IAP, push notifications, lokalizacje (6 języków), global launch | +1 mies |
| **Phase 4: Live Ops** | Cloud save, leaderboards, battle pass, content updates | ongoing |

**Realistic v1.0 timeline**: 4-7 miesięcy part-time od dziś.

---

## ⚖️ Licencja & ownership

- Kod: **proprietary** (Twój / firmy software house)
- Assety: **proprietary** (po Aseprite cleanup z AI generations)
- Fonty: m5x7 (CC0), PixelOperator (free), Press Start 2P (Open Font License)
- Audio: TBD — Suno AI tracks lub freelancer commissions

---

## 📞 Decyzje / kontakt

- **Game Design**: Arian (sole designer)
- **Tech**: Arian (Godot, GDScript)
- **Business**: Arian + partner (software house)
- **Marketing**: pre-launch DIY (Twitter, TikTok, Discord)

---

## 🔗 Linki

- Domain: capitalo.com (TBD — verify WHOIS)
- Twitter: @capitalogame (TBD — register)
- TikTok: @capitalogame (TBD — register)
- Discord: TBD — server "Capitalo Community"
- Press kit: TBD (Phase 2)

---

**Pre-production complete: April 2026.**
**Sprint 1 starts: gotowy do odpalenia w Claude Code.**
