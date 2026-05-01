# Plan 007 — Offline earnings integration test

**Milestone**: M1 Sprint 1 (Foundation) — **OSTATNI deliverable M1**
**Author**: Opus (planning)
**Implementer**: Sonnet (executing)
**Status**: ready for implementation
**Estimated complexity**: S (~1h Sonnet session)
**Type**: pure test deliverable, **zero new game code** (preferred). Lekka API zmiana w SaveSystem dopuszczalna jeśli niezbędna do testowalności.

---

## Goal

Integration test który dowodzi, że `SaveSystem._handle_offline_earnings()`:
1. Wypłaca earnings = `IPS × elapsed × OFFLINE_EARNINGS_RATE` gdy gracz wraca po Xs
2. Capuje elapsed do `OFFLINE_EARNINGS_CAP_SECONDS` (8h = 28800s)
3. Skipuje gdy `last_save_timestamp <= 0` (pierwsze uruchomienie)
4. Skipuje gdy `elapsed <= 0` (clock skew)
5. Skipuje gdy IPS = 0 (no shops)
6. Emituje `EventBus.offline_earnings_paid(amount, capped_elapsed)`

Wymóg z roadmap M1: "clock +2h → restart → dostań offline earnings". Test pokrywa to + edge cases.

## Out of scope

- UI modal "Welcome back!" — to M5 polish (modal pokazuje wynik test #6 emit)
- Variable rate based on tech tree (Marketing branch może mieć "offline rate +0.1" — M4)
- Push notification 8h before cap (Phase 3)
- Time skew detection / anti-cheat (Phase 3+)
- Real Time mocking — używamy direct field manipulation `GameState.last_save_timestamp`

## Files to create

| Plik | Rola |
|---|---|
| `tests/OfflineEarningsTest.gd` | Integration test: setup shops + IPS + past timestamp → trigger → assert |

## Files to modify

| Plik | Zmiana |
|---|---|
| `scripts/autoload/SaveSystem.gd` | **OPCJONALNIE** dodać `func handle_offline_earnings_for_test() -> void: _handle_offline_earnings()` jako test seam (publiczne wrap). Jeśli można testować via load_game flow → skip ten change |
| `docs/roadmap.md` | Po impl: `[x]` przy "**Offline earnings test** — clock +2h → restart → dostań earnings" |

**Preferred path**: zero zmian w game code. Test wywołuje `_handle_offline_earnings` przez prefix-underscore call (GDScript pozwala — convention only, not enforced).

## Architecture notes

### Test isolation
- Każdy test:
  - Setup: `GameState.reset_to_defaults()` (lub manual reset) → set shops/levels → set IPS
  - Manipulate: `GameState.last_save_timestamp = Time.get_unix_time_from_system() - elapsed_seconds`
  - Trigger: `SaveSystem._handle_offline_earnings()` directly
  - Assert: GameState.money difference, EventBus emit args
  - Teardown: reset
- Brak dotykania disku (test nie używa save_game/load_game flow)

### Expected math (sanity check)
```
elapsed = 3600s (1h)
IPS = 10/sec (3 shops at total $10/sec)
rate = 0.5
expected_earnings = 10 * 3600 * 0.5 = $18,000
```

```
elapsed = 86400s (24h)
capped = 28800s (8h)
IPS = 100/sec
expected = 100 * 28800 * 0.5 = $1,440,000
```

### Mocking IPS
- Real path: purchase shop → upgrade → IPS calculated od level. Wymaga seed shops.json data.
- Test path: mock GameState.shops directly, wywołaj `EconomyManager._invalidate_cache()`, then `EconomyManager.get_total_income_per_second()` zwróci recomputed value
- Lub: bypass całkowicie — test może override IPS query? Nie istnieje hook. Stick to real shops setup.

### EventBus emit verification
- `EventBus.offline_earnings_paid` already exists (sprawdź EventBus.gd)
- SignalSpy connect → trigger → assert spy.count == 1 + args[0] (BigNumber.equals expected_amount) + args[1] (~capped_elapsed)

### Edge cases
- `last_save_timestamp = 0.0` (default) → skip silently, NO emit
- `last_save_timestamp = future` (Time.now + 100) → elapsed negative → skip
- `IPS.is_zero()` → skip silently (no money added, no emit) — `_handle_offline_earnings` ma early return per `if ips.is_zero(): return`
- Cap exactly: elapsed = 28800 → capped = 28800 (exact, no rounding bug)
- Cap exceeded: elapsed = 28800.5 → capped = 28800

## Test cases

`tests/OfflineEarningsTest.gd`:

1. **test_no_save_timestamp_no_earnings** — fresh GameState (last_save_timestamp = 0), trigger → money unchanged, no emit
2. **test_negative_elapsed_no_earnings** — set timestamp = future (now + 100), trigger → money unchanged, no emit
3. **test_zero_ips_no_earnings** — empty shops dict (IPS = 0), set timestamp 1h ago, trigger → money unchanged, no emit
4. **test_one_hour_earnings_correct** — 1 fashion shop lvl 1 (znany IPS z data/shops.json + formula), timestamp 1h ago, trigger → money += IPS * 3600 * 0.5
5. **test_eight_hour_cap_exact** — IPS = 10/sec (mocked via shops), timestamp exactly 8h ago, trigger → money += 10 * 28800 * 0.5 = $144,000, emit cap_seconds == 28800
6. **test_24h_capped_to_8h** — timestamp 24h ago, IPS = 10/sec, trigger → money += same as #5 ($144,000), capped_elapsed arg w emit == 28800 (NIE 86400)
7. **test_emit_offline_earnings_paid** — SignalSpy, trigger z 2h elapsed + IPS=5, expect spy fired exactly once z (BigNumber, 7200.0)
8. **test_short_elapsed_one_second** — timestamp 1s ago, IPS=10, trigger → money += 10*1*0.5 = $5
9. **test_money_uses_bignumber_arithmetic** — IPS = BigNumber(1, 100) (10^100), elapsed 100s → expect money += 10^100 * 100 * 0.5 = 5e101 (no float overflow). BigNumber.equals assertion
10. **test_after_load_game_offline_earnings_applied** — full flow: write save z `last_save_timestamp = now-3600`, then `SaveSystem.load_game()` → expect offline earnings applied (integration test, not unit)
11. **test_no_double_application** — trigger raz, capture money. Trigger znowu z tym samym timestamp → money NIE rośnie drugi raz (czy `_handle_offline_earnings` resetuje timestamp? Sprawdź — jeśli nie, to known issue, oznaczyć test jako TODO/skip)

Reuse `tests/_helpers/SignalSpy.gd`. Może `tests/_helpers/SaveTestFixture.gd` z 006 (jeśli ma reset state helper).

## Phase-by-phase

### Phase A — tests skeleton (15 min)
1. Create `tests/OfflineEarningsTest.gd` z 11 testami custom-runner pattern
2. Stub setup/teardown (reset GameState, clear shops, reset timestamp)
3. Run → expect failures (asserts puste)
4. **Commit**: `test(offline): add OfflineEarningsTest skeleton`

### Phase B — tests #1-3 (negative cases) (15 min)
1. Implement test #1, #2, #3 (skip cases)
2. Run → expect PASS (early returns w `_handle_offline_earnings` powinny działać)
3. **Commit**: `test(offline): cover skip cases (no timestamp / negative elapsed / zero IPS)`

### Phase C — tests #4-9 (math correctness) (30 min)
1. Implement test #4-9
2. Critical helper: `_set_ips_to(value: float)` — set shops dict tak żeby `EconomyManager.get_total_income_per_second()` zwrócił `BigNumber.from_float(value)`. Może wymagać znajomości formuł z shops.json — dla test #4 use real fashion lvl 1 (znamy z data: base_income=1.0, growth=1.07, level=1 → IPS=1.07). Dla pozostałych mock by setting `GameState.shops = {"fashion": {"level": N}}` i compute expected via same formula
2. Run → expect PASS
3. **Commit**: `test(offline): verify earnings math + 8h cap`

### Phase D — tests #10-11 (integration + double-apply) (20 min)
1. Test #10 — write save file z timestamp 1h past, load_game, assert offline earnings applied (uses real disk via SaveSystem flow)
2. Test #11 — double-apply guard. Run trigger twice z tym samym timestamp. Sprawdź czy second trigger no-ops. Jeśli current code aplikuje dwa razy → test fail → STOP, raportuj user (game code bug poza scope 007)
3. Cleanup test files (test #10 użyje `user://savegame.json` — może zniszczyć dev save; mitigation: backup user save przed testem, restore w teardown. Lub use unique path via direct write)
4. Run → expect PASS lub flag known issue
5. **Commit**: `test(offline): integration via load_game + double-apply guard`

### Phase E — full regression + lint (10 min)
1. Run wszystkie testy z 001-006 + 007 → expect zero regressions
2. `gdlint tests/` clean
3. `godot --headless --quit-after 5 --path .` zero ERROR/SCRIPT
4. **Commit**: `test(offline): all 11 tests passing, regression clean`

### Phase F — manual smoke (5 min)
1. F5 — kup Fashion lvl 1, czekaj 30s żeby autosave złapał, quit
2. Zmień zegar systemowy +2h forward (System Settings → Date & Time → unlock → manual)
3. F5 → expect console log "[SaveSystem] Offline earnings: $X over 7200 seconds (capped at 7200)"
4. Cofnij zegar
5. **Brak commitu**

### Phase G — roadmap update (oznacz M1 COMPLETE)
1. Mark `[x]` przy "**Offline earnings test** — clock +2h → restart → dostań earnings"
2. **Sprawdź** czy wszystkie M1 deliverables `[x]` — jeśli tak, dodaj na końcu sekcji M1: `**M1 COMPLETE — date: YYYY-MM-DD**`
3. **Commit**: `docs(roadmap): mark Offline earnings test complete + close M1`

### Phase H — plan DONE marker
1. Edit `docs/plans/007-offline-earnings-test.md` Status → `[x] DONE`
2. **Commit**: `docs(plans): mark 007-offline-earnings-test done`

## Risks

| Risk | Mitigation |
|---|---|
| Test #11 odkrywa że current code aplikuje earnings dwa razy (brak timestamp reset) | **Możliwy real bug**. STOP, raportuj. Mini-plan fix: po `_handle_offline_earnings` ustaw `GameState.last_save_timestamp = Time.get_unix_time_from_system()`. Sprawdź obecny code — może już to robi via `save_game()` po load |
| Test #10 niszczy dev save | Backup user save przed test #10: copy `savegame.json` → `savegame_test_backup.json`, restore w teardown. ALBO override path via test seam (preferred jeśli wprowadzasz `_handle_offline_earnings` overload) |
| Real `Time.get_unix_time_from_system()` różni się między linijkami testu (rzadkie ale możliwe) | Capture `now` raz na początku testu, używaj zmiennej |
| Setting `GameState.shops = {"fashion": {"level": 1}}` nie wystarczy żeby EconomyManager zwrócił correct IPS — trzeba też `_invalidate_cache()` | Wywołaj `EconomyManager._cache_dirty = true` lub publiczny `EconomyManager._invalidate_cache()` przed assertion |
| `_handle_offline_earnings` jest prefix-underscore (private convention). GDScript nie blokuje calla, ale lint może warn | gdlint nie warn'uje na call private z innego pliku w GDScript. Jeśli warn → suppress per-line |
| BigNumber `equals` może mieć tolerance issues dla bardzo małych różnic floats | Phase C tests #4-8 używają round-number IPS (10, 5, 1) → math exact. Tylko test #9 (BigNumber huge) potrzebuje semantic equal. Sprawdź `BigNumber.equals(other, tolerance)` API |
| EconomyManager wymaga DataLoader.load_shops() przed `get_total_income_per_second` da sensowny wynik | `_ready` w EconomyManager już to robi — w teście wystarczy że autoloady poszły standardowo |

## Acceptance criteria

- [ ] `godot --headless --script tests/OfflineEarningsTest.gd --path .` → 11/11 PASS (lub 10/11 jeśli #11 odkrywa real bug → flag jako TODO)
- [ ] Wszystkie testy z 001-006 nadal PASS — zero regressions
- [ ] `godot --headless --quit-after 5 --path .` zero ERROR/SCRIPT
- [ ] `gdlint` clean
- [ ] **Zero zmian w game code** (preferred). Jeśli niezbędne → tylko 1-line publiczny wrap w SaveSystem
- [ ] Manual smoke: zegar +2h, restart, console log z offline earnings
- [ ] M1 OZNACZONE jako COMPLETE w roadmap (po wszystkich `[x]`)
- [ ] 7-8 commitów per phase + push

## Handoff to Sonnet

Czytaj: ten plan + `@CLAUDE.md` + `@docs/architecture.md` (sekcja 5 Save versioning, sekcja 7 — offline earnings cap=8h, rate=0.5).

Reference:
- `scripts/autoload/SaveSystem.gd` lines 165-201 — to jest source of truth dla `_handle_offline_earnings` logic
- `tests/SaveRoundTripTest.gd` (z 006) — fixture/helper pattern
- `tests/_helpers/SignalSpy.gd` — emit assertions

**Kluczowe**:
- **Zero game code change** preferred. Test #11 może odkryć że obecny code aplikuje earnings dwa razy. Jeśli tak → STOP, raportuj user, NIE fixuj w 007.
- **Test #10 niszczy real save**: backup user save przed, restore po. Lub skip tego testu jeśli za ryzykowne, oznaczyć jako manual smoke verification.
- **Math precision**: użyj round-number IPS (10, 100) żeby uniknąć float compare issues. BigNumber.equals dla edge cases.

**Po wszystkich commitach**: 
1. zaktualizuj Status do `[x] DONE` w planie
2. Sprawdź czy wszystkie M1 deliverables `[x]` w roadmap → jeśli tak, dodaj **M1 COMPLETE marker** na końcu sekcji M1

**To jest ostatni plan M1** — po nim Capitalo ma działającą foundation: city z 3 sklepami, HUD reaktywny, modal upgrade/buy, floating numbers, tutorial, save/load z offline earnings. Time for manual playtest 1h przed M2.
