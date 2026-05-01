## ShopSlot.gd
## Reusable slot component for CityView. Shows one shop category.
## State: "empty" (not yet bought) or "owned" (level >= 1).
## Tap → EventBus.shop_slot_tapped(shop_id, slot_state)

class_name ShopSlot
extends PanelContainer

@onready var shop_icon: ColorRect = $HBox/ShopIcon
@onready var name_label: Label = $HBox/InfoBox/NameLabel
@onready var level_label: Label = $HBox/InfoBox/LevelLabel
@onready var ips_label: Label = $HBox/InfoBox/IPSLabel
@onready var action_button: Button = $HBox/ActionButton

var shop_id: String:
	get:
		return _shop_id

var _shop_id: String = ""
var _shop_data: Dictionary = {}
var _slot_state: String = "empty"


func _ready() -> void:
	add_to_group("shop_slots")
	action_button.pressed.connect(_on_tapped)


## Initialise slot from static shop definition + current runtime state.
func setup(shop_data: Dictionary, is_owned: bool, level: int, ips: BigNumber) -> void:
	_shop_data = shop_data
	_shop_id = shop_data.get("id", "")
	_update_display(is_owned, level, ips)


## Refresh visuals after a state change (purchase / upgrade).
func refresh(is_owned: bool, level: int, ips: BigNumber) -> void:
	_update_display(is_owned, level, ips)


func is_owned() -> bool:
	return _slot_state == "owned"


func get_shop_id() -> String:
	return _shop_id


func _on_tapped() -> void:
	EventBus.shop_slot_tapped.emit(_shop_id, _slot_state)


# ==========================================================================
# INTERNAL
# ==========================================================================

func _update_display(is_owned: bool, level: int, ips: BigNumber) -> void:
	name_label.text = _shop_data.get("name", _shop_id)

	if is_owned:
		_slot_state = "owned"
		level_label.text = "Lvl %d" % level
		ips_label.text = "%s/sec" % Formatters.format_money(ips)
		action_button.text = "▲"
		var color_hex: String = _shop_data.get("color_primary", "#888888")
		shop_icon.color = Color.from_string(color_hex, Color(0.5, 0.5, 0.5))
	else:
		_slot_state = "empty"
		var unlock_cost = _shop_data.get("unlock_cost", 0)
		level_label.text = "Buy: " + Formatters.format_money(BigNumber.from_float(float(unlock_cost)))
		ips_label.text = ""
		action_button.text = "+"
		shop_icon.color = Color(0.3, 0.3, 0.3)
