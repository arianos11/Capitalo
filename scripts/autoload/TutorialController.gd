## TutorialController.gd
## AUTOLOAD: Listens for game_loaded, shows first-run tutorial overlay when eligible.
## Eligible = no owned shops AND tutorial_completed["first_shop"] not set.
## Adds overlay to Main/TutorialLayer; falls back to scene root (e.g. in tests).

extends Node

const _OVERLAY_SCENE := preload("res://scenes/ui/TutorialOverlay.tscn")
const _FIRST_SHOP_HINT := "Tap the shop to buy\nyour first store!"


func _ready() -> void:
	EventBus.game_loaded.connect(_on_game_loaded)


func _on_game_loaded() -> void:
	if GameState.tutorial_completed.get("first_shop", false):
		return
	if not GameState.shops.is_empty():
		GameState.tutorial_completed["first_shop"] = true
		return
	call_deferred("_show_overlay")


func _show_overlay() -> void:
	var overlay := _OVERLAY_SCENE.instantiate()
	var layer := _get_tutorial_layer()
	layer.add_child(overlay)
	overlay.setup("first_shop", _FIRST_SHOP_HINT)


func _get_tutorial_layer() -> Node:
	var root := get_tree().get_root()
	var tutorial_layer := root.get_node_or_null("Main/TutorialLayer")
	if tutorial_layer:
		return tutorial_layer
	return root
