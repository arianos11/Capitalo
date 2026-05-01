# Plan 006 — Save round-trip integration test

**Milestone**: M1 Sprint 1 (Foundation)
**Author**: Opus (planning)
**Implementer**: Sonnet (executing)
**Status**: ready for implementation
**Estimated complexity**: S (~1h Sonnet session)
**Type**: pure test deliverable, **zero new game code**

---

## Goal

Comprehensive integration test który dowodzi, że **wszystko** co GameState trzyma round-trip'uje przez `save_game()` → file → `load_game()` → equal state. Pisze realne pliki na disku (do izolowanych ścieżek `user://test_*.json`), nie mockuje SaveSystem. Cel: złapać silent save corruption (zapomniany field w `to_dict`/`from_dict`) PRZED wypchnięciem do gracza.

To również pierwszy plan który **nie tworzy żadnego game code** — tylko testy. Pattern dla future regression suites.

## Out of scope

- Save format migration testing (SAVE_VERSION = 1, brak v2 do testowania)
- Cloud save (Phase 4)
- Compressed save (Phase 4)
- Encrypted save (anti-cheat — Phase 4 jeśli w ogóle)
- Concurrent save corruption simulation (out of scope dla M1)
- Performance benchmarks save speed (Phase 2)

## Files to create

| Plik | Rola |
|---|---|
| `tests/SaveRoundTripTest.gd` | Integration test: write → read → assert equal across all GameState fields |
| `tests/_helpers/SaveTestFixture.gd` | Helper: builds maximal "loaded" GameState (every field touched), cleanup after |

## Files to modify

| Plik | Zmiana |
|---|---|
| `docs/roadmap.md` | Po impl: `[x]` przy "**Save round-trip test** — quit → reopen → kasa + sklepy zachowane" |

**Brak zmian w game code.** Jeśli test odkrywa bug → osobny plan/commit z fix, nie w tym planie.

## Architecture notes

### Test isolation
- Test używa custom paths NIE `user://savegame.json` — żeby nie zepsuć dev save
- Override SaveSystem paths via temp constants:
  - `SaveSystem.SAVE_FILE_PATH` to const → nie da się override w runtime czysto
  - **Workaround**: test direct używa `FileAccess` na `user://test_save_roundtrip.json`, woła `JSON.stringify(GameState.to_dict())` ręcznie, czyta z powrotem, woła `GameState.from_dict()`
  - **Alternatywa**: stworzyć `SaveSystem.save_to_path(path)` / `load_from_path(path)` jako test seam
  - **Decyzja**: workaround direct (nie zmieniaj SaveSystem dla testu — to plan #006 ma zero game code change)

### Test scope per field
Każdy field z `GameState.to_dict()` MUSI mieć assertion w teście. Aktualnie (sprawdź w runtime — pole może się rozrosnąć po 005):
- `version: int = 1`
- `money: BigNumber` (nested dict)
- `innovation_points: int`
- `prestige_count: int`
- `prestige_multiplier: float`
- `reputation: int`
- `shops: Dictionary` (nested per shop_id)
- `managers: Dictionary` (nested per manager_id)
- `unlocked_tech: Array[String]`
- `campaign_cooldowns: Dictionary`
- `total_campaigns_launched: int`
- `total_viral_hits: int`
- `last_save_timestamp: float`
- `total_play_time_seconds: float`
- `tutorial_completed: Dictionary` (z 005)

**Auto-discovery**: test może iterować `GameState.to_dict().keys()` i assertować że każdy klucz jest > 0 znaków + present po round-trip. Bardziej defensive niż hardcode listy.

### BigNumber round-trip critical
- `money` to `BigNumber` z `to_dict() / from_dict()` własnym
- Test musi assertować `loaded_money.equals(original_money)` (semantic equal), NIE `loaded_money == original_money` (reference)
- Edge cases: zero, very small (0.001), very large (1e60+), negative (jeśli możliwe — sprawdź czy GameState pozwala)

### Cleanup
- Test `_run_tests()` start: delete test files jeśli istnieją
- Test exit (sukces lub fail): delete test files
- Użyj `try/finally`-equivalent w GDScript: helper z `_cleanup()` w `_exit_tree()`

## Test cases

`tests/SaveRoundTripTest.gd`:

1. **test_empty_state_roundtrip** — fresh GameState, save → load → all fields == default values
2. **test_money_roundtrip** — set money to BigNumber.from_float(123456.789), save → load → loaded.equals(original)
3. **test_money_huge_roundtrip** — set money to BigNumber.new(9.99, 308), save → load → loaded.equals(original) (test mantissa precision near float ceiling)
4. **test_money_zero_roundtrip** — set money to BigNumber.from_float(0), save → load → equals zero
5. **test_shops_roundtrip** — purchase fashion+tech, upgrade fashion to lvl 5, save → load → both shops present z correct levels
6. **test_managers_roundtrip** — hire manager, save → load → manager present z correct level + assignment
7. **test_tech_roundtrip** — `unlocked_tech.append_array(["mkt_node_1", "mkt_node_2"])`, save → load → array equal
8. **test_campaigns_state_roundtrip** — set campaign_cooldowns + counters, save → load → equal
9. **test_tutorial_completed_roundtrip** — set tutorial_completed = {"first_shop": true, "first_campaign": true}, save → load → dict equal (z 005)
10. **test_timestamps_roundtrip** — set last_save_timestamp + total_play_time_seconds to known float, save → load → equal (within 0.001 tolerance)
11. **test_all_fields_present_after_roundtrip** — call to_dict, save, load, call to_dict again, assert key sets equal (catches typo'd fields)
12. **test_corrupted_json_falls_back_to_backup** — write valid save, copy to backup, write garbage to save, load_from_path → expect _load_from_backup invoked, state restored
13. **test_missing_file_returns_false** — delete file, load → returns false, no crash
14. **test_partial_dict_uses_defaults** — write JSON z brakiem niektórych keys (np. brak `tutorial_completed`), load → field przyjmuje default `{}`, no crash (regression test dla forward-compat)

Reuse `tests/_helpers/SignalSpy.gd` jeśli potrzebne.

## Phase-by-phase

### Phase A — SaveTestFixture helper (15 min)
1. Create `tests/_helpers/SaveTestFixture.gd`:
   - `class_name SaveTestFixture extends RefCounted`
   - `static func make_maximal_state() -> Dictionary` — zwraca dict z każdym field set do non-default value (do test #11)
   - `static func write_json(path: String, dict: Dictionary)` — helper opakowujący FileAccess
   - `static func read_json(path: String) -> Dictionary` — helper read + parse
   - `static func cleanup_test_files(paths: Array[String])` — delete via DirAccess
2. **Commit**: `test(save): add SaveTestFixture helper for round-trip tests`

### Phase B — Tests #1-10 (basic field round-trips) (40 min)
1. Create `tests/SaveRoundTripTest.gd` z:
   - Custom runner (per CityViewTest pattern)
   - Setup: snapshot GameState defaults via `to_dict()` przed każdym testem
   - Teardown: `GameState.reset_to_defaults()` (sprawdź że ta metoda istnieje!) + cleanup test files
   - Tests #1-10 z listy wyżej
2. Run → expect failures dla testów które wykrywają missing to_dict/from_dict pairs
3. **JEŻELI test failuje na missing field** → STOP, raportuj user, NIE fixuj w tym planie (zero-game-code rule)
4. **Commit**: `test(save): add 10 field-level round-trip tests`

### Phase C — Tests #11-14 (defensive cases) (25 min)
1. Test #11 — auto-discovery key set assertion
2. Test #12 — corrupted JSON + backup fallback (write garbage do main save)
3. Test #13 — missing file
4. Test #14 — partial dict forward-compat
5. Run all 14 → expect PASS
6. **Commit**: `test(save): add corruption + forward-compat tests`

### Phase D — full regression suite + lint (10 min)
1. Run wszystkie testy projektu:
   - `godot --headless --script tests/BigNumberTest.gd --path .`
   - `godot --headless --script tests/CityViewTest.gd --path .`
   - `godot --headless --script tests/HUDTest.gd --path .`
   - `godot --headless --script tests/ShopUpgradeModalTest.gd --path .`
   - `godot --headless --script tests/FloatingNumberLayerTest.gd --path .`
   - `godot --headless --script tests/TutorialControllerTest.gd --path .`
   - `godot --headless --script tests/SaveRoundTripTest.gd --path .`
2. **Wszystkie** musi PASS — to plan walidacyjny, regression = blocker
3. `gdlint tests/` clean
4. **Commit**: `test(save): full regression pass`

### Phase E — manual smoke (5 min)
1. F5 w editor
2. Kup Fashion, upgrade do lvl 3
3. Quit (Cmd+Q lub close window)
4. F5 znowu — kasa + sklep + level zachowane?
5. **Brak commitu**

### Phase F — roadmap update
1. Mark `[x]` przy "**Save round-trip test** — quit → reopen → kasa + sklepy zachowane"
2. **Commit**: `docs(roadmap): mark Save round-trip test complete`

### Phase G — plan DONE marker
1. Edit `docs/plans/006-save-roundtrip-test.md` Status → `[x] DONE`
2. **Commit**: `docs(plans): mark 006-save-roundtrip-test done`

## Risks

| Risk | Mitigation |
|---|---|
| Test odkrywa real bug w `to_dict`/`from_dict` (zapomniany field) | **DOBRZE** — to całe celem testu. STOP, raportuj user, fix w osobnym planie/commitcie poza scope 006. NIE wstaw fix w sam test |
| `GameState.reset_to_defaults()` może nie istnieć — test setup się wywala | Sprawdź na początku Phase B. Jeśli brak, utwórz tymczasowy `_reset_test_state()` w fixture który ustawia każde pole na default ręcznie. NIE dodawaj `reset_to_defaults` do GameState w tym planie (zero game code) |
| Tests dotykają `user://` path — może przeszkadzać dev save jeśli path collision | Use unique prefix `test_save_roundtrip_*` — never overlap z `savegame.json` |
| BigNumber `equals()` może nie istnieć dla tolerance compare — tylko strict equal | Sprawdź BigNumber API. Jeśli brak `equals()` z tolerance, użyj `mantissa_equal_within(other, 1e-9) and exponent == other.exponent` manual |
| Test #12 (corrupted) wymaga manual file write z garbage — pewne że GDScript pozwoli pisać invalid JSON | Tak, `FileAccess.store_string("not json {{{")` works |
| Test #11 auto-discovery może false-positive jeśli `from_dict` przepisuje pole na default ZAMIAST używać saved value | Test #11 mierzy obecność klucza, test #1-10 mierzą wartości. Razem łapią |
| Concurrent autosave timer może odpalić w trakcie testu i zepsuć stan | Test runner powinien set `GameState.is_dirty = false` przed każdym testem żeby autosave nie strzelił. Lub disable autosave: `SaveSystem._autosave_timer = -INF` na start testu |

## Acceptance criteria

- [ ] `godot --headless --script tests/SaveRoundTripTest.gd --path .` → 14/14 PASS
- [ ] Wszystkie poprzednie testy nadal PASS (BigNumber, CityView, HUD, Modal, FloatingNumbers, Tutorial)
- [ ] `godot --headless --quit-after 5 --path .` zero ERROR/SCRIPT
- [ ] `gdlint tests/` clean
- [ ] Test files cleaned up (no `user://test_*.json` po test runie — sprawdź `~/Library/Application Support/Godot/app_userdata/Capitalo/`)
- [ ] **Zero zmian w `scripts/`** — diff to wyłącznie `tests/` + `docs/roadmap.md` + `docs/plans/006-*.md`
- [ ] Manual smoke: kup sklep, quit, restart → state preserved
- [ ] 6 commitów per phase + push

## Handoff to Sonnet

Czytaj: ten plan + `@CLAUDE.md` + `@docs/architecture.md` (sekcja 5 Save versioning, **kluczowe** sekcja "Symetria to_dict/from_dict").

Reference: `tests/CityViewTest.gd` + `tests/HUDTest.gd` + `tests/SaveRoundTripTest.gd` (po napisaniu) — custom runner pattern. `scripts/autoload/SaveSystem.gd` — read API już dostępne (`save_game()`, `load_game()`, `delete_save()`).

**Kluczowe**:
- **NIE zmieniaj game code**. Plan ten jest read-only dla `scripts/`. Jeśli test wykryje bug → STOP i raportuj.
- **Cleanup files** — leftover test JSON w user:// = brzydko. Phase A fixture musi mieć cleanup.
- **Auto-discovery test #11** złapie zapomniane fields w przyszłości (kiedy dorzucisz nowe pola w M2-M5).

Po wszystkich commitach: zaktualizuj Status do `[x] DONE`.
