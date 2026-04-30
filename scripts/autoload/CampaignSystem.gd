## CampaignSystem.gd
## Obsługa marketing campaigns. AUTOLOAD as "CampaignSystem".
##
## Core mechanic Capitalo: gracz nie taps na sklepy — zamiast tego launches campaigns.
## Każda campaign ma: cost, cooldown, base_payout, success_chance, viral_chance.
##
## Roll mechanic (per launch):
##   roll = randf()
##   if roll < viral_chance → VIRAL HIT (10x payout, screen shake)
##   elif roll < viral_chance + success_chance → SUCCESS (1x payout)
##   else → FAIL (0 payout, but campaign still spent)
##
## CRITICAL: Cooldowns tickują nawet offline (clamp do 0).
## CRITICAL: Modyfikatory z reputation, tech tree, managerów wpływają na chances.

extends Node

# ==========================================================================
# STATE
# ==========================================================================

var _campaign_definitions: Array = []


# ==========================================================================
# INIT
# ==========================================================================

func _ready() -> void:
	_load_campaign_data()


func _load_campaign_data() -> void:
	var file = FileAccess.open("res://data/campaigns.json", FileAccess.READ)
	if file == null:
		push_error("[CampaignSystem] Failed to load campaigns.json")
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("[CampaignSystem] Failed to parse campaigns.json")
		file.close()
		return
	file.close()
	_campaign_definitions = json.data.get("campaigns", [])
	print("[CampaignSystem] Loaded %d campaign definitions" % _campaign_definitions.size())


func _process(delta: float) -> void:
	# Tick cooldowns
	var keys_to_remove: Array[String] = []
	for cid in GameState.campaign_cooldowns.keys():
		var remaining = GameState.campaign_cooldowns[cid] - delta
		if remaining <= 0:
			keys_to_remove.append(cid)
		else:
			GameState.campaign_cooldowns[cid] = remaining
	for cid in keys_to_remove:
		GameState.campaign_cooldowns.erase(cid)


# ==========================================================================
# PUBLIC API
# ==========================================================================

## Czy kampania jest dostępna (cooldown == 0, ma cash)?
func is_campaign_available(campaign_id: String) -> bool:
	if GameState.campaign_cooldowns.has(campaign_id):
		return false  # On cooldown
	var def = _get_campaign_definition(campaign_id)
	if def.is_empty():
		return false
	var cost = BigNumber.from_float(def.get("cost", 0.0))
	return GameState.can_afford(cost)


## Odpal kampanię. Zwraca true jeśli się udało.
func launch_campaign(campaign_id: String) -> bool:
	var def = _get_campaign_definition(campaign_id)
	if def.is_empty():
		push_error("[CampaignSystem] Unknown campaign: %s" % campaign_id)
		return false

	var cost = BigNumber.from_float(def.get("cost", 0.0))
	if not GameState.try_spend_money(cost):
		return false

	# Set cooldown
	var cooldown: float = def.get("cooldown_seconds", 1.0)
	GameState.campaign_cooldowns[campaign_id] = cooldown

	GameState.total_campaigns_launched += 1
	GameState.is_dirty = true
	EventBus.campaign_launched.emit(campaign_id)

	# Roll for outcome
	_roll_campaign_outcome(campaign_id, def)

	return true


# ==========================================================================
# OUTCOME ROLL
# ==========================================================================

func _roll_campaign_outcome(campaign_id: String, def: Dictionary) -> void:
	var roll = randf()

	var viral_chance: float = def.get("viral_chance", 0.01)
	var success_chance: float = def.get("success_chance", 0.7)

	# Apply modifiers
	viral_chance *= _get_viral_chance_modifier()
	success_chance *= _get_success_chance_modifier()

	# Cap chances
	viral_chance = clamp(viral_chance, 0.0, 1.0)
	success_chance = clamp(success_chance, 0.0, 1.0 - viral_chance)

	var base_payout = BigNumber.from_float(def.get("base_payout", 0.0))
	var payout: BigNumber
	var result: String

	if roll < viral_chance:
		# VIRAL HIT!
		var multiplier: float = def.get("viral_multiplier", 10.0)
		payout = base_payout.multiply_by_float(multiplier)
		result = "viral"
		GameState.total_viral_hits += 1
		EventBus.viral_hit.emit(campaign_id, multiplier)

	elif roll < viral_chance + success_chance:
		# SUCCESS
		payout = base_payout
		result = "success"

	else:
		# FAIL
		payout = BigNumber.from_float(0.0)
		result = "fail"

	if not payout.is_zero():
		GameState.add_money(payout)

	EventBus.campaign_completed.emit(campaign_id, result, payout)


# ==========================================================================
# MODIFIERS
# ==========================================================================

## Modyfikatory viral chance z tech tree, managerów, reputation, eventów.
func _get_viral_chance_modifier() -> float:
	var modifier: float = 1.0

	# Reputation: high rep boosts viral chance
	if GameState.reputation >= 75:
		modifier *= 1.5
	elif GameState.reputation <= 25:
		modifier *= 0.5

	# TODO: tech tree (np. "Influencer Network" node)
	# TODO: managers (np. Kai's "Trend Spotter" perk)

	return modifier


func _get_success_chance_modifier() -> float:
	var modifier: float = 1.0

	# Reputation
	if GameState.reputation >= 75:
		modifier *= 1.2
	elif GameState.reputation <= 25:
		modifier *= 0.7

	# TODO: tech tree, managers

	return modifier


# ==========================================================================
# HELPERS
# ==========================================================================

func _get_campaign_definition(campaign_id: String) -> Dictionary:
	for c in _campaign_definitions:
		if c.get("id", "") == campaign_id:
			return c
	return {}


## Pozostały cooldown (sekundy). 0 = available.
func get_cooldown_remaining(campaign_id: String) -> float:
	return GameState.campaign_cooldowns.get(campaign_id, 0.0)


## Lista wszystkich campaign IDs.
func get_all_campaign_ids() -> Array[String]:
	var ids: Array[String] = []
	for c in _campaign_definitions:
		if c.has("id"):
			ids.append(c["id"])
	return ids
