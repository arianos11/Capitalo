## FloatingNumberLayer.gd
## Object pool of 30 reusable Labels that float and fade above shop slots on each income tick.
## Subscribes EventBus.shop_earned, finds ShopSlot by group query, animates via Tween.
## Pool full → silent drop (no crash, no warning). Zero-allocation hot path.

extends CanvasLayer

const POOL_SIZE: int = 30
const FLOAT_DISTANCE: float = 100.0
const ANIMATION_DURATION: float = 1.2
const LABEL_FONT_SIZE: int = 40
const SPAWN_OFFSET: Vector2 = Vector2(0.0, -20.0)

var _pool: Array[Label] = []
var _busy: Array[bool] = []
var _tweens: Array[Tween] = []
var _pool_index: int = 0


func _ready() -> void:
	_build_pool()
	EventBus.shop_earned.connect(_on_shop_earned)


func _build_pool() -> void:
	_pool.resize(POOL_SIZE)
	_busy.resize(POOL_SIZE)
	_tweens.resize(POOL_SIZE)
	for i in POOL_SIZE:
		var label := Label.new()
		label.visible = false
		label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
		label.add_theme_color_override("font_color", Color(0.498, 1.0, 0.0, 1.0))
		label.z_index = 5
		add_child(label)
		_pool[i] = label
		_busy[i] = false
		_tweens[i] = null


func _on_shop_earned(shop_id: String, amount: BigNumber) -> void:
	if amount.is_zero():
		return

	var slot := _find_slot(shop_id)
	if slot == null:
		return

	var idx := _get_idle_index()
	if idx == -1:
		return

	var spawn_x: float = slot.global_position.x + slot.get("size", Vector2.ZERO).x / 2.0
	var spawn_y: float = slot.global_position.y + SPAWN_OFFSET.y
	var start_pos := Vector2(spawn_x, spawn_y)
	var text := "+%s" % Formatters.format_money(amount)

	_animate_label(idx, start_pos, text)


func _find_slot(shop_id: String) -> Node:
	for slot in get_tree().get_nodes_in_group("shop_slots"):
		if slot.get("shop_id", "") == shop_id:
			return slot
	return null


func _get_idle_index() -> int:
	for i in POOL_SIZE:
		var idx := (_pool_index + i) % POOL_SIZE
		if not _busy[idx]:
			_pool_index = (idx + 1) % POOL_SIZE
			return idx
	return -1


func _animate_label(idx: int, start_pos: Vector2, text: String) -> void:
	var label := _pool[idx]
	_busy[idx] = true

	if _tweens[idx] != null and _tweens[idx].is_valid():
		_tweens[idx].kill()

	label.text = text
	label.position = start_pos
	label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	label.visible = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", start_pos.y - FLOAT_DISTANCE, ANIMATION_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, ANIMATION_DURATION)
	tween.finished.connect(_on_tween_finished.bind(idx), CONNECT_ONE_SHOT)
	_tweens[idx] = tween


func _on_tween_finished(idx: int) -> void:
	_pool[idx].visible = false
	_busy[idx] = false
