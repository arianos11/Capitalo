## CityViewTest.gd
## Tests for CityView scene: slot rendering, tap signals, EventBus subscription.
## Run: godot --headless --path . --script tests/CityViewTest.gd
##
## Tests:
##   1. test_loads_3_shop_slots     — CityView has 3 phase_1 ShopSlot children
##   2. test_slot_empty_state       — Fashion slot shows "Buy: $0" when not owned
##   3. test_slot_owned_state       — Fashion slot shows "Lvl 5" when owned at level 5
##   4. test_tap_emits_signal_empty — Tapping empty slot emits shop_slot_tapped(id, "empty")
##   5. test_tap_emits_signal_owned — Tapping owned slot emits shop_slot_tapped(id, "owned")
##   6. test_subscribes_shop_purchased — shop_purchased signal flips slot to owned

extends Node

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []


func _ready() -> void:
	print("[CityViewTest] Starting 6 tests...")
	_run_tests()


func _run_tests() -> void:
	await get_tree().process_frame

	await _test_loads_3_shop_slots()
	await _test_slot_empty_state()
	await _test_slot_owned_state()
	await _test_tap_emits_signal_empty()
	await _test_tap_emits_signal_owned()
	await _test_subscribes_shop_purchased()

	_print_results()
	get_tree().quit(1 if failed > 0 else 0)


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


# ==========================================================================
# HELPERS
# ==========================================================================

func _make_cv() -> Node:
	var packed = load("res://scenes/city/CityView.tscn") as PackedScene
	if packed == null:
		_assert(false, "CityView.tscn loads from res://")
		return null
	var cv = packed.instantiate()
	add_child(cv)
	return cv


func _free_node(n: Node) -> void:
	if n and is_instance_valid(n):
		n.queue_free()
	await get_tree().process_frame


func _reset_state() -> void:
	GameState.shops.clear()


# ==========================================================================
# TESTS
# ==========================================================================

func _test_loads_3_shop_slots() -> void:
	_reset_state()
	var cv = _make_cv()
	if cv == null:
		return
	_assert(cv.get_child_count() == 3, "test_loads_3_shop_slots: CityView has 3 children")
	await _free_node(cv)


func _test_slot_empty_state() -> void:
	_reset_state()
	var cv = _make_cv()
	if cv == null:
		return
	# Fashion is first phase_1 shop with unlock_cost = 0
	var first_slot = cv.get_child(0)
	_assert(first_slot != null, "test_slot_empty_state: first slot node exists")
	if first_slot == null:
		await _free_node(cv)
		return
	var level_label = first_slot.get_node_or_null("HBox/InfoBox/LevelLabel") as Label
	_assert(level_label != null, "test_slot_empty_state: LevelLabel node exists")
	if level_label:
		_assert(
			level_label.text == "Buy: $0",
			"test_slot_empty_state: label='%s' expected 'Buy: $0'" % level_label.text
		)
	await _free_node(cv)


func _test_slot_owned_state() -> void:
	_reset_state()
	GameState.shops["fashion"] = {
		"level": 5,
		"specialization": "",
		"manager_id": "",
		"purchased_at": 0.0
	}
	var cv = _make_cv()
	if cv == null:
		_reset_state()
		return
	var fashion_slot = cv.call("get_slot", "fashion")
	_assert(fashion_slot != null, "test_slot_owned_state: fashion slot exists in _slots dict")
	if fashion_slot:
		var level_label = fashion_slot.get_node_or_null("HBox/InfoBox/LevelLabel") as Label
		_assert(level_label != null, "test_slot_owned_state: LevelLabel exists")
		if level_label:
			_assert(
				level_label.text == "Lvl 5",
				"test_slot_owned_state: label='%s' expected 'Lvl 5'" % level_label.text
			)
	await _free_node(cv)
	_reset_state()


func _test_tap_emits_signal_empty() -> void:
	_reset_state()
	var cv = _make_cv()
	if cv == null:
		return
	var spy = SignalSpy.new()
	EventBus.shop_slot_tapped.connect(spy.on_2)

	var fashion_slot = cv.call("get_slot", "fashion")
	_assert(fashion_slot != null, "test_tap_emits_signal_empty: fashion slot found")
	if fashion_slot:
		fashion_slot._on_tapped()
		_assert(spy.count == 1, "test_tap_emits_signal_empty: signal fired once")
		_assert(
			spy.last_args == ["fashion", "empty"],
			"test_tap_emits_signal_empty: args=%s expected ['fashion','empty']" % str(spy.last_args)
		)

	EventBus.shop_slot_tapped.disconnect(spy.on_2)
	await _free_node(cv)


func _test_tap_emits_signal_owned() -> void:
	_reset_state()
	GameState.shops["fashion"] = {
		"level": 1,
		"specialization": "",
		"manager_id": "",
		"purchased_at": 0.0
	}
	var cv = _make_cv()
	if cv == null:
		_reset_state()
		return
	var spy = SignalSpy.new()
	EventBus.shop_slot_tapped.connect(spy.on_2)

	var fashion_slot = cv.call("get_slot", "fashion")
	_assert(fashion_slot != null, "test_tap_emits_signal_owned: fashion slot found")
	if fashion_slot:
		fashion_slot._on_tapped()
		_assert(spy.count == 1, "test_tap_emits_signal_owned: signal fired once")
		_assert(
			spy.last_args == ["fashion", "owned"],
			"test_tap_emits_signal_owned: args=%s expected ['fashion','owned']" % str(spy.last_args)
		)

	EventBus.shop_slot_tapped.disconnect(spy.on_2)
	await _free_node(cv)
	_reset_state()


func _test_subscribes_shop_purchased() -> void:
	_reset_state()
	var cv = _make_cv()
	if cv == null:
		return
	var fashion_slot = cv.call("get_slot", "fashion")
	_assert(fashion_slot != null, "test_subscribes_shop_purchased: fashion slot found")
	if fashion_slot:
		_assert(
			not fashion_slot.call("is_owned"),
			"test_subscribes_shop_purchased: initially empty"
		)
		# purchase_shop emits shop_purchased synchronously → CityView._on_shop_purchased runs
		GameState.purchase_shop("fashion")
		_assert(
			fashion_slot.call("is_owned"),
			"test_subscribes_shop_purchased: owned after shop_purchased signal"
		)
		GameState.shops.clear()

	await _free_node(cv)


# ==========================================================================
# RESULTS
# ==========================================================================

func _print_results() -> void:
	print("=".repeat(60))
	print("CityView Test Results")
	print("=".repeat(60))
	print("Passed: %d / %d" % [passed, passed + failed])
	if failed > 0:
		print("\nFailed:")
		for f in failures:
			print("  ✗ %s" % f)
	else:
		print("\n✓ All tests passed!")
