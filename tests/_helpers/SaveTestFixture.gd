## SaveTestFixture.gd
## Static helper for SaveRoundTripTest: builds maximal GameState dict, reads/writes
## test JSON files, cleans up after. Zero game code changes — test-only.

class_name SaveTestFixture
extends RefCounted

## Write a Dictionary as JSON to the given user:// path.
static func write_json(path: String, dict: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveTestFixture] Cannot open for write: %s" % path)
		return
	file.store_string(JSON.stringify(dict, "\t"))
	file.close()


## Write raw string (e.g. garbage) to the given user:// path.
static func write_raw(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveTestFixture] Cannot open for write: %s" % path)
		return
	file.store_string(content)
	file.close()


## Read and parse JSON from user:// path. Returns {} on error.
static func read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	var result: Variant = json.data
	if result is Dictionary:
		return result
	return {}


## Delete test files. Silently ignores missing files.
static func cleanup_test_files(paths: Array[String]) -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	for path in paths:
		var filename := path.replace("user://", "")
		if dir.file_exists(filename):
			dir.remove(filename)


## Reset all GameState fields to defaults, including fields reset_to_defaults()
## misses (tutorial_completed, last_save_timestamp). Test-only seam.
static func reset_game_state(gs: Variant) -> void:
	gs.reset_to_defaults()
	gs.tutorial_completed = {}
	gs.last_save_timestamp = 0.0


## Build a maximal GameState dict — every field at a non-default value.
## Used by test_all_fields_present_after_roundtrip.
static func make_maximal_dict() -> Dictionary:
	return {
		"version": 1,
		"money": {"m": 4.567, "e": 12},
		"innovation_points": 42,
		"prestige_count": 3,
		"prestige_multiplier": 1.45,
		"reputation": 77,
		"shops": {
			"fashion": {"level": 5, "specialization": "premium", "manager_id": "mgr_alex", "purchased_at": 1735000000.0},
			"tech": {"level": 2, "specialization": "", "manager_id": "", "purchased_at": 1735001000.0},
		},
		"managers": {
			"mgr_alex": {"hired": true, "level": 3, "assigned_to_shop": "fashion"},
		},
		"unlocked_tech": ["mkt_node_1", "mkt_node_2"],
		"campaign_cooldowns": {"flyers": 1.5, "facebook": 3.2},
		"total_campaigns_launched": 99,
		"total_viral_hits": 7,
		"last_save_timestamp": 1735050000.0,
		"total_play_time_seconds": 3600.0,
		"tutorial_completed": {"first_shop": true, "first_campaign": true},
	}
