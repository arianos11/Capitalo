## DataLoader.gd
## Static utility do ładowania danych z res://data/*.json.
## Wszystkie systemy (EconomyManager, CampaignSystem, TechTree) używają tego.
##
## Cache w pamięci po pierwszym load — JSONy są małe.

class_name DataLoader
extends RefCounted


static var _cache: Dictionary = {}


## Załaduj JSON z path. Zwraca Dictionary lub {} przy błędzie.
static func load_json(path: String, use_cache: bool = true) -> Dictionary:
	if use_cache and _cache.has(path):
		return _cache[path]

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[DataLoader] Failed to open: %s" % path)
		return {}

	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(text) != OK:
		push_error("[DataLoader] JSON parse error in %s: %s" % [path, json.get_error_message()])
		return {}

	if not json.data is Dictionary:
		push_error("[DataLoader] %s root is not Dictionary" % path)
		return {}

	if use_cache:
		_cache[path] = json.data
	return json.data


## Wyczyść cache (np. po reload danych w trybie debug).
static func clear_cache() -> void:
	_cache.clear()


# ==========================================================================
# CONVENIENCE METHODS
# ==========================================================================

static func load_shops() -> Array:
	return load_json("res://data/shops.json").get("shops", [])


static func load_managers() -> Array:
	return load_json("res://data/managers.json").get("managers", [])


static func load_campaigns() -> Array:
	return load_json("res://data/campaigns.json").get("campaigns", [])


static func load_tech_tree() -> Array:
	return load_json("res://data/tech_tree.json").get("nodes", [])
