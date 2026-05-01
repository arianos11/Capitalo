# Plan 005 — Tutorial first-run

**Milestone**: M1 Sprint 1 (Foundation)
**Author**: Opus (planning)
**Implementer**: Sonnet (executing)
**Status**: ready for implementation
**Estimated complexity**: S (~1.5h Sonnet session)

---

## Goal

Pojedyncza pierwsza wskazówka FTUE: "**Tap the shop to buy your first store!**" wyświetlana nad pierwszym pustym slotem (Fashion) gdy gracz ma świeży save (`tutorial_completed["first_shop"] != true`). Dismiss = pierwszy `EventBus.shop_purchased` lub `shop_slot_tapped`. Persist w save → nigdy nie pokaż drugi raz.

Scope minimalistyczny — to jest **placeholder FTUE**. Pełny interaktywny tutorial system (kontekstowe hints krok-po-kroku przez całą grę) to M5 deliverable.

## Out of scope

- Multi-step tutorial (M5)
- Animowana strzałka pulsująca → tap target (M5 polish)
- Hint dla campaigns / managers / tech tree (M5)
- Skip Tutorial button (na M1 hint i tak auto-dismiss przy pierwszym tap)
- Voice over / narrator (Phase 4)
- Tutorial reset z Settings (M5 — gdy będzie Settings ekran)

## Files to create

| Plik | Rola |
|---|---|
| `scenes/ui/TutorialOverlay.tscn` | Control: dim semi-transparent backdrop + Label hint + opcjonalny pointer |
| `scenes/ui/TutorialOverlay.gd` | Setup hint text + target slot pos, listen to EventBus dla dismiss, free self |
| `scripts/autoload/TutorialController.gd` | NOWY autoload: na `EventBus.game_loaded` sprawdza tutorial state, instantiate overlay jeśli not done |
| `tests/TutorialControllerTest.gd` | Headless: fresh save → overlay shown; mark done → no overlay; tap → dismiss |

## Files to modify

| Plik | Zmiana |
|---|---|
| `scripts/autoload/GameState.gd` | Dodaj `var tutorial_completed: Dictionary = {}` (key=tutorial_id, val=true). Dorzuć do `to_dict()` AND `from_dict()` z fallbackiem `{}` |
| `scripts/autoload/EventBus.gd` | Dodaj sygnały `tutorial_step_shown(step_id: String)` i `tutorial_step_completed(step_id: String)` w sekcji `## UI SIGNALS` |
| `project.godot` | Dodaj `TutorialController="*res://scripts/autoload/TutorialController.gd"` na końcu `[autoload]` (po ModalController) |
| `scenes/main/Main.tscn` | Dodaj `TutorialLayer` CanvasLayer (layer=15, nad ModalLayer 10) — tutorial overlay nad wszystkim |
| `docs/roadmap.md` | Po impl: `[x]` przy "**Tutorial first-run** — 'Tap the shop to buy your first store!'" |

## Architecture notes

### Komunikacja
- `SaveSystem.load_game()` → `GameState.from_dict()` → `EventBus.game_loaded.emit()` (już istnieje)
- `TutorialController._on_game_loaded()`:
  - if `GameState.tutorial_completed.get("first_shop", false) == true` → return (już ukończone)
  - if `not GameState.shops.is_empty()` → mark completed (gracz już ma sklep, tutorial obsolete) + return
  - else: instantiate `TutorialOverlay`, setup z target_shop_id="fashion", add do `Main/TutorialLayer`
- Overlay subscribes:
  - `EventBus.shop_purchased` → if first time, mark `tutorial_completed["first_shop"] = true`, save (force flush via `SaveSystem.save_game()`), `queue_free()`
  - `EventBus.shop_slot_tapped` → mark completed + queue_free (gracz wie co robić, hint speł funkcję)
- Overlay sam emituje `EventBus.tutorial_step_shown("first_shop")` w `_ready` i `tutorial_step_completed("first_shop")` przed `queue_free`

### Ważne: save flush
Po `tutorial_completed["first_shop"] = true` MUSI być natychmiastowy save (nie tylko `is_dirty = true`). Inaczej crash gry przed auto-save 30s = tutorial pokaże się znowu. Wywołaj `SaveSystem.save_game()` directly.

### Layout (portrait 1080x1920)
- Root Control full-rect, `mouse_filter = MOUSE_FILTER_IGNORE` (pozwala tap przejść do ShopSlot)
- Backdrop: ColorRect full-screen, color (0,0,0,0.4), `mouse_filter = IGNORE`
- HintBox: PanelContainer 800x200, anchored center-top (np. y=400, nad Fashion slot z 001 layout)
  - Inside: VBox z Label "Tap the shop to buy your first store!" (font ~36, wrap)
- Pointer (optional): Polygon2D / Sprite2D arrow pointing down → Fashion slot (y~600). Jeśli za skomplikowane → skip, sam tekst wystarczy
- Pulsing animation na HintBox: subtle scale 1.0 ↔ 1.05 over 1s loop (visual attractor)

### Persistence pattern (przykład w GameState.gd)
```gdscript
# Add field
var tutorial_completed: Dictionary = {}

# In to_dict():
"tutorial_completed": tutorial_completed,

# In from_dict():
tutorial_completed = data.get("tutorial_completed", {})
```
Per `architecture.md` §5 — symetria to_dict/from_dict, fallback default.

### Autoload order
```
[autoload]
EventBus=...
GameState=...
SaveSystem=...
EconomyManager=...
CampaignSystem=...
AudioManager=...
ModalController=...
TutorialController=...   # NEW, na końcu — wszystko inne musi być ready
```

## Test cases (TDD)

`tests/TutorialControllerTest.gd`:

1. **test_overlay_shown_on_fresh_save** — fresh GameState (tutorial_completed={}, shops={}), emit `EventBus.game_loaded` → expect TutorialOverlay w drzewie scenicznym
2. **test_overlay_not_shown_when_completed** — set `GameState.tutorial_completed["first_shop"] = true`, emit `game_loaded` → expect no overlay
3. **test_overlay_not_shown_when_shops_already_owned** — fresh tutorial state ale `GameState.shops = {"fashion": {level: 1}}`, emit `game_loaded` → expect no overlay (gracz już ma sklep, hint obsolete)
4. **test_overlay_dismisses_on_shop_purchased** — overlay shown, emit `EventBus.shop_purchased.emit("fashion")` → expect overlay queue_free'd, `GameState.tutorial_completed["first_shop"] == true`
5. **test_overlay_dismisses_on_shop_slot_tapped** — overlay shown, emit `shop_slot_tapped("fashion", "empty")` → expect dismissed
6. **test_save_flushed_on_completion** — overlay shown, emit shop_purchased, expect SaveSystem.save_game() called (lub equivalent — sprawdź że file na disku ma `tutorial_completed.first_shop == true`)
7. **test_to_dict_from_dict_round_trip** — set tutorial_completed = {"first_shop": true}, call to_dict(), pass result do from_dict() na fresh GameState, expect tutorial_completed equal
8. **test_emits_tutorial_signals** — overlay shown → expect `tutorial_step_shown("first_shop")` emitted; dismissed → expect `tutorial_step_completed("first_shop")`

Reuse `tests/_helpers/SignalSpy.gd`.

## Phase-by-phase

### Phase A — GameState field + EventBus signals + tests skeleton (20 min)
1. Edit `scripts/autoload/GameState.gd`:
   - Add `var tutorial_completed: Dictionary = {}` w sekcji state
   - Add do `to_dict()`: `"tutorial_completed": tutorial_completed`
   - Add do `from_dict()`: `tutorial_completed = data.get("tutorial_completed", {})`
2. Edit `scripts/autoload/EventBus.gd`:
   - Add `signal tutorial_step_shown(step_id)` w UI section
   - Add `signal tutorial_step_completed(step_id)` w UI section
3. Create `tests/TutorialControllerTest.gd` z 8 testami fail (TutorialController + Overlay not yet exist)
4. Run tests → expect failures
5. Run all existing tests → expect zero regressions (GameState dict change ne wywala save)
6. **Commit**: `feat(state): add tutorial_completed dict + tutorial signals

Save symmetry to_dict/from_dict updated. Two new EventBus signals
for tutorial step lifecycle.`

### Phase B — TutorialOverlay scene + script (40 min)
1. `scenes/ui/TutorialOverlay.tscn` per layout spec
2. `scenes/ui/TutorialOverlay.gd`:
   - `setup(step_id: String, hint_text: String)` — set Label, store step_id
   - `_ready()` — subscribe `EventBus.shop_purchased`, `shop_slot_tapped`. emit `tutorial_step_shown`. start pulsing tween
   - `_dismiss()` — mark `GameState.tutorial_completed[step_id] = true`, force `SaveSystem.save_game()`, emit `tutorial_step_completed`, queue_free
   - `_exit_tree()` cleanup signal connections
3. **Commit**: `feat(tutorial): add TutorialOverlay scene with dismiss-on-action`

### Phase C — TutorialController autoload (25 min)
1. `scripts/autoload/TutorialController.gd`:
   - `_ready()` — `EventBus.game_loaded.connect(_on_game_loaded)`
   - `_on_game_loaded()` — guard logic (already done? has shops?), if eligible: instantiate overlay, find Main/TutorialLayer, add_child, setup with "first_shop" + hint string
2. `project.godot` — register autoload na końcu `[autoload]`
3. `Main.tscn` — add `TutorialLayer` CanvasLayer (layer=15)
4. **Commit**: `feat(tutorial): add TutorialController autoload + TutorialLayer`

### Phase D — pass tests + lint (15 min)
1. Run `tests/TutorialControllerTest.gd` → fix wszystkie 8 PASS
2. Run all previous tests (CityView, HUD, Modal, FloatingNumbers) → zero regressions
3. `gdlint scripts/ scenes/ui/` clean
4. `godot --headless --quit-after 5 --path .` zero ERROR/SCRIPT
5. **Commit**: `test(tutorial): all 8 tests passing`

### Phase E — manual smoke (5 min)
1. **Delete save**: `rm ~/Library/Application\ Support/Godot/app_userdata/Capitalo/savegame.json` (macOS path)
2. F5 w editor — overlay powinien wyskoczyć z hintem nad Fashion
3. Tap Fashion → modal otwiera się (z 003), overlay znika
4. Po Buy → tutorial completed, save flushed
5. Restart F5 — overlay NIE pokazuje się drugi raz
6. **Brak commitu**

### Phase F — roadmap update
1. Mark `[x]` przy "**Tutorial first-run** — 'Tap the shop to buy your first store!'"
2. **Commit**: `docs(roadmap): mark Tutorial first-run complete`

### Phase G — plan DONE marker
1. Edit `docs/plans/005-tutorial-first-run.md` Status → `[x] DONE`
2. **Commit**: `docs(plans): mark 005-tutorial-first-run done`

## Risks

| Risk | Mitigation |
|---|---|
| Overlay backdrop blokuje tap → ShopSlot nie reaguje → infinite tutorial | `mouse_filter = MOUSE_FILTER_IGNORE` na backdrop AND root Control. Test #5 verifies tap signal still fires |
| `EventBus.game_loaded` emitowany przed Main.tscn ready (autoloady wcześniejsze) → TutorialLayer not yet exist gdy try add_child | TutorialController używa `call_deferred("_on_game_loaded")` lub `await get_tree().process_frame` przed add_child żeby Main scene ready |
| `SaveSystem.save_game()` na disk write w trakcie game session = potential lag spike | Acceptable — once-per-game-lifetime event, użytkownik nie zauważy 50ms |
| Test #6 (save flushed) wymaga prawdziwego file write w teście — FileAccess wymaga Godot runtime | Headless test może zapisać do `user://test_save.json`, czytać z powrotem. Lub mock SaveSystem.save_game z spy. Wybierz spy approach (cleaner) |
| Tutorial overlay z 003 ModalController concurrent — który ma priorytet wizualnie? | Layer 15 (tutorial) > Layer 10 (modal) — overlay nad modalem. ALE: jeśli overlay aktywny i user tapnie slot → modal otwiera się + overlay dismiss równocześnie. Race acceptable (oba dispatch przez EventBus, ordering deterministic) |
| Pulsing tween + queue_free = warning "tween was running on freed object" | `_exit_tree()` powinno `tween.kill()` jeśli tween still active |
| GameState `to_dict` change → stary save pre-tutorial nie ma `tutorial_completed` field → from_dict get z fallbackiem `{}` → overlay shown for returning player | Acceptable — returning player z brakującym fieldem nie skończył tutoriala (per definicji), pokażemy go raz. Edge case: returning player który MA shops ale brakuje fieldu → guard `if not shops.is_empty()` w controllerze chroni |

## Acceptance criteria

- [ ] `godot --headless --script tests/TutorialControllerTest.gd --path .` → 8/8 PASS
- [ ] Wszystkie poprzednie testy (CityView, HUD, Modal, FloatingNumbers) nadal PASS
- [ ] `godot --headless --quit-after 5 --path .` zero ERROR/SCRIPT
- [ ] F5 manual: fresh save → overlay; tap Fashion → modal opens AND overlay dismisses; restart → no overlay
- [ ] Save plik na disku po dismiss zawiera `"tutorial_completed": {"first_shop": true}`
- [ ] Backdrop NIE blokuje tap propagation (test #5 + manual verifies)
- [ ] `gdlint` clean
- [ ] 7 commitów per phase + push

## Handoff to Sonnet

Czytaj: ten plan + `@CLAUDE.md` + `@docs/architecture.md` (sekcja 5 Save versioning — symetria to_dict/from_dict).

Reference: `scripts/autoload/ModalController.gd` (z 003) — TutorialController = ten sam pattern (autoload subscribuje sygnał, instantiate overlay scene). `scripts/autoload/SaveSystem.gd` — sprawdź signature `save_game()`.

**Kluczowe**:
- **Save symmetry**: jeśli zapomnisz `to_dict`/`from_dict` aktualizacji = silent save corruption. Test #7 weryfikuje, ale podwójnie sprawdź sam diff.
- **mouse_filter**: backdrop MUSI być IGNORE inaczej tutorial blokuje gameplay.
- **call_deferred dla add_child**: Main scene może nie być w pełni ready gdy `game_loaded` emit. Defer.

Po wszystkich commitach: zaktualizuj Status do `[x] DONE`.
