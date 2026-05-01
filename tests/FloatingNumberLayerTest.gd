## FloatingNumberLayerTest.gd
## Tests for FloatingNumberLayer: object pool, shop_earned subscription, animation.
## Run: godot --headless --path . --script tests/FloatingNumberLayerTest.gd

extends SceneTree

const _SignalSpy := preload("res://tests/_helpers/SignalSpy.gd")
const _LAYER_PATH := "res://scenes/ui/FloatingNumberLayer.tscn"

var _eb  # EventBus
var _gs  # GameState
var _em  # EconomyManager

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []


# Inner class for mock shop slots — has shop_id and size properties
class MockShopSlot extends Node2D:
	var shop_id: String = ""
	var size: Vector2 = Vector2(100.0, 100.0)


func _initialize() -> void:
	_eb = get_root().get_node_or_null("EventBus")
	_gs = get_root().get_node_or_null("GameState")
	_em = get_root().get_node_or_null("EconomyManager")
	if _eb == null or _gs == null or _em == null:
		push_error("[FloatingNumberLayerTest] Autoloads not found — run with --path .")
		quit(1)
		return
	print("[FloatingNumberLayerTest] Starting 10 tests...")
	_run_tests()


func _run_tests() -> void:
	await process_frame

	await _test_pool_initialized_with_30_labels()
	await _test_shop_earned_spawns_label()
	await _test_label_position_matches_slot()
	await _test_pool_recycles_after_animation()
	await _test_pool_drops_when_full()
	await _test_unknown_shop_id_no_spawn()
	await _test_format_uses_formatters()
	await _test_zero_amount_no_spawn()
	await _test_label_fades_to_invisible()
	await _test_economy_tick_emits_per_shop()

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
	print("\n[FloatingNumberLayerTest] Results: %d/%d passed" % [passed, passed + failed])
	for f in failures:
		print("  ✗ %s" % f)


# ==========================================================================
# HELPERS
# ==========================================================================

func _load_layer() -> Node:
	if not ResourceLoader.exists(_LAYER_PATH):
		return null
	var scene: PackedScene = load(_LAYER_PATH)
	if scene == null:
		return null
	return scene.instantiate()


func _make_mock_slot(shop_id_val: String, pos: Vector2) -> MockShopSlot:
	var slot := MockShopSlot.new()
	slot.shop_id = shop_id_val
	slot.position = pos
	slot.add_to_group("shop_slots")
	return slot


func _count_visible_labels(layer: Node) -> int:
	var count := 0
	for child in layer.get_children():
		if child is Label and child.visible:
			count += 1
	return count


# ==========================================================================
# TESTS
# ==========================================================================

func _test_pool_initialized_with_30_labels() -> void:
	var layer := _load_layer()
	_assert(layer != null, "test_pool_initialized_with_30_labels: scene loads")
	if layer == null:
		return
	get_root().add_child(layer)
	await process_frame

	var label_count := 0
	var all_hidden := true
	for child in layer.get_children():
		if child is Label:
			label_count += 1
			if child.visible:
				all_hidden = false

	_assert(label_count >= 30, "test_pool_initialized_with_30_labels: >= 30 Labels")
	_assert(all_hidden, "test_pool_initialized_with_30_labels: all hidden on init")

	layer.queue_free()
	await process_frame


func _test_shop_earned_spawns_label() -> void:
	var layer := _load_layer()
	_assert(layer != null, "test_shop_earned_spawns_label: scene loads")
	if layer == null:
		return
	get_root().add_child(layer)
	var slot := _make_mock_slot("fashion", Vector2(200.0, 400.0))
	get_root().add_child(slot)
	await process_frame

	_eb.shop_earned.emit("fashion", BigNumber.from_float(123.0))
	await process_frame

	var visible_count := _count_visible_labels(layer)
	_assert(visible_count == 1, "test_shop_earned_spawns_label: exactly 1 label visible")

	var spawned_text := ""
	for child in layer.get_children():
		if child is Label and child.visible:
			spawned_text = child.text
			break
	_assert(spawned_text == "+$123", "test_shop_earned_spawns_label: text == '+$123'")

	layer.queue_free()
	slot.queue_free()
	await process_frame


func _test_label_position_matches_slot() -> void:
	var layer := _load_layer()
	_assert(layer != null, "test_label_position_matches_slot: scene loads")
	if layer == null:
		return
	get_root().add_child(layer)
	var slot := _make_mock_slot("fashion", Vector2(200.0, 400.0))
	get_root().add_child(slot)
	await process_frame

	_eb.shop_earned.emit("fashion", BigNumber.from_float(50.0))
	await process_frame

	var label_pos := Vector2.ZERO
	var found := false
	for child in layer.get_children():
		if child is Label and child.visible:
			label_pos = child.position
			found = true
			break

	_assert(found, "test_label_position_matches_slot: label spawned")
	if found:
		# Expected: slot.global_position + Vector2(slot.size.x / 2, -20)
		var expected := slot.global_position + Vector2(slot.size.x / 2.0, -20.0)
		var dist := label_pos.distance_to(expected)
		_assert(dist < 5.0, "test_label_position_matches_slot: position within 5px of slot center-top (dist=%.1f)" % dist)

	layer.queue_free()
	slot.queue_free()
	await process_frame


func _test_pool_recycles_after_animation() -> void:
	var layer := _load_layer()
	_assert(layer != null, "test_pool_recycles_after_animation: scene loads")
	if layer == null:
		return
	get_root().add_child(layer)
	var slot := _make_mock_slot("fashion", Vector2(200.0, 400.0))
	get_root().add_child(slot)
	await process_frame

	_eb.shop_earned.emit("fashion", BigNumber.from_float(10.0))
	await process_frame
	_assert(_count_visible_labels(layer) == 1, "test_pool_recycles_after_animation: 1 label active")

	await create_timer(1.5).timeout

	_assert(_count_visible_labels(layer) == 0, "test_pool_recycles_after_animation: label hidden after tween")

	_eb.shop_earned.emit("fashion", BigNumber.from_float(20.0))
	await process_frame
	_assert(_count_visible_labels(layer) == 1, "test_pool_recycles_after_animation: recycled label reused")

	layer.queue_free()
	slot.queue_free()
	await process_frame


func _test_pool_drops_when_full() -> void:
	var layer := _load_layer()
	_assert(layer != null, "test_pool_drops_when_full: scene loads")
	if layer == null:
		return
	get_root().add_child(layer)
	var slot := _make_mock_slot("fashion", Vector2(200.0, 400.0))
	get_root().add_child(slot)
	await process_frame

	for i in 35:
		_eb.shop_earned.emit("fashion", BigNumber.from_float(float(i + 1)))
	await process_frame

	var visible_count := _count_visible_labels(layer)
	_assert(visible_count <= 30, "test_pool_drops_when_full: <= 30 labels visible (got %d)" % visible_count)
	_assert(visible_count > 0, "test_pool_drops_when_full: at least 1 label active")

	layer.queue_free()
	slot.queue_free()
	await process_frame


func _test_unknown_shop_id_no_spawn() -> void:
	var layer := _load_layer()
	_assert(layer != null, "test_unknown_shop_id_no_spawn: scene loads")
	if layer == null:
		return
	get_root().add_child(layer)
	await process_frame

	_eb.shop_earned.emit("nonexistent_shop", BigNumber.from_float(100.0))
	await process_frame

	_assert(_count_visible_labels(layer) == 0, "test_unknown_shop_id_no_spawn: 0 labels (no slot found)")

	layer.queue_free()
	await process_frame


func _test_format_uses_formatters() -> void:
	var layer := _load_layer()
	_assert(layer != null, "test_format_uses_formatters: scene loads")
	if layer == null:
		return
	get_root().add_child(layer)
	var slot := _make_mock_slot("fashion", Vector2(200.0, 400.0))
	get_root().add_child(slot)
	await process_frame

	_eb.shop_earned.emit("fashion", BigNumber.from_float(1500000.0))
	await process_frame

	var label_text := ""
	for child in layer.get_children():
		if child is Label and child.visible:
			label_text = child.text
			break
	_assert(label_text == "+$1.50M", "test_format_uses_formatters: text == '+$1.50M' (got '%s')" % label_text)

	layer.queue_free()
	slot.queue_free()
	await process_frame


func _test_zero_amount_no_spawn() -> void:
	var layer := _load_layer()
	_assert(layer != null, "test_zero_amount_no_spawn: scene loads")
	if layer == null:
		return
	get_root().add_child(layer)
	var slot := _make_mock_slot("fashion", Vector2(200.0, 400.0))
	get_root().add_child(slot)
	await process_frame

	_eb.shop_earned.emit("fashion", BigNumber.from_float(0.0))
	await process_frame

	_assert(_count_visible_labels(layer) == 0, "test_zero_amount_no_spawn: 0 labels for zero amount")

	layer.queue_free()
	slot.queue_free()
	await process_frame


func _test_label_fades_to_invisible() -> void:
	var layer := _load_layer()
	_assert(layer != null, "test_label_fades_to_invisible: scene loads")
	if layer == null:
		return
	get_root().add_child(layer)
	var slot := _make_mock_slot("fashion", Vector2(200.0, 400.0))
	get_root().add_child(slot)
	await process_frame

	_eb.shop_earned.emit("fashion", BigNumber.from_float(5.0))
	await process_frame

	var active_label: Label = null
	for child in layer.get_children():
		if child is Label and child.visible:
			active_label = child
			break
	_assert(active_label != null, "test_label_fades_to_invisible: label activated")

	await create_timer(1.5).timeout

	if active_label != null:
		_assert(active_label.modulate.a < 0.05, "test_label_fades_to_invisible: modulate.a ~ 0 after tween")

	layer.queue_free()
	slot.queue_free()
	await process_frame


func _test_economy_tick_emits_per_shop() -> void:
	var spy := _SignalSpy.new()
	_eb.shop_earned.connect(spy.on_2)

	var original_shops: Dictionary = _gs.shops.duplicate(true)
	_gs.shops = {
		"fashion": {"level": 1},
		"tech": {"level": 1}
	}
	_em._cache_dirty = true

	_em._process_income_tick(0.1)

	_assert(spy.count == 2, "test_economy_tick_emits_per_shop: 2 shop_earned emits (got %d)" % spy.count)

	_gs.shops = original_shops
	_em._cache_dirty = true
	_eb.shop_earned.disconnect(spy.on_2)
