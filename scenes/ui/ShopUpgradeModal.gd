## ShopUpgradeModal.gd
## Modal for buying (empty state) or upgrading (owned state) a shop.
## Opened by ModalController on shop_slot_tapped.
## Never reads GameState in _process — initial render in setup(), then reactive on money_changed.

class_name ShopUpgradeModal
extends Control

var _shop_id: String = ""
var _slot_state: String = "empty"
var _shop_def: Dictionary = {}
var _emitted_close: bool = false

@onready var title_label: Label = $ModalBox/VBox/TitleRow/TitleLabel
@onready var close_button: Button = $ModalBox/VBox/TitleRow/CloseButton
@onready var icon_rect: ColorRect = $ModalBox/VBox/IconRect
@onready var level_label: Label = $ModalBox/VBox/LevelLabel
@onready var ips_label: Label = $ModalBox/VBox/IPSLabel
@onready var cost_label: Label = $ModalBox/VBox/CostLabel
@onready var action_button: Button = $ModalBox/VBox/ActionButton
@onready var insufficient_label: Label = $ModalBox/VBox/InsufficientFundsLabel
@onready var backdrop: Button = $Backdrop


func _ready() -> void:
	action_button.pressed.connect(_on_action_pressed)
	close_button.pressed.connect(_on_close_pressed)
	backdrop.pressed.connect(_on_close_pressed)
	EventBus.money_changed.connect(_on_money_changed)


func _exit_tree() -> void:
	if EventBus.money_changed.is_connected(_on_money_changed):
		EventBus.money_changed.disconnect(_on_money_changed)
	if not _emitted_close:
		_emitted_close = true
		EventBus.modal_closed.emit("shop_upgrade")


func setup(shop_id: String, state: String) -> void:
	_shop_id = shop_id
	_slot_state = state
	_shop_def = _find_shop_def(shop_id)

	title_label.text = _shop_def.get("name", shop_id)
	var color_hex: String = _shop_def.get("color_primary", "#888888")
	icon_rect.color = Color.from_string(color_hex, Color(0.5, 0.5, 0.5))

	if state == "owned":
		var level := GameState.get_shop_level(shop_id)
		level_label.text = "Level %d" % level
		var ips := EconomyManager.calculate_shop_income(shop_id)
		ips_label.text = "Income: %s/sec" % Formatters.format_money(ips)
		ips_label.visible = true
		action_button.text = "Upgrade"
		var cost := EconomyManager.get_shop_upgrade_cost(shop_id)
		cost_label.text = "Cost: %s" % Formatters.format_money(cost)
	else:
		level_label.text = "Not owned"
		ips_label.visible = false
		action_button.text = "Buy"
		var unlock_cost: int = _shop_def.get("unlock_cost", 0)
		if unlock_cost == 0:
			cost_label.text = "Free"
		else:
			cost_label.text = "Cost: %s" % Formatters.format_money(BigNumber.from_float(float(unlock_cost)))

	_refresh_button_state()


func _find_shop_def(shop_id: String) -> Dictionary:
	for s in DataLoader.load_shops():
		if s.get("id", "") == shop_id:
			return s
	return {}


func _refresh_button_state() -> void:
	var cost: BigNumber
	if _slot_state == "empty":
		cost = BigNumber.from_float(float(_shop_def.get("unlock_cost", 0)))
	else:
		cost = EconomyManager.get_shop_upgrade_cost(_shop_id)
	var can_afford := GameState.can_afford(cost)
	action_button.disabled = not can_afford
	insufficient_label.visible = not can_afford


func _on_action_pressed() -> void:
	var cost: BigNumber
	if _slot_state == "empty":
		cost = BigNumber.from_float(float(_shop_def.get("unlock_cost", 0)))
	else:
		cost = EconomyManager.get_shop_upgrade_cost(_shop_id)

	if not GameState.try_spend_money(cost):
		EventBus.shop_purchase_failed.emit(_shop_id, "insufficient_funds")
		return

	if _slot_state == "empty":
		GameState.purchase_shop(_shop_id)
	else:
		GameState.upgrade_shop(_shop_id)

	_close_modal()


func _on_close_pressed() -> void:
	_close_modal()


func _on_money_changed(_new_money: BigNumber) -> void:
	if _shop_id.is_empty():
		return
	_refresh_button_state()


func _close_modal() -> void:
	if not _emitted_close:
		_emitted_close = true
		EventBus.modal_closed.emit("shop_upgrade")
	queue_free()
