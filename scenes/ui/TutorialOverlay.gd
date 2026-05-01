## TutorialOverlay.gd
## Displays a first-run hint with dismiss-on-action behavior.
## Add to tree first, then call setup(). Subscribes EventBus for dismiss triggers.
## Double-dismiss guarded by _dismissed flag. Kills tween in _exit_tree.

extends Control

var _step_id: String = ""
var _dismissed: bool = false
var _tween: Tween = null

@onready var _hint_label: Label = $HintBox/VBox/HintLabel


func setup(step_id: String, hint_text: String) -> void:
	_step_id = step_id
	_hint_label.text = hint_text
	EventBus.tutorial_step_shown.emit(_step_id)


func _ready() -> void:
	EventBus.shop_purchased.connect(_on_shop_purchased)
	EventBus.shop_slot_tapped.connect(_on_shop_slot_tapped)
	_start_pulse()


func _on_shop_purchased(_shop_id: String) -> void:
	_dismiss()


func _on_shop_slot_tapped(_shop_id: String, _state: String) -> void:
	_dismiss()


func _dismiss() -> void:
	if _dismissed or not is_inside_tree():
		return
	_dismissed = true
	GameState.tutorial_completed[_step_id] = true
	SaveSystem.save_game()
	EventBus.tutorial_step_completed.emit(_step_id)
	queue_free()


func _start_pulse() -> void:
	var hint_box: Control = $HintBox
	hint_box.pivot_offset = hint_box.size / 2.0
	_tween = create_tween()
	_tween.set_loops()
	_tween.tween_property(hint_box, "modulate:a", 0.6, 0.8)
	_tween.tween_property(hint_box, "modulate:a", 1.0, 0.8)


func _exit_tree() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if EventBus.shop_purchased.is_connected(_on_shop_purchased):
		EventBus.shop_purchased.disconnect(_on_shop_purchased)
	if EventBus.shop_slot_tapped.is_connected(_on_shop_slot_tapped):
		EventBus.shop_slot_tapped.disconnect(_on_shop_slot_tapped)
