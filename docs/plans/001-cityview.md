# Plan 001 — CityView scene

**Milestone**: M1 Sprint 1 (Foundation)
**Author**: Opus (planning)
**Implementer**: Sonnet (executing)
**Status**: [x] DONE
**Estimated complexity**: M (~2-3h Sonnet session)

---

## Goal

Scena `CityView` z 3 slotami na sklepy (Fashion / Tech / Food per GDD §3 Faza 1). Slot pokazuje albo placeholder "+" (kup) albo zatop level + IPS (jeśli kupiony). Tap na slot emituje `EventBus`. To **foundation** pod ShopBuilding (M1#2), ShopUpgradeModal (M1#3), HUD (M1#4).

## Out of scope

- ShopBuilding scene (osobny plan)
- Pixel art assety (placeholder ColorRect na razie)
- Animacje klientów
- Modal upgrade (osobny plan)
- HUD wiring (CityView tylko emituje sygnały, HUD osobno)
- Logika kupowania sklepu (EconomyManager już ma stub, tylko emit)

## Files to create

| Plik | Rola |
|---|---|
| `scenes/city/CityView.tscn` | Scene z VBox 3 slotów portrait layout |
| `scenes/city/CityView.gd` | Script: bind data/shops.json, emit on tap, react to shop_purchased/upgraded |
| `scenes/city/ShopSlot.tscn` | Reusable component per slot (placeholder rect + label + tap area) |
| `scenes/city/ShopSlot.gd` | Logic: empty/owned state, level/IPS labels, tap detection |
| `tests/CityViewTest.gd` | Headless test: load scene, simulate tap, verify EventBus signals fire |

## Files to modify

| Plik | Zmiana |
|---|---|
| `scenes/main/Main.tscn` | Instantiate `CityView.tscn` w UI CanvasLayer (zastąp placeholder DEBUG przy okazji? **NIE** — debug zostaje do M5) |
| `scripts/autoload/EventBus.gd` | **(brak — sygnały `shop_purchased` / `shop_upgraded` już są)** |
| `docs/roadmap.md` | Po impl: `[x]` przy "Scena CityView" w M1 |

## Architecture notes

### Komunikacja
- `CityView` **nie pisze** do `GameState` bezpośrednio
- Tap → `ShopSlot._on_tapped()` → `EventBus.shop_slot_tapped.emit(shop_id)`
- Listener (przyszły `ShopController` lub `Main.gd` na razie) decyduje: jeśli not owned → otwórz buy modal; jeśli owned → upgrade modal
- `CityView` subskrybuje `EventBus.shop_purchased` / `shop_upgraded` i odświeża wizualnie odpowiedni slot

### NOWY sygnał wymagany w EventBus
```gdscript
## Gracz tapnął slot sklepu w CityView (do logiki buy/upgrade).
## param: shop_id: String, slot_state: String ("empty" / "owned")
signal shop_slot_tapped(shop_id, slot_state)
```
Dodać do `scripts/autoload/EventBus.gd` w sekcji `## SHOP SIGNALS`.

### Layout (portrait 1080x1920)
- `CityView` to VBoxContainer w UI CanvasLayer
- Pozycja: offset_top = 320 (poniżej HUD), offset_bottom = 1500 (nad CampaignBar/Debug)
- 3 sloty pionowo, każdy ~360px wysokości, separator 30px
- ShopSlot: HBoxContainer = [icon placeholder 200x200] [VBox: name label, level label, IPS label] [+/upgrade button area]

### State per slot
| State | Wizualnie | Tap action |
|---|---|---|
| `empty` | szary rect + "+" + nazwa kategorii + "Buy: $X" | emit `shop_slot_tapped(id, "empty")` |
| `owned` | kolorowy rect z `color_primary` z shops.json + level label + "$X.XK/sec" | emit `shop_slot_tapped(id, "owned")` |

### Data binding
- `CityView._ready()` → `DataLoader.load_shops()` → iteruje pierwsze 3 z `unlock_phase == "phase_1"` → instantiate `ShopSlot` per shop
- `ShopSlot.setup(shop_data: Dictionary, owned_state: bool, level: int, ips: BigNumber)`
- Initial state: czytaj z `GameState.shops` (lista posiadanych)

## Test cases (TDD — write first, must fail)

`tests/CityViewTest.gd` (GDScript, run via `godot --headless --script`):

1. **test_loads_3_shop_slots** — instantiate scene, expect `get_children().size() == 3` w VBox
2. **test_slot_empty_state** — fresh GameState (no shops owned), pierwszy slot ma label "Buy: $0" (Fashion unlock_cost = 0)
3. **test_slot_owned_state** — mock `GameState.shops = [{id: "fashion", level: 5}]`, pierwszy slot pokazuje "Lvl 5"
4. **test_tap_emits_signal_empty** — connect spy do `EventBus.shop_slot_tapped`, simulate `_on_tapped` na empty slot Fashion, assert signal fired with `("fashion", "empty")`
5. **test_tap_emits_signal_owned** — same dla owned state
6. **test_subscribes_shop_purchased** — emit `EventBus.shop_purchased.emit("fashion")`, slot przechodzi z empty → owned wizualnie

Pomocnik: `tests/_helpers/SignalSpy.gd` (jeśli nie ma, stwórz minimalny — connect signal, count emissions, last_args).

## Phase-by-phase implementation order

### Phase A — EventBus signal + tests skeleton (15 min)
1. Add `signal shop_slot_tapped(shop_id, slot_state)` w EventBus
2. Create `tests/_helpers/SignalSpy.gd` (jeśli brak)
3. Create `tests/CityViewTest.gd` z 6 testami — wszystkie failujące (reference yet-non-existent CityView.tscn)
4. Run: `godot --headless --script tests/CityViewTest.gd` → expect failures
5. **Commit**: `test(cityview): add failing tests for slot rendering and tap signals`

### Phase B — ShopSlot component (45 min)
1. `scenes/city/ShopSlot.tscn` — Control root, HBox layout, ColorRect placeholder, 3 Labels, Button (full-area, flat)
2. `scenes/city/ShopSlot.gd` — `setup()` method, `_on_pressed` → emit
3. Manual smoke: instantiate w MainTscn temp, F5, click → console log
4. **Commit**: `feat(cityview): add ShopSlot reusable component`

### Phase C — CityView scene (30 min)
1. `scenes/city/CityView.tscn` — VBox z 3 slotami (load programmatically)
2. `scenes/city/CityView.gd` — `_ready()` ładuje shops.json, instancuje ShopSlot per shop, subscribuje EventBus
3. Wire `Main.tscn` → instantiate CityView w UI CanvasLayer
4. **Commit**: `feat(cityview): wire CityView with 3 phase-1 shop slots`

### Phase D — pass tests (30 min)
1. Run testy → fix to przejdą
2. Run `gdlint scripts/ scenes/` → fix
3. Run `godot --headless --quit-after 5 --path .` → expect zero ERROR/SCRIPT lines (poza już znanym font warning jeśli wróci)
4. **Commit**: `test(cityview): all 6 tests passing`

### Phase E — roadmap update (5 min)
1. Mark `[x]` w `docs/roadmap.md` przy "Scena CityView"
2. **Commit**: `docs(roadmap): mark CityView deliverable complete`

## Risks

| Risk | Mitigation |
|---|---|
| GUT framework nie zainstalowane → custom test runner | Phase A SignalSpy = minimal helper (~30 lines). Migracja do GUT w Phase 2 sprintu |
| `ShopSlot` Button przykrywa cały slot → utrudnia future drag/drop | OK na M1, drag/drop nie planowany do M5 |
| `DataLoader.load_shops()` nie istnieje jako method | Sprawdzone — istnieje (`scripts/utils/DataLoader.gd` line ~40, gotowe) |
| GameState.shops na starcie = `[]` array → iter na empty OK | OK, test #2 covers this |
| Portrait coords mogą się zderzyć z DEBUG panel (offset 1600) | CityView offset_bottom 1500 — 100px bufor |

## Acceptance criteria

- [ ] `godot --headless --script tests/CityViewTest.gd` → 6/6 PASS
- [ ] `godot --headless --quit-after 5 --path .` → zero `ERROR` / `SCRIPT ERROR` w outputcie
- [ ] F5 w editor → widać 3 sloty w portrait, tap na każdy → console log z signal emit
- [ ] `gdlint scripts/ scenes/city/` → clean
- [ ] CityView nie czyta `GameState` poza initial `_ready()` snapshot — wszystko reactive via EventBus
- [ ] Commit chain: 5 commitów per phase, push do origin/main

## Handoff to Sonnet

Sonnet czytaj ten plan + `@CLAUDE.md` + `@docs/architecture.md` (sekcje 3 EventBus, 4 BigNumber). NIE czytaj całego GDD — to za dużo kontekstu na ten task. Jeśli niejasne: zapytaj zanim kodujesz, nie zgaduj.

Po skończeniu wszystkich Phase commitów: zapisz `docs/plans/001-cityview.md` jako `[x] DONE` w sekcji Status na górze, commit `docs(plans): mark 001-cityview done`.
