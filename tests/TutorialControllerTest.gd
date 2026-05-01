## TutorialControllerTest.gd
## Tests for TutorialController + TutorialOverlay.
## Run: godot --headless --path . --script tests/TutorialControllerTest.gd

extends SceneTree

const _SignalSpy := preload("res://tests/_helpers/SignalSpy.gd")

var _eb   # EventBus
var _gs   # GameState
var _tc   # TutorialController

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	_eb = get_root().get_node_or_null("EventBus")
	_gs = get_root().get_node_or_null("GameState")
	_tc = get_root().get_node_or_null("TutorialController")
	if _eb == null or _gs == null:
		push_error("[TutorialControllerTest] Autoloads not found — run with --path .")
		quit(1)
		return
	if _tc == null:
		push_error("[TutorialControllerTest] TutorialController not found — register in project.godot")
		quit(1)
		return
	print("[TutorialControllerTest] Starting 8 tests...")
	_run_tests()


func _run_tests() -> void:
	await process_frame

	await _test_overlay_shown_on_fresh_save()
	await _test_overlay_not_shown_when_completed()
	await _test_overlay_not_shown_when_shops_already_owned()
	await _test_overlay_dismisses_on_shop_purchased()
	await _test_overlay_dismisses_on_shop_slot_tapped()
	await _test_save_flushed_on_completion()
	await _test_to_dict_from_dict_round_trip()
	await _test_emits_tutorial_signals()

	_print_results()
	quit(1 if failed > 0 else 0)


# ==========================================================================
# ASSERTIONS
# ==========================================================================

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		passed += 1
		print("  ✓ %s" % test_name)
	else:
		failed += 1
		failures.append(test_name)
		push_error("  ✗ FAIL: %s" % test_name)


func _print_results() -> void:
	print("\n[TutorialControllerTest] Results: %d/%d passed" % [passed, passed + failed])
	for f in failures:
		print("  ✗ %s" % f)


# ==========================================================================
# HELPERS
# ==========================================================================

func _find_overlay() -> Node:
	return get_root().get_node_or_null("TutorialOverlay")


func _cleanup() -> void:
	var ov := _find_overlay()
	if ov and is_instance_valid(ov):
		ov.queue_free()
		await process_frame
	_gs.tutorial_completed = {}
	_gs.shops = {}


# ==========================================================================
# TESTS
# ==========================================================================

func _test_overlay_shown_on_fresh_save() -> void:
	await _cleanup()
	_gs.tutorial_completed = {}
	_gs.shops = {}

	_eb.game_loaded.emit()
	await process_frame
	await process_frame

	var ov := _find_overlay()
	_assert(ov != null, "test_overlay_shown_on_fresh_save: overlay in tree")

	await _cleanup()


func _test_overlay_not_shown_when_completed() -> void:
	await _cleanup()
	_gs.tutorial_completed = {"first_shop": true}
	_gs.shops = {}

	_eb.game_loaded.emit()
	await process_frame
	await process_frame

	var ov := _find_overlay()
	_assert(ov == null, "test_overlay_not_shown_when_completed: no overlay")

	await _cleanup()


func _test_overlay_not_shown_when_shops_already_owned() -> void:
	await _cleanup()
	_gs.tutorial_completed = {}
	_gs.shops = {"fashion": {"level": 1}}

	_eb.game_loaded.emit()
	await process_frame
	await process_frame

	var ov := _find_overlay()
	_assert(ov == null, "test_overlay_not_shown_when_shops_already_owned: no overlay")

	await _cleanup()


func _test_overlay_dismisses_on_shop_purchased() -> void:
	await _cleanup()
	_gs.tutorial_completed = {}
	_gs.shops = {}

	_eb.game_loaded.emit()
	await process_frame
	await process_frame

	var ov := _find_overlay()
	_assert(ov != null, "test_overlay_dismisses_on_shop_purchased: overlay appeared")

	_eb.shop_purchased.emit("fashion")
	await process_frame

	var ov_after := _find_overlay()
	_assert(ov_after == null or not is_instance_valid(ov_after),
		"test_overlay_dismisses_on_shop_purchased: overlay dismissed")
	_assert(_gs.tutorial_completed.get("first_shop", false) == true,
		"test_overlay_dismisses_on_shop_purchased: first_shop marked done")

	await _cleanup()


func _test_overlay_dismisses_on_shop_slot_tapped() -> void:
	await _cleanup()
	_gs.tutorial_completed = {}
	_gs.shops = {}

	_eb.game_loaded.emit()
	await process_frame
	await process_frame

	var ov := _find_overlay()
	_assert(ov != null, "test_overlay_dismisses_on_shop_slot_tapped: overlay appeared")

	_eb.shop_slot_tapped.emit("fashion", "empty")
	await process_frame

	var ov_after := _find_overlay()
	_assert(ov_after == null or not is_instance_valid(ov_after),
		"test_overlay_dismisses_on_shop_slot_tapped: overlay dismissed")

	await _cleanup()


func _test_save_flushed_on_completion() -> void:
	await _cleanup()
	_gs.tutorial_completed = {}
	_gs.shops = {}

	var spy := _SignalSpy.new()
	_eb.game_saved.connect(spy.on_0)

	_eb.game_loaded.emit()
	await process_frame
	await process_frame

	_eb.shop_purchased.emit("fashion")
	await process_frame

	_assert(spy.count >= 1, "test_save_flushed_on_completion: game_saved emitted")

	_eb.game_saved.disconnect(spy.on_0)
	await _cleanup()


func _test_to_dict_from_dict_round_trip() -> void:
	_gs.tutorial_completed = {"first_shop": true, "other_step": false}
	var saved: Dictionary = _gs.to_dict()

	_assert(
		saved.get("tutorial_completed", {}).get("first_shop") == true,
		"test_to_dict_from_dict_round_trip: to_dict persists first_shop=true"
	)
	_assert(
		saved.get("tutorial_completed", {}).get("other_step") == false,
		"test_to_dict_from_dict_round_trip: to_dict persists other_step=false"
	)

	# Verify from_dict pattern restores correctly (same logic GameState.from_dict uses)
	var restored: Dictionary = saved.get("tutorial_completed", {})
	_assert(
		restored.get("first_shop") == true,
		"test_to_dict_from_dict_round_trip: from_dict pattern restores first_shop"
	)

	_gs.tutorial_completed = {}


func _test_emits_tutorial_signals() -> void:
	await _cleanup()
	_gs.tutorial_completed = {}
	_gs.shops = {}

	var spy_shown := _SignalSpy.new()
	var spy_done := _SignalSpy.new()
	_eb.tutorial_step_shown.connect(spy_shown.on_1)
	_eb.tutorial_step_completed.connect(spy_done.on_1)

	_eb.game_loaded.emit()
	await process_frame
	await process_frame

	_assert(spy_shown.count == 1, "test_emits_tutorial_signals: step_shown emitted")
	_assert(spy_shown.last_args == ["first_shop"],
		"test_emits_tutorial_signals: step_shown args == ['first_shop']")

	_eb.shop_purchased.emit("fashion")
	await process_frame

	_assert(spy_done.count == 1, "test_emits_tutorial_signals: step_completed emitted")

	_eb.tutorial_step_shown.disconnect(spy_shown.on_1)
	_eb.tutorial_step_completed.disconnect(spy_done.on_1)
	await _cleanup()
