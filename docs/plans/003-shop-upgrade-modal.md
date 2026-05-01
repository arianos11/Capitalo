# Plan 003 — ShopUpgradeModal

**Milestone**: M1 Sprint 1 (Foundation)
**Author**: Opus (planning)
**Implementer**: Sonnet (executing)
**Status**: [x] DONE
**Estimated complexity**: M (~2h Sonnet session)

---

## Goal

Modal UI który pokazuje detale sklepu i pozwala kupić (jeśli not owned) albo upgrade (jeśli owned). Otwierany przez listener na `EventBus.shop_slot_tapped` (z 001 plan). Przycisk Buy/Upgrade waliduje cash, deduktuje, woła `GameState.purchase_shop()` / `upgrade_shop()`. Modal zamyka się po sukcesie albo na cancel.

Cleanup decyzja: spec M1 wymienia osobno "ShopBuilding scene" (sprite + level + tap → modal). **`ShopSlot` z 001 już to spełnia jako placeholder dla M1**. Sprite-based building visualization to M5 polish (pixel art assets). Plan ten obejmuje ShopBuilding aspekt = oznaczyć w roadmap obie pozycje (`ShopBuilding` + `ShopUpgradeModal`) jako covered.

## Out of scope

- Sprite-based ShopBuilding (M5)
- Specialization picker (M3 — Specializations sub-system z `data/shops.json`)
- Manager assignment z poziomu modala (M3)
- Animacje otwierania/zamykania modala (M5 polish, na razie instant show/hide)
- Buy x10 / Buy max buttons (Phase 2 polish)
- Confirm dialog dla expensive upgrades (Phase 2)

## Files to create

| Plik | Rola |
|---|---|
| `scenes/ui/ShopUpgradeModal.tscn` | Modal UI: Title, IPS info, Cost label, Buy/Upgrade Button, Close Button, Backdrop |
| `scenes/ui/ShopUpgradeModal.gd` | Setup z shop_id, render state (empty/owned), wire button → GameState calls |
| `scripts/autoload/ModalController.gd` | NOWY autoload — listener na `shop_slot_tapped`, instantiate + show modal |
| `tests/ShopUpgradeModalTest.gd` | Headless: setup empty/owned, click buy → GameState changes, signals fire |

## Files to modify

| Plik | Zmiana |
|---|---|
| `project.godot` | Dodaj `ModalController="*res://scripts/autoload/ModalController.gd"` w `[autoload]` |
| `scripts/autoload/EventBus.gd` | (już ma `modal_opened`/`modal_closed`/`shop_purchased`/`shop_upgraded` — używaj tych. Dodaj `shop_purchase_failed(shop_id, reason)` jeśli nie ma) |
| `scenes/main/Main.tscn` | Dodaj pusty `ModalLayer` (CanvasLayer z layer=10) gdzie ModalController będzie addował modale |
| `docs/roadmap.md` | Po impl: `[x]` przy "**ShopBuilding** scene" (jako covered by ShopSlot+Modal w M1) ORAZ `[x]` przy "**ShopUpgradeModal**" |

## Architecture notes

### Komunikacja
- `CityView/ShopSlot` tap → `EventBus.shop_slot_tapped.emit(shop_id, "empty"|"owned")`
- `ModalController._on_shop_slot_tapped(shop_id, state)` → instantiate `ShopUpgradeModal`, call `setup(shop_id, state)`, `add_child` w `Main/ModalLayer`
- Modal Buy/Upgrade press:
  - read `EconomyManager.get_shop_upgrade_cost(shop_id)`
  - `if GameState.try_spend_money(cost): GameState.purchase_shop(id)` lub `upgrade_shop(id)`
  - `EventBus.shop_purchased`/`shop_upgraded` autoemit z GameState (już są)
  - Modal: close_self() (queue_free)
- Modal Close button → `queue_free()` + `EventBus.modal_closed.emit("shop_upgrade")`
- Modal Backdrop tap → close (UX standard)

### Zero direct refs
- Modal **nie** trzyma ref do CityView/ShopSlot
- Modal **nie** czyta `GameState` w `_process` — tylko w `setup()` i przed Buy press
- ModalController **nie** trzyma listy aktywnych modali per shop — pojedynczy modal naraz (refuse second `shop_slot_tapped` jeśli modal już otwarty)

### NOWY sygnał (jeśli brak)
```gdscript
## Próba zakupu/upgrade nie powiodła się (np. brak kasy).
## param: shop_id: String, reason: String ("insufficient_funds" / "invalid_shop")
signal shop_purchase_failed(shop_id, reason)
```
Sprawdź `scripts/autoload/EventBus.gd` — jeśli już jest, skip. Sekcja `## SHOP SIGNALS`.

### Layout (portrait 1080x1920)
- Backdrop: ColorRect full-screen, color (0,0,0,0.6), MouseFilter STOP, click → close
- Modal box: 800x1000 centered (anchor center, offset_left=-400, offset_right=400, offset_top=-500, offset_bottom=500)
- Inside box VBox separation 30:
  - `TitleLabel` — shop name (font ~48)
  - `IconRect` — placeholder ColorRect 200x200, color z `shop_def.color_primary`
  - `LevelLabel` — "Level 5" lub "Not owned" (~32)
  - `IPSLabel` — "Income: $1.23K/sec" lub hide jeśli not owned
  - `CostLabel` — "Cost: $123" (~36, bold)
  - `ActionButton` — text "Buy" (empty state) lub "Upgrade" (owned state), height 120
  - `CloseButton` — text "Close" lub "X" w prawym górnym rogu
- Disable ActionButton + szare wybarwienie jeśli `cost > GameState.money`
- Sub-text "Insufficient funds" pod button gdy disabled

### Auto-refresh on money_changed
Modal subscribes `EventBus.money_changed` — disable/enable Action button gdy gracz zarobi więcej kasy w czasie gdy modal otwarty.

### Cost po upgrade
Po `purchase_shop`/`upgrade_shop` → `EventBus.shop_purchased`/`shop_upgraded` emit → modal NIE refresh (zamyka się). Następne otwarcie modala = fresh setup z nowym levelem.

## Test cases (TDD)

`tests/ShopUpgradeModalTest.gd` (custom runner pattern):

1. **test_empty_state_renders_buy_button** — setup z shop_id="fashion", state="empty" → ActionButton.text == "Buy", LevelLabel == "Not owned"
2. **test_owned_state_renders_upgrade_button** — mock `GameState.purchase_shop("fashion")` first, setup z state="owned" → ActionButton.text == "Upgrade", LevelLabel contains "Level"
3. **test_cost_label_uses_economy_manager** — fashion unlock_cost=0, level=0 → CostLabel == "Cost: $0" (lub "Free")
4. **test_buy_button_calls_purchase_shop** — SignalSpy na `EventBus.shop_purchased`, GameState.money = $1000, click Buy → spy.count==1, args==["fashion"]
5. **test_buy_button_deducts_money** — initial money = $100, fashion cost = $0 (unlock free), click Buy → GameState.money == $100 (free) lub $X (deducted)
6. **test_insufficient_funds_disables_button** — GameState.money = $0, modal dla shop z cost > 0 (np. "tech" jeśli cost > 0, sprawdź data) → ActionButton.disabled == true
7. **test_money_changed_reenables_button** — start z disabled, emit `money_changed` z dużą kasą → button enabled
8. **test_close_button_frees_modal** — instantiate, capture ref, click close, await frame → modal.is_inside_tree() == false
9. **test_backdrop_tap_closes_modal** — click backdrop → modal closed
10. **test_modal_controller_opens_on_signal** — emit `shop_slot_tapped("fashion", "empty")` → ModalController dodaje modal do drzewa
11. **test_modal_controller_refuses_second_open** — emit signal twice → only one modal in tree

Reuse `tests/_helpers/SignalSpy.gd`.

## Phase-by-phase

### Phase A — EventBus signal + tests skeleton (15 min)
1. Sprawdź czy `shop_purchase_failed` istnieje w EventBus, jeśli nie → dodaj
2. Create `tests/ShopUpgradeModalTest.gd` z 11 testami — wszystkie fail
3. Run → expect failures
4. **Commit**: `test(modal): add failing tests for ShopUpgradeModal + ModalController`

### Phase B — ShopUpgradeModal scene + script (50 min)
1. `scenes/ui/ShopUpgradeModal.tscn` per layout spec
2. `scenes/ui/ShopUpgradeModal.gd`:
   - `setup(shop_id: String, state: String)` — render labels, button text, color
   - `_on_action_pressed()` — purchase/upgrade flow
   - `_on_close_pressed()` / backdrop click handler
   - `_on_money_changed()` — re-evaluate button enabled state
   - `_exit_tree()` cleanup
3. **Commit**: `feat(modal): add ShopUpgradeModal scene with buy/upgrade flow`

### Phase C — ModalController autoload (25 min)
1. `scripts/autoload/ModalController.gd`:
   - `_ready()` — `EventBus.shop_slot_tapped.connect(_on_shop_slot_tapped)`
   - `_on_shop_slot_tapped(shop_id, state)` — guard if `_active_modal != null`, instantiate, find Main/ModalLayer, add_child, setup
   - Track `_active_modal: Node` weak ref, clear on `EventBus.modal_closed`
2. `project.godot` — register autoload
3. `Main.tscn` — add `ModalLayer` CanvasLayer (layer=10) jako sibling do `UI`
4. **Commit**: `feat(modal): add ModalController autoload + ModalLayer`

### Phase D — pass tests + lint (20 min)
1. Run testy → fix wszystkie 11 PASS
2. `gdlint scripts/ scenes/ui/` clean
3. `godot --headless --quit-after 5 --path .` → zero ERROR/SCRIPT
4. **Commit**: `test(modal): all 11 tests passing`

### Phase E — manual smoke test (5 min)
1. F5 w editor
2. Tap Fashion empty slot → modal otwiera się, "Buy" button → click → modal close, ShopSlot updates do owned
3. Tap Fashion owned slot → modal "Upgrade", click → level++, modal close
4. Tap Tech (assuming cost > 0) z $0 → button disabled, "Insufficient funds" pod
5. (opcjonalnie) Add some money via DEBUG → button enables
6. **Brak commitu** (manual verification only)

### Phase F — roadmap update
1. Mark `[x]` przy "ShopBuilding scene" w M1 z notką: "(covered by ShopSlot for M1 placeholder; sprite-based building → M5 polish)"
2. Mark `[x]` przy "ShopUpgradeModal"
3. **Commit**: `docs(roadmap): mark ShopBuilding (M1 placeholder) + ShopUpgradeModal complete`

### Phase G — plan DONE marker
1. Edit `docs/plans/003-shop-upgrade-modal.md` Status → `[x] DONE`
2. **Commit**: `docs(plans): mark 003-shop-upgrade-modal done`

## Risks

| Risk | Mitigation |
|---|---|
| `GameState.try_spend_money(BigNumber.from_float(0.0))` może zwrócić false dla zero cost | Edge case: jeśli cost==0 → skip try_spend, just purchase directly. Sprawdź semantykę w GameState |
| `EconomyManager.get_shop_upgrade_cost` dla level=0 zwraca base_cost (not 0). Spec: pierwszy zakup = unlock_cost z shops.json. Mismatch! | Plan's intent: pierwszy zakup używa `shop_def.unlock_cost` (= 0 dla Fashion); upgrade używa `get_shop_upgrade_cost` formula. Modal musi wiedzieć który użyć po `state` param |
| ModalController + autoload kolejność (czy EventBus loaded first?) | EventBus już w autoload list line 21 → ModalController musi być DALEJ w `[autoload]` żeby EventBus był ready. Add na końcu listy autoloadów |
| Backdrop click vs button click — propagation może zamknąć modal nawet po Buy click | MouseFilter na ModalBox = STOP, na Backdrop = STOP też. Buttony wewnątrz modalbox blokują propagację |
| Test #4 wymaga że purchase_shop emituje shop_purchased SYNC (in-frame) — jeśli queued → spy nie złapie | Sprawdź GameState.purchase_shop — to direct emit (linia 162), sync. OK |
| 11 testów = długi runtime — może > 10s w headless | Acceptable. Optimize tylko jeśli > 30s |

## Acceptance criteria

- [ ] `godot --headless --script tests/ShopUpgradeModalTest.gd --path .` → 11/11 PASS
- [ ] `godot --headless --quit-after 5 --path .` → zero ERROR / SCRIPT
- [ ] F5 manual smoke: tap empty Fashion → buy → owned; tap owned → upgrade → level++
- [ ] Insufficient funds wizualnie blokuje Buy
- [ ] Backdrop tap zamyka modal
- [ ] Tylko jeden modal aktywny naraz (drugi tap ignorowany)
- [ ] `gdlint scripts/ scenes/ui/` clean
- [ ] Modal nie czyta GameState w `_process`
- [ ] 7 commitów per phase + push

## Handoff to Sonnet

Czytaj: ten plan + `@CLAUDE.md` + `@docs/architecture.md` (sekcje 2 autoloady, 3 EventBus).

Reference: `scenes/city/CityView.gd` (subscribuje EventBus pattern), `scenes/ui/HUD.gd` (initial snapshot pattern z 002), `tests/CityViewTest.gd` + `tests/HUDTest.gd` (custom runner).

**Kluczowe**: różnica między `purchase_cost` (unlock z shops.json — pierwszy zakup) a `upgrade_cost` (formula z EconomyManager — kolejne levele). Modal MUSI wybrać property w zależności od `state` param.

Ważne: `ModalController` to NOWY autoload — w `project.godot` dodaj **na końcu** sekcji `[autoload]`, żeby EventBus był wcześniej zainicjalizowany.

Po wszystkich commitach: zaktualizuj Status na górze tego pliku do `[x] DONE`.
