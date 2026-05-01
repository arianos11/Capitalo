# Plan 004 — Floating numbers (object pool)

**Milestone**: M1 Sprint 1 (Foundation)
**Author**: Opus (planning)
**Implementer**: Sonnet (executing)
**Status**: [x] DONE
**Estimated complexity**: M (~2h Sonnet session)
**Performance budget**: pool of 30 reusable Labels (per architecture.md §7)

---

## Goal

Visible feedback per income tick: "+$1.23K" Label floating up + fading out nad każdym sklepem co tick (10 Hz). Object pool 30 reusable Labels w `FloatingNumberLayer` (CanvasLayer w Main). Zero allocations w hot path. Subscribuje nowy sygnał `EventBus.shop_earned(shop_id, amount)` który EconomyManager musi zacząć emitować per-shop.

## Out of scope

- Particles dla viral hits (M2 — VIRAL HIT screen shake + particles, osobny system)
- Floating numbers dla campaign payouts (M2)
- Combo/multiplier visual flair (Phase 2 polish)
- Color-coded numbers (positive zielony, drain czerwony) — wszystko zielone w M1
- Sound per floating number (osobny audio task)
- Localization formatu liczb (Phase 3)

## Files to create

| Plik | Rola |
|---|---|
| `scenes/ui/FloatingNumberLayer.tscn` | CanvasLayer (layer=5) z 30 pre-instantiated Labels jako children, all hidden |
| `scenes/ui/FloatingNumberLayer.gd` | Object pool, subscribe shop_earned, query ShopSlot positions, animate via Tween |
| `tests/FloatingNumberLayerTest.gd` | Headless: emit shop_earned → label appears, multiple emits → pool recycles, max 30 alive |

## Files to modify

| Plik | Zmiana |
|---|---|
| `scripts/autoload/EconomyManager.gd` | W `_process_income_tick`: po `GameState.add_money(income_this_tick)` dodaj loop emit `EventBus.shop_earned(shop_id, per_shop_amount)` per posiadany sklep |
| `scenes/city/ShopSlot.gd` | Dodaj `add_to_group("shop_slots")` w `_ready()` + property `shop_id` (jeśli już istnieje, zostaw) — żeby Layer mógł znaleźć slot po id |
| `scenes/main/Main.tscn` | Instantiate `FloatingNumberLayer.tscn` jako sibling do `ModalLayer` (z 003) i `UI`. Layer index=5 (pod modalem layer=10, nad UI layer=1) |
| `scripts/autoload/EventBus.gd` | (sygnał `shop_earned(shop_id, amount)` JUŻ istnieje, line 30 — używaj) |
| `docs/roadmap.md` | Po impl: `[x]` przy "**Floating numbers** — pool 30 reusable labels" w M1 |

## Architecture notes

### Komunikacja
- EconomyManager tick (10 Hz) → loop owned shops → emit `EventBus.shop_earned(shop_id, per_shop_income)`
- FloatingNumberLayer subscribes `EventBus.shop_earned` → finds ShopSlot via group → spawn label
- ShopSlot zarejestrowany w grupie `shop_slots` z property `shop_id: String`
- Layer query: `for slot in get_tree().get_nodes_in_group("shop_slots"): if slot.shop_id == id: pos = slot.global_position + offset; break`
- Pool: array 30 Labels, każdy ma `_busy: bool` flag. Find idle, mark busy, animate, on Tween finish → mark idle + hide
- **Drop strategy**: jeśli pool full (wszystkie busy) → silently drop (nie spawn). 30 @ 10Hz @ 1.2s lifetime = max 36 concurrent dla 3 shopów; budget = 30 → 17% drop rate worst case w M1, OK na placeholder

### EconomyManager refactor (precyzyjnie)
```gdscript
func _process_income_tick(tick_seconds: float) -> void:
    var total_ips = get_total_income_per_second()
    if total_ips.is_zero():
        return

    var income_this_tick = total_ips.multiply_by_float(tick_seconds)
    GameState.add_money(income_this_tick)

    # NEW: per-shop emit dla floating numbers
    for shop_id in GameState.shops.keys():
        var shop_ips = calculate_shop_income(shop_id)
        if shop_ips.is_zero():
            continue
        var shop_tick_income = shop_ips.multiply_by_float(tick_seconds)
        EventBus.shop_earned.emit(shop_id, shop_tick_income)
```

**Performance check**: 3 sklepy * 10 Hz = 30 emits/sec — trivial.
**Cache reuse**: `calculate_shop_income(shop_id)` powinien być cached jeśli możliwe, sprawdź czy jest. Jeśli nie, OK na M1 (3 shopów).

### Animation
- Spawn position: `slot.global_position + Vector2(slot.size.x / 2, -20)` (środek slotu, lekko nad)
- Tween: `position.y -= 100` over 1.2s, easing `EASE_OUT`
- Tween parallel: `modulate.a` 1.0 → 0.0 over 1.2s, linear
- On finish: `label.visible = false`, `label._busy = false`
- Font size ~40, color zielony `#7FFF00` (lime), bold jeśli możliwe
- Z-order: Layer ma `layer=5` w Main scene (nad UI layer 1, pod ModalLayer layer 10)

### Pool initialization
- `_ready()`: pre-instantiate 30 Labels jako children layeru, wszystkie `visible=false`
- Każdy Label custom property `_busy: bool = false`
- `_pool_index: int = 0` — round-robin start point dla `_get_idle_label()`
- `_get_idle_label() -> Label`: scan from `_pool_index`, return first `not _busy`, or `null` jeśli wszystkie busy

### Group pattern
- `ShopSlot._ready()`: `add_to_group("shop_slots")`
- `ShopSlot` ma `shop_id` jako member var (powinno być z 001, sprawdź)
- Layer nie cache'uje listy slotów — query za każdym razem (overhead trivial dla 3 nodów)
- Unsubscribe nie potrzebne (group cleanup automatic)

## Test cases (TDD)

`tests/FloatingNumberLayerTest.gd`:

1. **test_pool_initialized_with_30_labels** — instantiate layer, expect `get_children().size() >= 30` (Label nodes), wszystkie `visible == false`
2. **test_shop_earned_spawns_label** — mock ShopSlot z shop_id="fashion" w grupie + global_position znanej, emit `shop_earned("fashion", BigNumber.from_float(123.0))`, expect dokładnie 1 label visible z text "+$123.00"
3. **test_label_position_matches_slot** — emit, expect spawned label.global_position == slot.global_position + offset (tolerance ±5px)
4. **test_pool_recycles_after_animation** — emit, await 1.5s (Tween done), emit again, expect tylko 1 label visible (recycled)
5. **test_pool_drops_when_full** — spawn 30 mock ShopSlots z różnymi ids, emit shop_earned 35 razy w jednej klatce, expect <= 30 labels visible (silent drop)
6. **test_unknown_shop_id_no_spawn** — emit z shop_id="nonexistent" (brak slotu w grupie), expect 0 labels visible (no crash)
7. **test_format_uses_formatters** — emit z amount=1500000.0, expect label.text == "+$1.50M" (z `Formatters.format_money`, prefix "+")
8. **test_zero_amount_no_spawn** — emit z BigNumber.from_float(0), expect 0 labels (skip degenerate case)
9. **test_label_fades_to_invisible** — emit, manually advance Tween do końca via `await tween.finished`, expect label.modulate.a == 0.0
10. **test_economy_tick_emits_per_shop** — mock GameState z 2 owned shops, advance fake time 0.1s przez `EconomyManager._process_income_tick(0.1)`, SignalSpy expect 2 emits `shop_earned` (jeden per shop)

Reuse `tests/_helpers/SignalSpy.gd`. Test #5 i #10 wymagają creative setup — może mock GameState.shops = {"a":{level:1}, "b":{level:1}} bez używania purchase flow.

## Phase-by-phase

### Phase A — EconomyManager refactor + tests skeleton (25 min)
1. Edit `scripts/autoload/EconomyManager.gd` — dodaj per-shop emit w `_process_income_tick`
2. Quick verify: `godot --headless --quit-after 5 --path .` → no parse errors
3. Create `tests/FloatingNumberLayerTest.gd` z 10 testami fail (FloatingNumberLayer not yet exist)
4. Run tests → expect failures (też test #10 bo tests EconomyManager już rebuilt)
5. **Commit**: `feat(economy): emit shop_earned per shop on income tick

Prerequisite for floating number visualization. Adds 3 emits/sec
overhead in M1 (3 shops). EconomyManager._process_income_tick now
loops owned shops post add_money to fire EventBus.shop_earned.`

### Phase B — FloatingNumberLayer scene + script (50 min)
1. `scenes/ui/FloatingNumberLayer.tscn` — CanvasLayer root (layer=5), 30 Label children pre-created (lub instantiate w script `_ready`)
   - Decision: tworzyć w script (`_ready` dynamic) — łatwiej zmienić count, mniej noise w .tscn
2. `scenes/ui/FloatingNumberLayer.gd`:
   - `const POOL_SIZE = 30`
   - `_pool: Array[Label] = []`, `_busy: Array[bool] = []`, `_pool_index: int = 0`
   - `_ready()` — create 30 Labels z font/color/size, hide, append do pool, subscribe `EventBus.shop_earned`
   - `_on_shop_earned(shop_id, amount)` — find slot, get idle label, position, animate
   - `_get_idle_label() -> int` — return index lub -1
   - `_animate_label(idx, start_pos, text)` — Tween position+modulate, on finish unset busy
3. **Commit**: `feat(floating-numbers): add FloatingNumberLayer with object pool`

### Phase C — ShopSlot group registration (15 min)
1. `scenes/city/ShopSlot.gd` — w `_ready()` dodaj `add_to_group("shop_slots")`
2. Sprawdź czy `shop_id` to var member (powinno z 001 — verify)
3. Run CityView tests — should still pass (nothing broken)
4. **Commit**: `feat(cityview): register ShopSlot in shop_slots group for queries`

### Phase D — wire FloatingNumberLayer w Main (10 min)
1. `Main.tscn` — instantiate `FloatingNumberLayer.tscn` jako sibling UI/ModalLayer
2. Layer index 5 (pod modalem 10, nad UI 1)
3. **Commit**: `feat(main): wire FloatingNumberLayer into Main scene`

### Phase E — pass tests + lint (25 min)
1. Run `tests/FloatingNumberLayerTest.gd` → fix wszystkie 10 PASS
2. Run `tests/CityViewTest.gd` + `tests/HUDTest.gd` + `tests/ShopUpgradeModalTest.gd` (z 003 jeśli już done) → expect zero regressions
3. `gdlint scripts/ scenes/ui/ scenes/city/` clean
4. `godot --headless --quit-after 5 --path .` zero ERROR/SCRIPT
5. **Commit**: `test(floating-numbers): all 10 tests passing`

### Phase F — manual smoke (5 min)
1. F5 w editor
2. Tap Fashion empty → buy via modal (z 003) → ZA SEKUNDĘ powinny lecieć "+$X" znad Fashion slotu co tick (10/sec)
3. Buy 2nd shop → numbers nad obu
4. Spam DEBUG +$1000 NIE powinno spawnować floating numbers (to inny path, money_changed ≠ shop_earned)
5. **Brak commitu**

### Phase G — roadmap update
1. Mark `[x]` przy "**Floating numbers** — pool 30 reusable labels"
2. **Commit**: `docs(roadmap): mark Floating numbers complete`

### Phase H — plan DONE marker
1. Edit `docs/plans/004-floating-numbers.md` Status → `[x] DONE`
2. **Commit**: `docs(plans): mark 004-floating-numbers done`

## Risks

| Risk | Mitigation |
|---|---|
| Per-shop emit zwiększa CPU w tick — przy 10 sklepach (Phase 2) = 100 emits/sec | Acceptable do Phase 2 (10 shops max). Phase 3+ batch emit jako Dict |
| `calculate_shop_income(shop_id)` wywołane 2x na tick (raz w get_total + raz w nowej pętli) — wasted work | Faktycznie, redundant. Optimize: w `_process_income_tick` zbieraj per-shop incomes do Dict podczas pierwszej iteracji w `get_total_income_per_second`. Ale to refactor scope poza ten plan. M1 OK z 2x calc — 3 shops, no big deal. Note dla Phase 2 |
| ShopSlot.global_position może być (0,0) jeśli scena nie była rendered | `_ready()` order: ShopSlot._ready przed FloatingLayer może not work jeśli layer instantiated wcześniej. Mitigation: query positions ON-DEMAND w `_on_shop_earned` (after first frame guaranteed) |
| Tween gymastics — Godot 4 Tween API: `create_tween().tween_property(label, "position:y", target, duration)` — sprawdź exact syntax | Godot 4 Tween jest stable, zobacz docs. Kill old tween przed nowym dla recycled label żeby nie nakładać |
| Test #5 (pool drops) wymaga 30 mock slots — overkill | Replace test #5 z prostszym: emit 35 razy bez sleep, count visible labels, expect == 30 (i 5 dropped). Mock tylko 1 shop |
| Pool recycle bug — busy flag set false przed Tween rzeczywiście umiera | Use `tween.finished.connect(...)` callback, nie `await` w `_on_shop_earned` (block path) |
| `EventBus.shop_earned` parametr typing — sygnał deklarowany jako `shop_earned(shop_id, amount)` bez typów. BigNumber jako amount, ale signal nie type-check | OK, GDScript sygnały untyped pass-through. Receiver typuje params w handler signature |

## Acceptance criteria

- [ ] `godot --headless --script tests/FloatingNumberLayerTest.gd --path .` → 10/10 PASS
- [ ] Wszystkie poprzednie testy (CityView, HUD, BigNumber, ShopUpgradeModal jeśli 003 done) nadal PASS — zero regressions
- [ ] `godot --headless --quit-after 5 --path .` zero ERROR/SCRIPT
- [ ] F5 manual: kup Fashion → "+$X" floating co tick (10/sec) nad slotem przez ~1.2s każdy
- [ ] Pool max 30 alive — visualnie spróbuj spam (kup wszystkie 3, czekaj kilka sek) → no crash, no warning, smooth
- [ ] `gdlint scripts/ scenes/ui/ scenes/city/` clean
- [ ] FloatingNumberLayer nie czyta GameState bezpośrednio (tylko via EventBus.shop_earned param)
- [ ] EconomyManager change is minimal — tylko dodanie loop, no API break

## Handoff to Sonnet

Czytaj: ten plan + `@CLAUDE.md` + `@docs/architecture.md` (sekcje 4 BigNumber, 7 Performance budget — tam jest "Floating numbers pool of 30 reusable labels").

Reference: `scenes/city/CityView.gd` (group queries pattern jeśli używa), `scripts/autoload/EconomyManager.gd` (tick loop), `scripts/utils/Formatters.gd` (`format_money` API).

**Kluczowe**: object pool MUSI recycle. Jeśli stworzysz 30 labels i nie zwolnisz busy flag po Tween → po sekundzie wszystko stuck. Test #4 weryfikuje to.

**Animation**: użyj Godot 4 `create_tween()` — nie stary `Tween` node z Godot 3.

**Pool full**: silent drop, NIE crash, NIE warning (spam). To normalny stan przy heavy income.

Po wszystkich commitach: zaktualizuj Status na górze do `[x] DONE`.
