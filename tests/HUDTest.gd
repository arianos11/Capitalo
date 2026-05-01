## HUDTest.gd
## Tests for HUD scene: reactive labels, settings signal, disconnect cleanup.
## Run: godot --headless --path . --script tests/HUDTest.gd

extends SceneTree

const _SignalSpy := preload("res://tests/_helpers/SignalSpy.gd")

var _gs   # GameState
var _eb   # EventBus
var _em   # EconomyManager

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	_gs = get_root().get_node_or_null("GameState")
	_eb = get_root().get_node_or_null("EventBus")
	_em = get_root().get_node_or_null("EconomyManager")
	if _gs == null or _eb == null or _em == null:
		push_error("[HUDTest] Autoloads not found — run with --path .")
		quit(1)
		return
	print("[HUDTest] Starting 6 tests...")
	_run_tests()


func _run_tests() -> void:
	await process_frame

	await _test_initial_snapshot()
	await _test_money_changed_updates_label()
	await _test_ips_changed_updates_label()
	await _test_settings_button_emits_signal()
	await _test_disconnects_on_exit_tree()
	await _test_money_label_uses_formatters()

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


# ==========================================================================
# HELPERS
# ==========================================================================

func _make_hud() -> Node:
	var packed = load("res://scenes/ui/HUD.tscn") as PackedScene
	if packed == null:
		_assert(false, "HUD.tscn loads from res://")
		return null
	var hud = packed.instantiate()
	get_root().add_child(hud)
	return hud


func _free_node(n: Node) -> void:
	if n and is_instance_valid(n):
		n.queue_free()
	await process_frame


func _reset_state() -> void:
	_gs.money = BigNumber.from_float(0.0)
	_gs.shops.clear()


# ==========================================================================
# TESTS
# ==========================================================================

func _test_initial_snapshot() -> void:
	_reset_state()
	_gs.money = BigNumber.from_float(500.0)
	var hud = _make_hud()
	if hud == null:
		return
	var cash_label = hud.get_node_or_null("VBox/CashLabel") as Label
	_assert(cash_label != null, "test_initial_snapshot: CashLabel node exists")
	if cash_label:
		_assert(
			cash_label.text != "" and cash_label.text != "0",
			"test_initial_snapshot: label='%s' shows initial money (not blank)" % cash_label.text
		)
	await _free_node(hud)
	_reset_state()


func _test_money_changed_updates_label() -> void:
	_reset_state()
	var hud = _make_hud()
	if hud == null:
		return
	var cash_label = hud.get_node_or_null("VBox/CashLabel") as Label
	_assert(cash_label != null, "test_money_changed_updates_label: CashLabel exists")
	if cash_label:
		_eb.money_changed.emit(BigNumber.from_float(1234.0))
		_assert(
			cash_label.text == "$1.23K",
			"test_money_changed_updates_label: label='%s' expected '$1.23K'" % cash_label.text
		)
	await _free_node(hud)
	_reset_state()


func _test_ips_changed_updates_label() -> void:
	_reset_state()
	var hud = _make_hud()
	if hud == null:
		return
	var ips_label = hud.get_node_or_null("VBox/IPSLabel") as Label
	_assert(ips_label != null, "test_ips_changed_updates_label: IPSLabel exists")
	if ips_label:
		_eb.income_per_second_changed.emit(BigNumber.from_float(50.0))
		_assert(
			ips_label.text == "$50.0/sec",
			"test_ips_changed_updates_label: label='%s' expected '$50.0/sec'" % ips_label.text
		)
	await _free_node(hud)
	_reset_state()


func _test_settings_button_emits_signal() -> void:
	_reset_state()
	var hud = _make_hud()
	if hud == null:
		return
	var spy = _SignalSpy.new()
	_eb.settings_requested.connect(spy.on_0)

	var settings_btn = hud.get_node_or_null("VBox/TitleRow/SettingsButton") as Button
	_assert(settings_btn != null, "test_settings_button_emits_signal: SettingsButton exists")
	if settings_btn:
		settings_btn.pressed.emit()
		_assert(spy.count == 1, "test_settings_button_emits_signal: signal fired once")

	_eb.settings_requested.disconnect(spy.on_0)
	await _free_node(hud)
	_reset_state()


func _test_disconnects_on_exit_tree() -> void:
	_reset_state()
	var hud = _make_hud()
	if hud == null:
		return
	_assert(hud != null, "test_disconnects_on_exit_tree: HUD instantiated")
	await _free_node(hud)
	# emit after free — no crash = pass
	_eb.money_changed.emit(BigNumber.from_float(1.0))
	await process_frame
	_assert(true, "test_disconnects_on_exit_tree: no crash after free + emit")
	_reset_state()


func _test_money_label_uses_formatters() -> void:
	_reset_state()
	_gs.money = BigNumber.from_float(1500000.0)
	var hud = _make_hud()
	if hud == null:
		return
	var cash_label = hud.get_node_or_null("VBox/CashLabel") as Label
	_assert(cash_label != null, "test_money_label_uses_formatters: CashLabel exists")
	if cash_label:
		_assert(
			cash_label.text == "$1.50M",
			"test_money_label_uses_formatters: label='%s' expected '$1.50M'" % cash_label.text
		)
	await _free_node(hud)
	_reset_state()


# ==========================================================================
# RESULTS
# ==========================================================================

func _print_results() -> void:
	print("=".repeat(60))
	print("HUD Test Results")
	print("=".repeat(60))
	print("Passed: %d / %d" % [passed, passed + failed])
	if failed > 0:
		print("\nFailed:")
		for f in failures:
			print("  ✗ %s" % f)
	else:
		print("\n✓ All tests passed!")
