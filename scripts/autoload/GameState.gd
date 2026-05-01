## GameState.gd
## Single source of truth for player progress. AUTOLOAD as "GameState".
##
## Wszystko co trzeba zapisać jest TUTAJ. SaveSystem serializuje GameState do JSON.
## Wszystkie systemy (Economy, Campaign, Prestige) modyfikują dane przez GameState.
##
## CRITICAL: Po każdej znaczącej zmianie state'u — emit signal przez EventBus.
## CRITICAL: Save dirty flag — każda zmiana ustawia is_dirty = true. SaveSystem zapisuje co X sekund jeśli dirty.

extends Node

# ==========================================================================
# CORE PROGRESSION
# ==========================================================================

## Aktualne pieniądze gracza (BigNumber).
var money: BigNumber

## Innovation Points zarobione na prestige (do tech tree).
var innovation_points: int = 0

## Liczba prestige executed (na bonusy + flavor).
var prestige_count: int = 0

## Multiplier z prestige (rośnie po każdym prestige).
var prestige_multiplier: float = 1.0

## Reputation 0-100 — wpływa na conversion rate w sklepach.
var reputation: int = 50


# ==========================================================================
# SHOPS DATA
# ==========================================================================

## Map shop_id → ShopData
##   ShopData = {
##     "level": int,
##     "specialization": String (or empty),
##     "manager_id": String (or empty),
##     "purchased_at": float (timestamp)
##   }
var shops: Dictionary = {}


# ==========================================================================
# MANAGERS DATA
# ==========================================================================

## Map manager_id → ManagerData
##   ManagerData = {
##     "hired": bool,
##     "level": int (1-10),
##     "assigned_to_shop": String (or empty)
##   }
var managers: Dictionary = {}


# ==========================================================================
# TECH TREE DATA
# ==========================================================================

## Set of unlocked tech node IDs.
var unlocked_tech: Array[String] = []


# ==========================================================================
# CAMPAIGNS DATA
# ==========================================================================

## Map campaign_id → cooldown_remaining_seconds (float).
var campaign_cooldowns: Dictionary = {}

## Total liczba odpalonych kampanii (do achievementów).
var total_campaigns_launched: int = 0

## Total liczba viral hits (do achievementów).
var total_viral_hits: int = 0

## Map tutorial_step_id → true (step ukończony). Persisted w save.
var tutorial_completed: Dictionary = {}


# ==========================================================================
# META / STATS
# ==========================================================================

## Timestamp ostatniego save'a (Unix epoch seconds).
var last_save_timestamp: float = 0.0

## Total seconds played (kumulatywnie).
var total_play_time_seconds: float = 0.0

## Czy są niezapisane zmiany (dla SaveSystem).
var is_dirty: bool = false

## Wersja save format (do migracji w przyszłości).
const SAVE_FORMAT_VERSION: int = 1


# ==========================================================================
# INIT
# ==========================================================================

func _ready() -> void:
	# Domyślny start
	money = BigNumber.from_float(0.0)
	print("[GameState] Initialized — fresh start")


# ==========================================================================
# CORE OPERATIONS
# ==========================================================================

## Dodaj kasę (po zarobku, kampanii, etc.)
func add_money(amount: BigNumber) -> void:
	money = money.add(amount)
	is_dirty = true
	EventBus.money_changed.emit(money)


## Spróbuj wydać kasę. Zwraca true jeśli się udało.
func try_spend_money(amount: BigNumber) -> bool:
	if money.is_less_than(amount):
		return false
	money = money.subtract(amount)
	is_dirty = true
	EventBus.money_changed.emit(money)
	return true


## Czy stać gracza na X?
func can_afford(amount: BigNumber) -> bool:
	return money.is_greater_or_equal(amount)


# ==========================================================================
# SHOPS API
# ==========================================================================

## Czy sklep jest kupiony (level >= 1)?
func has_shop(shop_id: String) -> bool:
	return shops.has(shop_id) and shops[shop_id].get("level", 0) >= 1


## Pobierz level sklepu (0 = nie kupiony).
func get_shop_level(shop_id: String) -> int:
	if not shops.has(shop_id):
		return 0
	return shops[shop_id].get("level", 0)


## Kup / odblokuj sklep (level 1).
func purchase_shop(shop_id: String) -> void:
	if not shops.has(shop_id):
		shops[shop_id] = {
			"level": 1,
			"specialization": "",
			"manager_id": "",
			"purchased_at": Time.get_unix_time_from_system()
		}
	else:
		shops[shop_id]["level"] = 1
	is_dirty = true
	EventBus.shop_purchased.emit(shop_id)


## Upgrade sklepu o 1 level.
func upgrade_shop(shop_id: String) -> void:
	if not shops.has(shop_id):
		push_error("Cannot upgrade non-existent shop: %s" % shop_id)
		return
	shops[shop_id]["level"] += 1
	is_dirty = true
	EventBus.shop_upgraded.emit(shop_id, shops[shop_id]["level"])


# ==========================================================================
# MANAGERS API
# ==========================================================================

func has_manager(manager_id: String) -> bool:
	return managers.has(manager_id) and managers[manager_id].get("hired", false)


func hire_manager(manager_id: String) -> void:
	managers[manager_id] = {
		"hired": true,
		"level": 1,
		"assigned_to_shop": ""
	}
	is_dirty = true
	EventBus.manager_hired.emit(manager_id)


func upgrade_manager(manager_id: String) -> void:
	if not has_manager(manager_id):
		push_error("Cannot upgrade non-hired manager: %s" % manager_id)
		return
	managers[manager_id]["level"] = min(10, managers[manager_id]["level"] + 1)
	is_dirty = true
	EventBus.manager_upgraded.emit(manager_id, managers[manager_id]["level"])


# ==========================================================================
# TECH TREE API
# ==========================================================================

func has_tech(node_id: String) -> bool:
	return node_id in unlocked_tech


func unlock_tech(node_id: String, ip_cost: int) -> bool:
	if has_tech(node_id):
		return false
	if innovation_points < ip_cost:
		return false
	innovation_points -= ip_cost
	unlocked_tech.append(node_id)
	is_dirty = true
	EventBus.tech_node_unlocked.emit(node_id)
	EventBus.innovation_points_changed.emit(innovation_points)
	return true


# ==========================================================================
# PRESTIGE API
# ==========================================================================

## Wykonaj prestige — reset progresu, wypłać IP, zwiększ multiplier.
func perform_prestige(ip_earned: int) -> void:
	# Naliczamy IP
	innovation_points += ip_earned
	prestige_count += 1

	# Multiplier rośnie wraz z każdym prestige (formuła z GDD §7.4)
	prestige_multiplier = 1.0 + (prestige_count * 0.15)

	# Reset run-specific state — ALE zachowujemy:
	#   - innovation_points (kumulatywne)
	#   - unlocked_tech (permanentne)
	#   - managers hired (permanentni — ale resetujemy ich levele)
	#   - reputation
	money = BigNumber.from_float(0.0)
	shops.clear()
	campaign_cooldowns.clear()

	# Reset manager levels do 1 (zachowujemy hired status)
	for mid in managers.keys():
		if managers[mid].get("hired", false):
			managers[mid]["level"] = 1
			managers[mid]["assigned_to_shop"] = ""

	is_dirty = true
	EventBus.prestige_performed.emit(ip_earned, prestige_count)
	EventBus.prestige_multiplier_changed.emit(prestige_multiplier)


# ==========================================================================
# SERIALIZATION
# ==========================================================================

func to_dict() -> Dictionary:
	return {
		"version": SAVE_FORMAT_VERSION,
		"money": money.to_dict(),
		"innovation_points": innovation_points,
		"prestige_count": prestige_count,
		"prestige_multiplier": prestige_multiplier,
		"reputation": reputation,
		"shops": shops,
		"managers": managers,
		"unlocked_tech": unlocked_tech,
		"campaign_cooldowns": campaign_cooldowns,
		"total_campaigns_launched": total_campaigns_launched,
		"total_viral_hits": total_viral_hits,
		"last_save_timestamp": Time.get_unix_time_from_system(),
		"total_play_time_seconds": total_play_time_seconds,
		"tutorial_completed": tutorial_completed,
	}


func from_dict(data: Dictionary) -> void:
	# Migracja w przyszłości jeśli SAVE_FORMAT_VERSION inny
	var version = data.get("version", 1)
	if version != SAVE_FORMAT_VERSION:
		push_warning("Save version mismatch: file=%d, current=%d. Migration may be needed." % [version, SAVE_FORMAT_VERSION])

	money = BigNumber.from_dict(data.get("money", {"m": 0.0, "e": 0}))
	innovation_points = data.get("innovation_points", 0)
	prestige_count = data.get("prestige_count", 0)
	prestige_multiplier = data.get("prestige_multiplier", 1.0)
	reputation = data.get("reputation", 50)
	shops = data.get("shops", {})
	managers = data.get("managers", {})

	# Type cast Array → Array[String] dla unlocked_tech
	unlocked_tech.clear()
	for t in data.get("unlocked_tech", []):
		unlocked_tech.append(t)

	campaign_cooldowns = data.get("campaign_cooldowns", {})
	total_campaigns_launched = data.get("total_campaigns_launched", 0)
	total_viral_hits = data.get("total_viral_hits", 0)
	last_save_timestamp = data.get("last_save_timestamp", 0.0)
	total_play_time_seconds = data.get("total_play_time_seconds", 0.0)
	tutorial_completed = data.get("tutorial_completed", {})

	is_dirty = false
	EventBus.game_loaded.emit()
	EventBus.money_changed.emit(money)
	EventBus.innovation_points_changed.emit(innovation_points)
	EventBus.prestige_multiplier_changed.emit(prestige_multiplier)
	EventBus.reputation_changed.emit(reputation)


# ==========================================================================
# DEBUG / RESET
# ==========================================================================

## Pełny reset gry (dla debug / "delete save" feature).
func reset_to_defaults() -> void:
	money = BigNumber.from_float(0.0)
	innovation_points = 0
	prestige_count = 0
	prestige_multiplier = 1.0
	reputation = 50
	shops.clear()
	managers.clear()
	unlocked_tech.clear()
	campaign_cooldowns.clear()
	total_campaigns_launched = 0
	total_viral_hits = 0
	total_play_time_seconds = 0.0
	is_dirty = true
	print("[GameState] Reset to defaults")
