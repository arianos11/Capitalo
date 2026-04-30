# Capitalo — Architecture

Decyzje techniczne i pattern guide. Source of truth dla "JAK budujemy", komplementarne do GDD ("CO budujemy").

---

## 1. Stack

| Warstwa | Wybór | Dlaczego |
|---|---|---|
| Engine | Godot 4.3+ (mobile renderer) | Free, brak royalty, GDScript dobry pod Claude, czysty mobile export |
| Język | GDScript (100% w Phase 1-3) | Prostota, hot reload, AI dobrze pisze. C# dopiero gdy hot path tego wymaga |
| Save | Lokalny JSON (`user://savegame.json`) | Brak backendu w Phase 1-2. Cloud save = Phase 4 |
| Numerics | Custom `BigNumber` class | Idle game = liczby 10^100+, `float` pęka |
| State | Single autoload `GameState` | Single source of truth. Nie ma rozproszonego state |
| Comm | EventBus (signals) | Luźne sprzęganie systemów, łatwy refactor |
| Build | `godot --export` per platform | iOS via macOS+Xcode, Android via Android SDK |

---

## 2. Autoloady — boundaries

Definicje w `project.godot` `[autoload]`. Każdy ma jedną odpowiedzialność.

| Autoload | Plik | Czyta | Pisze | Zależy od |
|---|---|---|---|---|
| `EventBus` | `scripts/autoload/EventBus.gd` | — | — | nic (czysty hub sygnałów) |
| `GameState` | `scripts/autoload/GameState.gd` | EventBus | money, shops, IP, prestige, reputation | `BigNumber`, data classes |
| `SaveSystem` | `scripts/autoload/SaveSystem.gd` | GameState | `user://savegame.json` | GameState, EconomyManager (offline calc) |
| `EconomyManager` | `scripts/autoload/EconomyManager.gd` | GameState | money via GameState | `BigNumber`, EventBus |
| `CampaignSystem` | `scripts/autoload/CampaignSystem.gd` | GameState (validate cost) | money via GameState, emits results | `BigNumber`, EventBus, DataLoader |
| `AudioManager` | `scripts/autoload/AudioManager.gd` | EventBus (sub) | audio buses | EventBus |

### Zasada żelazna
**Cross-system communication ZAWSZE przez EventBus.** Nigdy `EconomyManager.foo()` z `CampaignSystem`. Nigdy UI nie czyta `GameState.money` w `_process` — subskrybuje `EventBus.money_changed`.

Wyjątek: czytanie state do walidacji (np. `CampaignSystem` sprawdza czy stać na koszt) jest OK, mutacja przez własną metodę GameState (`GameState.try_spend_money`).

---

## 3. EventBus — zasady

Plik: `scripts/autoload/EventBus.gd`. Wszystkie sygnały tu, scentralizowane.

Kanon (z GDD §12.3):
- `money_changed(new_amount: BigNumber)`
- `shop_purchased(shop: ShopData)`, `shop_upgraded(shop: ShopData)`
- `manager_hired(manager: ManagerData)`
- `campaign_launched(campaign_id: String)`
- `campaign_completed(campaign_id: String, result: Dictionary)`
- `tech_researched(node_id: String)`
- `achievement_unlocked(achievement_id: String)`
- `prestige_performed(ip_gained: int)`
- `offline_earnings_calculated(amount: BigNumber, seconds: int)`
- `viral_hit(campaign_id: String, multiplier: float)`
- `pr_crisis_triggered(crisis: Dictionary)`
- `reputation_changed(new_value: float)`

Reguły:
- Nazwy: snake_case, czas przeszły dla rezultatów (`shop_purchased`), teraźniejszy dla intencji (`campaign_launched`)
- Typowane parametry zawsze
- Subskrybenci nie-autoload nodes muszą `disconnect()` w `_exit_tree()` żeby uniknąć leaków
- Godot 4: emit przez `EventBus.signal_name.emit(...)` (NIE `emit_signal("...")`)

---

## 4. BigNumber — kontrakt

Plik: `scripts/classes/BigNumber.gd`, `class_name BigNumber`.

### Immutable
Wszystkie operacje **zwracają nową instancję**. `current.add(other)` NIE mutuje `current`.

```gdscript
# ❌ ŹLE
GameState.money.add(income)

# ✅ DOBRZE
GameState.money = GameState.money.add(income)
```

### API
- `BigNumber.new(value: float)` / `BigNumber.from_float(f)`
- `.add(other)`, `.subtract(other)`, `.multiply(other)`, `.divide(other)`
- `.multiply_by_float(f)` — mnożenie przez scalar
- `.is_greater_than(other)`, `.is_greater_or_equal(other)`, `.equals(other)`
- `.to_display() -> String` — `"1.23K"`, `"5.67M"`, ..., `"1.00 Vg"` (10^60+)
- `.to_dict() / BigNumber.from_dict(d)` — save/load

### Performance
- `.to_display()` wynik **cache'uj per sekunda** w UI, nie rebuild co frame
- Operacje BigNumber są CPU-tańsze niż się wydaje (mantissa+exponent), ale UI re-render kosztuje

### Kiedy NIE używać BigNumber
- Wskaźniki [0..1] (success rate, viral chance, multiplikatory <100x) → `float` OK
- Counts < 10^6 (level sklepu, IP < 10000) → `int` OK
- Reputacja 1.0-5.0 → `float`

---

## 5. Save format

`user://savegame.json` (pretty JSON), backup `user://savegame_backup.json`.

### Versioning
```json
{
  "version": 1,
  "money": { "mantissa": 1.234, "exponent": 6 },
  "shops": [...],
  "last_save_time": 1735689600
}
```

`SaveSystem.load_game()` **MUSI** sprawdzić `version`. Migracje: `_migrate_v1_to_v2(dict)` etc., wołane sekwencyjnie.

### Symetria `to_dict` / `from_dict`
Każde nowe pole w `GameState`:
1. Dodaj domyślną wartość przy deklaracji
2. Dodaj do `to_dict()`
3. Dodaj do `from_dict()` z fallbackiem (`save_dict.get("field", default)`)
4. Bump `SAVE_VERSION` jeśli pole jest required

**Złamanie tej symetrii = silent save corruption.** PR review wymaga sprawdzenia.

### Auto-save
- Co 30s (Timer w SaveSystem)
- On `NOTIFICATION_APPLICATION_PAUSED` (mobile background)
- Manual: prestige, settings change, scene transition do menu

### Offline earnings
- Calc raz przy `load_game()` (NIE w pętli)
- Cap: 8h * 3600s = 28800s
- Efficiency: 50% (per GDD §5.1) — gracz ma motywację wracać aktywnie
- Emit `offline_earnings_calculated` → UI pokaże modal "Welcome back!"

---

## 6. Data layer

`data/*.json` — read-only w runtime. Ładowane przez `scripts/utils/DataLoader.gd`.

| Plik | Zawiera | Schema docs |
|---|---|---|
| `data/shops.json` | 10 kategorii sklepów, base income, growth | GDD §5.3 |
| `data/managers.json` | 18 managerów (z planowanych 30) | GDD §5.4 |
| `data/campaigns.json` | 7 typów kampanii, success/viral/cost | GDD §5.2 |
| `data/tech_tree.json` | 48 nodów w 4 branches | GDD §6 |

Zasady:
- Game logic NIGDY nie hardcoduje liczb z tych plików
- Hot reload OK w dev (re-call `DataLoader.load_all()`)
- Validation przy bocie — DataLoader sprawdza required fields, emit błąd jeśli brak
- JSON format → łatwa edycja w `balance-tuner` agent + diff w PR

---

## 7. Performance budget (mobile)

| Co | Budget | Źródło |
|---|---|---|
| Income tick | 0.1s (10 Hz) | GDD §12.4 |
| Customers visible | max 50 (object pool) | GDD §12.4 |
| Floating numbers pool | 30 reusable labels | GDD §12.4 |
| Auto-save | 30s interval, async write | GDD §12.4 |
| Frame target | 60 FPS na mid-tier Android (2020+) | nasza decyzja |
| Boot-to-playable | < 3s na mid-tier | nasza decyzja |

Nie używaj:
- 3D rendering, GI, SDFGI (mobile renderer ich nie wspiera dobrze)
- `get_node()` w `_process` — cache w `_ready()`
- Per-frame BigNumber `.to_display()` — cache 1Hz

---

## 8. Testing

### Phase 1 (teraz)
- `tests/BigNumberTest.gd` — 12 grup testów (existing)
- Manual: BigNumberTest uruchamiane ad-hoc w `_ready()` lub headless
- Save/load round-trip — manual test po każdej zmianie GameState fields

### Phase 2+
- GUT framework (https://github.com/bitwes/Gut)
- CI: GitHub Actions z headless Godot, runs GUT on every PR
- Property-based tests dla EconomyManager (random shop combos → income reproduces)

### Co testujemy zawsze
- BigNumber: arithmetic accuracy, display format, save round-trip
- EconomyManager: income calc deterministic dla danego state
- CampaignSystem: roll distribution mieści się w expected range (large N)

### Czego NIE testujemy unit
- UI scenes (manual test na simulator/device)
- Animations (visual review)
- Asset pipeline (Aseprite cleanup workflow)

---

## 9. Build & deploy (Phase 1)

| Target | Command | Wymaga |
|---|---|---|
| Local desktop run | F5 w Godot editor | Godot 4.3+ |
| Headless test | `godot --headless --quit-after 5 --script tests/BigNumberTest.gd` | godot w PATH |
| Android APK | `godot --export-debug "Android" build/capitalo.apk` | Android SDK + export preset |
| iOS build | `godot --export-debug "iOS" build/capitalo.ipa` | macOS + Xcode 15+ + signing cert |

Wszystkie buildy → `build/` (gitignored).

Phase 2: AdMob integration (Godot Android plugin).
Phase 3: Premium IAP (Godot in-app purchase plugin).
Phase 4: Cloud save (Firebase via Godot plugin).

---

## 10. Decyzje wymuszone (do not revisit bez argumentu)

| Decyzja | Powód |
|---|---|
| Lokalne save tylko w Phase 1 | Backend = scope creep, MVP musi działać offline |
| GDScript only, no C# | Velocity > marginal perf. Hot path identyfikujemy później |
| Brak WebGL/web export | Mobile-first targeting, web = inny UX paradigm |
| Brak Unity/Unreal | Royalties, complexity, mobile bloat |
| Portrait orientation only | Idle game = jedna ręka = portrait |
| Polski + EN tylko w Phase 1 | Localizacja kosztuje, Phase 3 dodaje 4 języki |
| Brak online/multi w Phase 1-3 | Different game design, dodaje 6+ miesięcy scope |
