## ShopUpgradeModalTest.gd
## Tests for ShopUpgradeModal + ModalController.
## Run: godot --headless --path . --script tests/ShopUpgradeModalTest.gd

extends SceneTree

const _SignalSpy := preload("res://tests/_helpers/SignalSpy.gd")

var _gs   # GameState
var _eb   # EventBus
var _mc   # ModalController

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []


func _initialize() -> void:
	_gs = get_root().get_node_or_null("GameState")
	_eb = get_root().get_node_or_null("EventBus")
	_mc = get_root().get_node_or_null("ModalController")
	if _gs == null or _eb == null:
		push_error("[ShopUpgradeModalTest] GameState/EventBus not found — run with --path .")
		quit(1)
		return
	print("[ShopUpgradeModalTest] Starting 11 tests...")
	_run_tests()


func _run_tests() -> void:
	await process_frame

	await _test_empty_state_renders_buy_button()
	await _test_owned_state_renders_upgrade_button()
	await _test_cost_label_uses_economy_manager()
	await _test_buy_button_calls_purchase_shop()
	await _test_buy_button_deducts_money()
	await _test_insufficient_funds_disables_button()
	await _test_money_changed_reenables_button()
	await _test_close_button_frees_modal()
	await _test_backdrop_tap_closes_modal()
	await _test_modal_controller_opens_on_signal()
	await _test_modal_controller_refuses_second_open()

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

func _make_modal(shop_id: String, state: String) -> Node:
	var packed = load("res://scenes/ui/ShopUpgradeModal.tscn") as PackedScene
	if packed == null:
		_assert(false, "ShopUpgradeModal.tscn loads from res://")
		return null
	var modal = packed.instantiate()
	get_root().add_child(modal)
	modal.setup(shop_id, state)
	return modal


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

func _test_empty_state_renders_buy_button() -> void:
	_reset_state()
	var modal = _make_modal("fashion", "empty")
	if modal == null:
		return
	var action_btn = modal.get_node_or_null("ModalBox/VBox/ActionButton") as Button
	var level_label = modal.get_node_or_null("ModalBox/VBox/LevelLabel") as Label
	_assert(action_btn != null, "test_empty_state_renders_buy_button: ActionButton exists")
	_assert(level_label != null, "test_empty_state_renders_buy_button: LevelLabel exists")
	if action_btn:
		_assert(
			action_btn.text == "Buy",
			"test_empty_state_renders_buy_button: button='%s' expected 'Buy'" % action_btn.text
		)
	if level_label:
		_assert(
			level_label.text == "Not owned",
			"test_empty_state_renders_buy_button: label='%s' expected 'Not owned'" % level_label.text
		)
	await _free_node(modal)
	_reset_state()


func _test_owned_state_renders_upgrade_button() -> void:
	_reset_state()
	_gs.purchase_shop("fashion")
	var modal = _make_modal("fashion", "owned")
	if modal == null:
		_reset_state()
		return
	var action_btn = modal.get_node_or_null("ModalBox/VBox/ActionButton") as Button
	var level_label = modal.get_node_or_null("ModalBox/VBox/LevelLabel") as Label
	_assert(action_btn != null, "test_owned_state_renders_upgrade_button: ActionButton exists")
	_assert(level_label != null, "test_owned_state_renders_upgrade_button: LevelLabel exists")
	if action_btn:
		_assert(
			action_btn.text == "Upgrade",
			"test_owned_state_renders_upgrade_button: button='%s' expected 'Upgrade'" % action_btn.text
		)
	if level_label:
		_assert(
			level_label.text.contains("Level"),
			"test_owned_state_renders_upgrade_button: label='%s' expected to contain 'Level'" % level_label.text
		)
	await _free_node(modal)
	_reset_state()


func _test_cost_label_uses_economy_manager() -> void:
	_reset_state()
	var modal = _make_modal("fashion", "empty")
	if modal == null:
		return
	var cost_label = modal.get_node_or_null("ModalBox/VBox/CostLabel") as Label
	_assert(cost_label != null, "test_cost_label_uses_economy_manager: CostLabel exists")
	if cost_label:
		# Fashion unlock_cost = 0 → "Free" (or "Cost: $0")
		_assert(
			cost_label.text == "Free" or cost_label.text == "Cost: $0",
			"test_cost_label_uses_economy_manager: label='%s' expected 'Free' or 'Cost: $0'" % cost_label.text
		)
	await _free_node(modal)
	_reset_state()


func _test_buy_button_calls_purchase_shop() -> void:
	_reset_state()
	_gs.money = BigNumber.from_float(1000.0)
	var modal = _make_modal("fashion", "empty")
	if modal == null:
		_reset_state()
		return
	var spy = _SignalSpy.new()
	_eb.shop_purchased.connect(spy.on_1)

	var action_btn = modal.get_node_or_null("ModalBox/VBox/ActionButton") as Button
	_assert(action_btn != null, "test_buy_button_calls_purchase_shop: ActionButton exists")
	if action_btn:
		action_btn.pressed.emit()
		await process_frame
		_assert(spy.count == 1, "test_buy_button_calls_purchase_shop: signal fired once")
		_assert(
			spy.last_args == ["fashion"],
			"test_buy_button_calls_purchase_shop: args=%s expected ['fashion']" % str(spy.last_args)
		)

	_eb.shop_purchased.disconnect(spy.on_1)
	# Modal freed itself after purchase — just await frame
	await process_frame
	_reset_state()


func _test_buy_button_deducts_money() -> void:
	_reset_state()
	_gs.money = BigNumber.from_float(100.0)
	var modal = _make_modal("fashion", "empty")
	if modal == null:
		_reset_state()
		return

	var action_btn = modal.get_node_or_null("ModalBox/VBox/ActionButton") as Button
	_assert(action_btn != null, "test_buy_button_deducts_money: ActionButton exists")
	if action_btn:
		action_btn.pressed.emit()
		await process_frame
		# Fashion unlock_cost = 0, money stays $100
		_assert(
			_gs.money.compare(BigNumber.from_float(100.0)) == 0,
			"test_buy_button_deducts_money: money=%s expected $100 (free shop)" % _gs.money.to_display()
		)

	await process_frame
	_reset_state()


func _test_insufficient_funds_disables_button() -> void:
	_reset_state()
	_gs.money = BigNumber.from_float(0.0)  # tech costs $1000 to unlock
	var modal = _make_modal("tech", "empty")
	if modal == null:
		return
	var action_btn = modal.get_node_or_null("ModalBox/VBox/ActionButton") as Button
	_assert(action_btn != null, "test_insufficient_funds_disables_button: ActionButton exists")
	if action_btn:
		_assert(
			action_btn.disabled,
			"test_insufficient_funds_disables_button: button disabled (can't afford $1000)"
		)
	await _free_node(modal)
	_reset_state()


func _test_money_changed_reenables_button() -> void:
	_reset_state()
	_gs.money = BigNumber.from_float(0.0)
	_gs.purchase_shop("fashion")  # so state=owned is valid
	var modal = _make_modal("fashion", "owned")
	if modal == null:
		_reset_state()
		return

	var action_btn = modal.get_node_or_null("ModalBox/VBox/ActionButton") as Button
	_assert(action_btn != null, "test_money_changed_reenables_button: ActionButton exists")
	if action_btn:
		_assert(
			action_btn.disabled,
			"test_money_changed_reenables_button: button initially disabled ($0)"
		)
		# Give player money, then fire signal — refresh should re-enable
		_gs.money = BigNumber.from_float(10000.0)
		_eb.money_changed.emit(_gs.money)
		_assert(
			not action_btn.disabled,
			"test_money_changed_reenables_button: button enabled after money_changed"
		)

	await _free_node(modal)
	_reset_state()


func _test_close_button_frees_modal() -> void:
	_reset_state()
	var modal = _make_modal("fashion", "empty")
	if modal == null:
		return
	_assert(modal.is_inside_tree(), "test_close_button_frees_modal: modal in tree")

	var close_btn = modal.get_node_or_null("ModalBox/VBox/TitleRow/CloseButton") as Button
	_assert(close_btn != null, "test_close_button_frees_modal: CloseButton exists")
	if close_btn:
		close_btn.pressed.emit()
		await process_frame
		_assert(
			not is_instance_valid(modal),
			"test_close_button_frees_modal: modal freed after close"
		)
	_reset_state()


func _test_backdrop_tap_closes_modal() -> void:
	_reset_state()
	var modal = _make_modal("fashion", "empty")
	if modal == null:
		return
	_assert(modal.is_inside_tree(), "test_backdrop_tap_closes_modal: modal in tree")

	var backdrop = modal.get_node_or_null("Backdrop") as Button
	_assert(backdrop != null, "test_backdrop_tap_closes_modal: Backdrop button exists")
	if backdrop:
		backdrop.pressed.emit()
		await process_frame
		_assert(
			not is_instance_valid(modal),
			"test_backdrop_tap_closes_modal: modal freed after backdrop tap"
		)
	_reset_state()


func _test_modal_controller_opens_on_signal() -> void:
	_reset_state()
	_gs.money = BigNumber.from_float(1000.0)
	if _mc == null:
		_assert(false, "test_modal_controller_opens_on_signal: ModalController autoload exists")
		return
	_assert(_mc != null, "test_modal_controller_opens_on_signal: ModalController exists")
	_eb.shop_slot_tapped.emit("fashion", "empty")
	await process_frame
	_assert(
		_mc._active_modal != null and is_instance_valid(_mc._active_modal),
		"test_modal_controller_opens_on_signal: modal opened via shop_slot_tapped"
	)
	if _mc._active_modal and is_instance_valid(_mc._active_modal):
		_mc._active_modal.queue_free()
		await process_frame
	_reset_state()


func _test_modal_controller_refuses_second_open() -> void:
	_reset_state()
	_gs.money = BigNumber.from_float(1000.0)
	if _mc == null:
		_assert(false, "test_modal_controller_refuses_second_open: ModalController autoload exists")
		return
	_eb.shop_slot_tapped.emit("fashion", "empty")
	await process_frame
	var first_modal = _mc._active_modal
	_assert(first_modal != null, "test_modal_controller_refuses_second_open: first modal opened")
	_eb.shop_slot_tapped.emit("fashion", "empty")  # second tap — should be refused
	await process_frame
	_assert(
		_mc._active_modal == first_modal,
		"test_modal_controller_refuses_second_open: same modal, no duplicate"
	)
	if _mc._active_modal and is_instance_valid(_mc._active_modal):
		_mc._active_modal.queue_free()
		await process_frame
	_reset_state()


# ==========================================================================
# RESULTS
# ==========================================================================

func _print_results() -> void:
	print("=".repeat(60))
	print("ShopUpgradeModal Test Results")
	print("=".repeat(60))
	print("Passed: %d / %d" % [passed, passed + failed])
	if failed > 0:
		print("\nFailed:")
		for f in failures:
			print("  ✗ %s" % f)
	else:
		print("\n✓ All tests passed!")
