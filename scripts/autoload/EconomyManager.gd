## EconomyManager.gd
## Silnik ekonomii — calculates income per second, processes income tick. AUTOLOAD as "EconomyManager".
##
## Formuły z GDD §7 + Capitalo_Economy_v1.xlsx.
##
## Income per shop per second:
##   base_income * level_multiplier * manager_multiplier * tech_multiplier * prestige_multiplier
##   * specialization_bonus * reputation_modifier * event_modifier
##
## CRITICAL: Tick co 0.1s (10 razy/sek). Floating numbers spawn co tick.
## CRITICAL: Wszystkie multipliers są mnożone (nie dodawane). Order doesn't matter.

extends Node

# ==========================================================================
# CONFIG
# ==========================================================================

## Tick rate — jak często naliczamy income.
const TICK_INTERVAL: float = 0.1  # 10x per second

## Level multiplier formula: 1.0 + (level - 1) * LEVEL_MULTIPLIER_INCREMENT
const LEVEL_MULTIPLIER_INCREMENT: float = 0.07  # GDD §7.2

## Manager level multiplier formula: 1.0 + manager_level * MANAGER_MULTIPLIER_INCREMENT
const MANAGER_MULTIPLIER_INCREMENT: float = 0.10  # GDD §7.3


# ==========================================================================
# STATE
# ==========================================================================

var _tick_accumulator: float = 0.0

## Cached shop definitions loaded from data/shops.json.
var _shop_definitions: Dictionary = {}

## Cached manager definitions.
var _manager_definitions: Dictionary = {}

## Cached tech tree definitions.
var _tech_definitions: Dictionary = {}

## Cached campaign definitions.
var _campaign_definitions: Dictionary = {}

## Latest computed total income per second.
var _cached_total_ips: BigNumber


# ==========================================================================
# INIT
# ==========================================================================

func _ready() -> void:
	_cached_total_ips = BigNumber.from_float(0.0)
	_load_data_files()
	# Recompute cache when shops change
	EventBus.shop_purchased.connect(_invalidate_cache)
	EventBus.shop_upgraded.connect(_invalidate_cache)
	EventBus.manager_hired.connect(_invalidate_cache)
	EventBus.manager_upgraded.connect(_invalidate_cache)
	EventBus.tech_node_unlocked.connect(_invalidate_cache)
	EventBus.prestige_multiplier_changed.connect(_invalidate_cache)


func _load_data_files() -> void:
	_shop_definitions = _load_json("res://data/shops.json")
	_manager_definitions = _load_json("res://data/managers.json")
	_tech_definitions = _load_json("res://data/tech_tree.json")
	_campaign_definitions = _load_json("res://data/campaigns.json")
	print("[EconomyManager] Data files loaded")


func _load_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[EconomyManager] Failed to load %s" % path)
		return {}
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("[EconomyManager] Failed to parse %s" % path)
		file.close()
		return {}
	file.close()
	return json.data


# ==========================================================================
# TICK
# ==========================================================================

func _process(delta: float) -> void:
	GameState.total_play_time_seconds += delta
	_tick_accumulator += delta

	while _tick_accumulator >= TICK_INTERVAL:
		_process_income_tick(TICK_INTERVAL)
		_tick_accumulator -= TICK_INTERVAL


func _process_income_tick(tick_seconds: float) -> void:
	var total_ips = get_total_income_per_second()
	if total_ips.is_zero():
		return

	var income_this_tick = total_ips.multiply_by_float(tick_seconds)
	GameState.add_money(income_this_tick)


# ==========================================================================
# INCOME CALCULATION
# ==========================================================================

## Total income per second across all owned shops.
## Cached — invalidated on state changes.
func get_total_income_per_second() -> BigNumber:
	if _cached_total_ips != null and not _cache_dirty:
		return _cached_total_ips

	var total = BigNumber.from_float(0.0)
	for shop_id in GameState.shops.keys():
		var shop_income = calculate_shop_income(shop_id)
		total = total.add(shop_income)

	_cached_total_ips = total
	_cache_dirty = false

	EventBus.income_per_second_changed.emit(total)
	return total


var _cache_dirty: bool = true

func _invalidate_cache(_a = null, _b = null) -> void:
	_cache_dirty = true


## Income generowany przez konkretny sklep (per second).
func calculate_shop_income(shop_id: String) -> BigNumber:
	var shop_state = GameState.shops.get(shop_id, {})
	var level: int = shop_state.get("level", 0)
	if level <= 0:
		return BigNumber.from_float(0.0)

	var shop_def = _get_shop_definition(shop_id)
	if shop_def.is_empty():
		return BigNumber.from_float(0.0)

	# Base income from definition
	var base_income: float = shop_def.get("base_income_per_sec", 0.0)
	var income = BigNumber.from_float(base_income)

	# Level multiplier: 1.0 + (level-1) * 0.07 — z time also multiplicative growth
	# Ale w idle games income też skaluje się exponentially with level
	# Z GDD §7.2: shop_income = base * (1.07 ^ (level-1)) * level_const
	var level_mult = pow(1.07, level - 1) * level
	income = income.multiply_by_float(level_mult)

	# Manager multiplier
	var manager_id: String = shop_state.get("manager_id", "")
	if not manager_id.is_empty() and GameState.has_manager(manager_id):
		var mgr_level = GameState.managers[manager_id].get("level", 1)
		var mgr_mult = 1.0 + (mgr_level * MANAGER_MULTIPLIER_INCREMENT)
		income = income.multiply_by_float(mgr_mult)

	# Specialization bonus
	var spec_id: String = shop_state.get("specialization", "")
	if not spec_id.is_empty():
		var spec_bonus = _get_specialization_bonus(shop_id, spec_id)
		income = income.multiply_by_float(spec_bonus)

	# Tech tree multipliers (global + per-category)
	var tech_mult = _get_tech_multiplier_for_shop(shop_id)
	income = income.multiply_by_float(tech_mult)

	# Prestige multiplier
	income = income.multiply_by_float(GameState.prestige_multiplier)

	# Reputation modifier (50 = neutral, 0-49 penalty, 51-100 bonus)
	# 0 reputation = -50%, 100 reputation = +50%
	var rep_mod = 0.5 + (GameState.reputation / 100.0)
	income = income.multiply_by_float(rep_mod)

	return income


func _get_shop_definition(shop_id: String) -> Dictionary:
	# shops.json structure: {"shops": [{"id": "fashion", ...}, ...]}
	var shops_list = _shop_definitions.get("shops", [])
	for s in shops_list:
		if s.get("id", "") == shop_id:
			return s
	return {}


func _get_specialization_bonus(shop_id: String, spec_id: String) -> float:
	var shop_def = _get_shop_definition(shop_id)
	var specs = shop_def.get("specializations", [])
	for s in specs:
		if s.get("id", "") == spec_id:
			return s.get("multiplier", 1.0)
	return 1.0


func _get_tech_multiplier_for_shop(shop_id: String) -> float:
	# Iterate through unlocked tech nodes, sum their bonuses
	var multiplier: float = 1.0
	var nodes_list = _tech_definitions.get("nodes", [])
	for node_id in GameState.unlocked_tech:
		for node in nodes_list:
			if node.get("id", "") == node_id:
				var effects = node.get("effects", {})
				# Global income bonus
				if effects.has("global_income_mult"):
					multiplier *= effects["global_income_mult"]
				# Category-specific bonus
				if effects.has("category_income_mult"):
					var cat_data = effects["category_income_mult"]
					if cat_data.get("category", "") == shop_id:
						multiplier *= cat_data.get("multiplier", 1.0)
				break
	return multiplier


# ==========================================================================
# COSTS
# ==========================================================================

## Cena ulepszenia sklepu do następnego levela.
## Z GDD §7.2: cost = base_cost * (1.15 ^ current_level)
func get_shop_upgrade_cost(shop_id: String) -> BigNumber:
	var shop_def = _get_shop_definition(shop_id)
	if shop_def.is_empty():
		return BigNumber.from_float(0.0)

	var base_cost: float = shop_def.get("base_cost", 100.0)
	var current_level = GameState.get_shop_level(shop_id)
	var cost = BigNumber.from_float(base_cost)
	cost = cost.multiply_by_float(pow(1.15, current_level))
	return cost


## Cena zatrudnienia managera.
func get_manager_hire_cost(manager_id: String) -> BigNumber:
	var mgr_list = _manager_definitions.get("managers", [])
	for m in mgr_list:
		if m.get("id", "") == manager_id:
			return BigNumber.from_float(m.get("hire_cost", 1000.0))
	return BigNumber.from_float(0.0)


## Cena upgrade'u managera (level up).
func get_manager_upgrade_cost(manager_id: String) -> BigNumber:
	var mgr_list = _manager_definitions.get("managers", [])
	for m in mgr_list:
		if m.get("id", "") == manager_id:
			var base = m.get("upgrade_cost_base", 5000.0)
			var current_level = GameState.managers.get(manager_id, {}).get("level", 1)
			return BigNumber.from_float(base * pow(2.0, current_level - 1))
	return BigNumber.from_float(0.0)
