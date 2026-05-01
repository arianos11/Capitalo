## ModalController.gd
## AUTOLOAD: Listens for shop_slot_tapped, opens/closes ShopUpgradeModal.
## Single modal at a time — refuses second open while one is active.
## Adds modal to Main/ModalLayer; falls back to scene root (e.g. in tests).

extends Node

const _MODAL_SCENE := preload("res://scenes/ui/ShopUpgradeModal.tscn")

var _active_modal: Node = null


func _ready() -> void:
	EventBus.shop_slot_tapped.connect(_on_shop_slot_tapped)
	EventBus.modal_closed.connect(_on_modal_closed)


func _on_shop_slot_tapped(shop_id: String, state: String) -> void:
	if _active_modal != null and is_instance_valid(_active_modal):
		return
	var modal = _MODAL_SCENE.instantiate()
	var layer := _get_modal_layer()
	layer.add_child(modal)
	modal.setup(shop_id, state)
	_active_modal = modal
	EventBus.modal_opened.emit("shop_upgrade")


func _on_modal_closed(modal_name: String) -> void:
	if modal_name == "shop_upgrade":
		_active_modal = null


func _get_modal_layer() -> Node:
	var root := get_tree().get_root()
	var modal_layer := root.get_node_or_null("Main/ModalLayer")
	if modal_layer:
		return modal_layer
	return root
