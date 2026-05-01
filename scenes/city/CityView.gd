## CityView.gd
## Displays 3 phase_1 shop slots (Fashion, Tech, Food) in a VBoxContainer.
## Reads initial state from GameState on _ready().
## Reacts to EventBus.shop_purchased / shop_upgraded to refresh visuals.
## NEVER writes to GameState directly — only reads + listens.

class_name CityView
extends VBoxContainer

const SHOP_SLOT_SCENE := preload("res://scenes/city/ShopSlot.tscn")
const PHASE_1_SHOP_COUNT := 3

## shop_id → ShopSlot node (typed as Node to avoid class_name scope issues)
var _slots: Dictionary = {}


func _ready() -> void:
	_build_slots()
	EventBus.shop_purchased.connect(_on_shop_purchased)
	EventBus.shop_upgraded.connect(_on_shop_upgraded)


func _exit_tree() -> void:
	if EventBus.shop_purchased.is_connected(_on_shop_purchased):
		EventBus.shop_purchased.disconnect(_on_shop_purchased)
	if EventBus.shop_upgraded.is_connected(_on_shop_upgraded):
		EventBus.shop_upgraded.disconnect(_on_shop_upgraded)


## Returns the ShopSlot node for the given shop_id, or null if not found.
func get_slot(shop_id: String) -> Node:
	return _slots.get(shop_id, null)


# ==========================================================================
# INTERNAL
# ==========================================================================

func _build_slots() -> void:
	var shops_data: Array = DataLoader.load_shops()
	var count := 0
	for shop_data in shops_data:
		if shop_data.get("unlock_phase", "") != "phase_1":
			continue
		if count >= PHASE_1_SHOP_COUNT:
			break
		_create_slot(shop_data)
		count += 1


func _create_slot(shop_data: Dictionary) -> void:
	var slot = SHOP_SLOT_SCENE.instantiate()
	add_child(slot)  # _ready() runs here → @onready vars initialised before setup()
	var shop_id: String = shop_data.get("id", "")
	var is_owned: bool = GameState.has_shop(shop_id)
	var level: int = GameState.get_shop_level(shop_id)
	var ips: BigNumber = EconomyManager.calculate_shop_income(shop_id) if is_owned \
			else BigNumber.from_float(0.0)
	slot.setup(shop_data, is_owned, level, ips)
	_slots[shop_id] = slot


func _on_shop_purchased(shop_id: String) -> void:
	var slot = get_slot(shop_id)
	if slot == null:
		return
	var level := GameState.get_shop_level(shop_id)
	var ips := EconomyManager.calculate_shop_income(shop_id)
	slot.refresh(true, level, ips)


func _on_shop_upgraded(shop_id: String, new_level: int) -> void:
	var slot = get_slot(shop_id)
	if slot == null:
		return
	var ips := EconomyManager.calculate_shop_income(shop_id)
	slot.refresh(true, new_level, ips)
