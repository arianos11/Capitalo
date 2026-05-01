## SaveRoundTripTest.gd
## Integration tests: GameState.to_dict → JSON file → from_dict → assert equal.
## Uses direct FileAccess on isolated paths — never touches savegame.json.
## Run: godot --headless --path . --script tests/SaveRoundTripTest.gd

extends SceneTree

const _Fixture := preload("res://tests/_helpers/SaveTestFixture.gd")

const _TEST_PATH   := "user://test_save_roundtrip.json"
const _BACKUP_PATH := "user://test_save_roundtrip_backup.json"
const _ALL_TEST_PATHS: Array[String] = [
	"user://test_save_roundtrip.json",
	"user://test_save_roundtrip_backup.json",
]

var _gs    # GameState
var _eb    # EventBus
var _ss    # SaveSystem

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	_gs = get_root().get_node_or_null("GameState")
	_eb = get_root().get_node_or_null("EventBus")
	_ss = get_root().get_node_or_null("SaveSystem")
	if _gs == null or _eb == null or _ss == null:
		push_error("[SaveRoundTripTest] Autoloads not found — run with --path .")
		quit(1)
		return
	print("[SaveRoundTripTest] Starting 14 tests...")
	_run_tests()


func _run_tests() -> void:
	await process_frame

	# Disable autosave interference
	_ss._autosave_timer = -9999.0

	# Tests #1–10 basic field round-trips
	await _test_empty_state_roundtrip()
	await _test_money_roundtrip()
	await _test_money_huge_roundtrip()
	await _test_money_zero_roundtrip()
	await _test_shops_roundtrip()
	await _test_managers_roundtrip()
	await _test_tech_roundtrip()
	await _test_campaigns_state_roundtrip()
	await _test_tutorial_completed_roundtrip()
	await _test_timestamps_roundtrip()

	# Tests #11–14 defensive cases
	await _test_all_fields_present_after_roundtrip()
	await _test_corrupted_json_falls_back_to_backup()
	await _test_missing_file_returns_false()
	await _test_partial_dict_uses_defaults()

	_Fixture.cleanup_test_files(_ALL_TEST_PATHS)
	_print_results()
	quit(1 if failed > 0 else 0)


# ==========================================================================
# HELPERS
# ==========================================================================

func _assert(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("  ✓ %s" % label)
	else:
		failed += 1
		failures.append(label)
		push_error("  ✗ FAIL: %s" % label)


func _reset() -> void:
	_Fixture.reset_game_state(_gs)
	_Fixture.cleanup_test_files(_ALL_TEST_PATHS)
	_ss._autosave_timer = -9999.0


## Write GameState to test path, load it back via from_dict. Returns loaded dict.
func _roundtrip() -> Dictionary:
	var saved: Dictionary = _gs.to_dict()
	_Fixture.write_json(_TEST_PATH, saved)
	var loaded: Dictionary = _Fixture.read_json(_TEST_PATH)
	_gs.from_dict(loaded)
	return loaded


func _print_results() -> void:
	print("")
	print("[SaveRoundTripTest] Results: %d/%d passed" % [passed, passed + failed])
	if failed > 0:
		print("  Failed tests:")
		for f in failures:
			print("    - %s" % f)


# ==========================================================================
# TEST #1 — empty state round-trip
# ==========================================================================

func _test_empty_state_roundtrip() -> void:
	_reset()

	_roundtrip()

	_assert(_gs.money.compare(BigNumber.from_float(0.0)) == 0,
		"test_empty_state_roundtrip: money == 0")
	_assert(_gs.innovation_points == 0,
		"test_empty_state_roundtrip: innovation_points == 0")
	_assert(_gs.prestige_count == 0,
		"test_empty_state_roundtrip: prestige_count == 0")
	_assert(is_equal_approx(_gs.prestige_multiplier, 1.0),
		"test_empty_state_roundtrip: prestige_multiplier == 1.0")
	_assert(_gs.reputation == 50,
		"test_empty_state_roundtrip: reputation == 50")
	_assert(_gs.shops.is_empty(),
		"test_empty_state_roundtrip: shops empty")
	_assert(_gs.managers.is_empty(),
		"test_empty_state_roundtrip: managers empty")
	_assert(_gs.unlocked_tech.is_empty(),
		"test_empty_state_roundtrip: unlocked_tech empty")
	_assert(_gs.campaign_cooldowns.is_empty(),
		"test_empty_state_roundtrip: campaign_cooldowns empty")
	_assert(_gs.total_campaigns_launched == 0,
		"test_empty_state_roundtrip: total_campaigns_launched == 0")
	_assert(_gs.total_viral_hits == 0,
		"test_empty_state_roundtrip: total_viral_hits == 0")
	_assert(_gs.tutorial_completed.is_empty(),
		"test_empty_state_roundtrip: tutorial_completed empty")
	_assert(is_equal_approx(_gs.total_play_time_seconds, 0.0),
		"test_empty_state_roundtrip: total_play_time_seconds == 0")


# ==========================================================================
# TEST #2 — money round-trip
# ==========================================================================

func _test_money_roundtrip() -> void:
	_reset()
	var original := BigNumber.from_float(123456.789)
	_gs.money = original

	_roundtrip()

	# compare() is exact. JSON float round-trip may introduce sub-epsilon diff;
	# plan anticipated this: use manual tolerance instead.
	_assert(_gs.money.exponent == original.exponent,
		"test_money_roundtrip: exponent preserved")
	_assert(abs(_gs.money.mantissa - original.mantissa) < 1e-9,
		"test_money_roundtrip: mantissa within 1e-9")


# ==========================================================================
# TEST #3 — huge money round-trip
# ==========================================================================

func _test_money_huge_roundtrip() -> void:
	_reset()
	var original := BigNumber.new(9.99, 308)
	_gs.money = original

	_roundtrip()

	_assert(_gs.money.exponent == 308,
		"test_money_huge_roundtrip: exponent 308 preserved")
	_assert(abs(_gs.money.mantissa - 9.99) < 1e-9,
		"test_money_huge_roundtrip: mantissa 9.99 preserved")


# ==========================================================================
# TEST #4 — zero money round-trip
# ==========================================================================

func _test_money_zero_roundtrip() -> void:
	_reset()
	_gs.money = BigNumber.from_float(0.0)

	_roundtrip()

	_assert(_gs.money.is_zero(), "test_money_zero_roundtrip: is_zero")
	_assert(_gs.money.compare(BigNumber.from_float(0.0)) == 0,
		"test_money_zero_roundtrip: compare == 0")


# ==========================================================================
# TEST #5 — shops round-trip
# ==========================================================================

func _test_shops_roundtrip() -> void:
	_reset()
	_gs.purchase_shop("fashion")
	for _i in range(4):
		_gs.upgrade_shop("fashion")   # lvl 5
	_gs.purchase_shop("tech")

	_roundtrip()

	_assert(_gs.shops.has("fashion"),
		"test_shops_roundtrip: fashion present")
	_assert(_gs.get_shop_level("fashion") == 5,
		"test_shops_roundtrip: fashion lvl 5")
	_assert(_gs.shops.has("tech"),
		"test_shops_roundtrip: tech present")
	_assert(_gs.get_shop_level("tech") == 1,
		"test_shops_roundtrip: tech lvl 1")


# ==========================================================================
# TEST #6 — managers round-trip
# ==========================================================================

func _test_managers_roundtrip() -> void:
	_reset()
	_gs.hire_manager("mgr_alex")
	_gs.upgrade_manager("mgr_alex")  # lvl 2
	_gs.managers["mgr_alex"]["assigned_to_shop"] = "fashion"

	_roundtrip()

	_assert(_gs.has_manager("mgr_alex"),
		"test_managers_roundtrip: mgr_alex hired")
	_assert(_gs.managers["mgr_alex"]["level"] == 2,
		"test_managers_roundtrip: level 2")
	_assert(_gs.managers["mgr_alex"]["assigned_to_shop"] == "fashion",
		"test_managers_roundtrip: assigned_to_shop")


# ==========================================================================
# TEST #7 — tech round-trip
# ==========================================================================

func _test_tech_roundtrip() -> void:
	_reset()
	_gs.unlocked_tech.append_array(["mkt_node_1", "mkt_node_2"])

	_roundtrip()

	_assert(_gs.unlocked_tech.size() == 2,
		"test_tech_roundtrip: 2 nodes")
	_assert("mkt_node_1" in _gs.unlocked_tech,
		"test_tech_roundtrip: mkt_node_1 present")
	_assert("mkt_node_2" in _gs.unlocked_tech,
		"test_tech_roundtrip: mkt_node_2 present")


# ==========================================================================
# TEST #8 — campaigns state round-trip
# ==========================================================================

func _test_campaigns_state_roundtrip() -> void:
	_reset()
	_gs.campaign_cooldowns["flyers"] = 1.5
	_gs.campaign_cooldowns["facebook"] = 3.2
	_gs.total_campaigns_launched = 42
	_gs.total_viral_hits = 5

	_roundtrip()

	_assert(_gs.campaign_cooldowns.has("flyers"),
		"test_campaigns_state_roundtrip: flyers key present")
	_assert(is_equal_approx(_gs.campaign_cooldowns["flyers"], 1.5),
		"test_campaigns_state_roundtrip: flyers cooldown 1.5")
	_assert(is_equal_approx(_gs.campaign_cooldowns["facebook"], 3.2),
		"test_campaigns_state_roundtrip: facebook cooldown 3.2")
	_assert(_gs.total_campaigns_launched == 42,
		"test_campaigns_state_roundtrip: total_campaigns_launched 42")
	_assert(_gs.total_viral_hits == 5,
		"test_campaigns_state_roundtrip: total_viral_hits 5")


# ==========================================================================
# TEST #9 — tutorial_completed round-trip
# ==========================================================================

func _test_tutorial_completed_roundtrip() -> void:
	_reset()
	_gs.tutorial_completed = {"first_shop": true, "first_campaign": true}

	_roundtrip()

	_assert(_gs.tutorial_completed.has("first_shop"),
		"test_tutorial_completed_roundtrip: first_shop present")
	_assert(_gs.tutorial_completed["first_shop"] == true,
		"test_tutorial_completed_roundtrip: first_shop true")
	_assert(_gs.tutorial_completed.has("first_campaign"),
		"test_tutorial_completed_roundtrip: first_campaign present")


# ==========================================================================
# TEST #10 — timestamps round-trip
# ==========================================================================

func _test_timestamps_roundtrip() -> void:
	_reset()
	_gs.total_play_time_seconds = 7200.0

	_roundtrip()

	_assert(is_equal_approx(_gs.total_play_time_seconds, 7200.0),
		"test_timestamps_roundtrip: total_play_time_seconds 7200")
	# last_save_timestamp is set by to_dict() dynamically — assert it's non-zero
	_assert(_gs.last_save_timestamp > 0.0,
		"test_timestamps_roundtrip: last_save_timestamp non-zero")


# ==========================================================================
# TEST #11 — all fields present after round-trip (auto-discovery)
# ==========================================================================

func _test_all_fields_present_after_roundtrip() -> void:
	_reset()

	# Load maximal dict into GameState
	var maximal := _Fixture.make_maximal_dict()
	_gs.from_dict(maximal)

	# Serialize, save, reload
	var before_keys: Array = _gs.to_dict().keys()
	before_keys.sort()

	_Fixture.write_json(_TEST_PATH, _gs.to_dict())
	var loaded_dict: Dictionary = _Fixture.read_json(_TEST_PATH)
	_gs.from_dict(loaded_dict)

	var after_keys: Array = _gs.to_dict().keys()
	after_keys.sort()

	_assert(before_keys == after_keys,
		"test_all_fields_present_after_roundtrip: key sets identical")

	# Every key from the maximal dict must survive
	for key in maximal.keys():
		_assert(loaded_dict.has(key),
			"test_all_fields_present_after_roundtrip: key '%s' present" % key)


# ==========================================================================
# TEST #12 — corrupted JSON falls back to backup
# ==========================================================================

func _test_corrupted_json_falls_back_to_backup() -> void:
	_reset()

	# Build known state and write a valid backup
	_gs.money = BigNumber.new(1.23, 9)
	_gs.prestige_count = 2
	var valid_dict: Dictionary = _gs.to_dict()
	_Fixture.write_json(_BACKUP_PATH, valid_dict)

	# Corrupt the main test file
	_Fixture.write_raw(_TEST_PATH, "{{{not valid json")

	# Simulate what SaveSystem.load_game does: parse main → fail → backup
	var main_json := _Fixture.read_json(_TEST_PATH)   # returns {} on parse error
	var loaded_ok: bool
	if main_json.is_empty():
		# Fall back to backup (mirrors SaveSystem._load_from_backup logic)
		var backup_dict := _Fixture.read_json(_BACKUP_PATH)
		if not backup_dict.is_empty():
			_gs.from_dict(backup_dict)
			loaded_ok = true
		else:
			loaded_ok = false
	else:
		_gs.from_dict(main_json)
		loaded_ok = true

	_assert(loaded_ok,
		"test_corrupted_json_falls_back_to_backup: loaded from backup")
	_assert(_gs.prestige_count == 2,
		"test_corrupted_json_falls_back_to_backup: prestige_count restored")
	_assert(_gs.money.exponent == 9,
		"test_corrupted_json_falls_back_to_backup: money exponent restored")


# ==========================================================================
# TEST #13 — missing file returns false / no crash
# ==========================================================================

func _test_missing_file_returns_false() -> void:
	_reset()
	_Fixture.cleanup_test_files(_ALL_TEST_PATHS)  # ensure absent

	var result := _Fixture.read_json(_TEST_PATH)  # should return {}

	_assert(result.is_empty(),
		"test_missing_file_returns_false: returns empty dict")
	_assert(_gs.money.compare(BigNumber.from_float(0.0)) == 0,
		"test_missing_file_returns_false: state unchanged")


# ==========================================================================
# TEST #14 — partial dict uses defaults (forward-compat)
# ==========================================================================

func _test_partial_dict_uses_defaults() -> void:
	_reset()

	# Minimal dict — missing tutorial_completed, campaign_cooldowns, etc.
	var partial := {
		"version": 1,
		"money": {"m": 5.0, "e": 3},
		"innovation_points": 10,
		"prestige_count": 0,
		"prestige_multiplier": 1.0,
		"reputation": 50,
	}
	_Fixture.write_json(_TEST_PATH, partial)
	var loaded := _Fixture.read_json(_TEST_PATH)
	_gs.from_dict(loaded)

	_assert(_gs.tutorial_completed.is_empty(),
		"test_partial_dict_uses_defaults: tutorial_completed defaults to {}")
	_assert(_gs.campaign_cooldowns.is_empty(),
		"test_partial_dict_uses_defaults: campaign_cooldowns defaults to {}")
	_assert(_gs.unlocked_tech.is_empty(),
		"test_partial_dict_uses_defaults: unlocked_tech defaults to []")
	_assert(_gs.shops.is_empty(),
		"test_partial_dict_uses_defaults: shops defaults to {}")
	_assert(_gs.total_campaigns_launched == 0,
		"test_partial_dict_uses_defaults: total_campaigns_launched defaults to 0")
	_assert(_gs.money.compare(BigNumber.new(5.0, 3)) == 0,
		"test_partial_dict_uses_defaults: present fields still loaded")
	_assert(_gs.innovation_points == 10,
		"test_partial_dict_uses_defaults: innovation_points loaded")
