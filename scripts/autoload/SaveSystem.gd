## SaveSystem.gd
## Save/load do JSON, plus offline earnings calculation. AUTOLOAD as "SaveSystem".
##
## File location: user://savegame.json (handled by Godot per-platform)
##   - Windows: %APPDATA%\Godot\app_userdata\Capitalo\savegame.json
##   - macOS:   ~/Library/Application Support/Godot/app_userdata/Capitalo/savegame.json
##   - iOS/Android: app sandbox storage
##
## CRITICAL: Auto-save co 30 sekund jeśli is_dirty.
## CRITICAL: Save on app pause/resume (mobile lifecycle).
## CRITICAL: Offline earnings — capped at 8h.

extends Node

# ==========================================================================
# CONFIG
# ==========================================================================

const SAVE_FILE_PATH: String = "user://savegame.json"
const BACKUP_FILE_PATH: String = "user://savegame_backup.json"

## Auto-save interval (sekundy).
const AUTOSAVE_INTERVAL: float = 30.0

## Offline earnings cap (sekundy). 8h = 28800s.
const OFFLINE_EARNINGS_CAP_SECONDS: float = 28800.0

## Offline earnings rate (procent income per second). 0.5 = pół normalnego tempa.
const OFFLINE_EARNINGS_RATE: float = 0.5


# ==========================================================================
# STATE
# ==========================================================================

var _autosave_timer: float = 0.0


# ==========================================================================
# INIT
# ==========================================================================

func _ready() -> void:
	# Próbuj załadować save przy starcie
	if has_save():
		load_game()
	else:
		print("[SaveSystem] No save file found — starting fresh")

	# Listen for app pause/resume (mobile)
	get_tree().auto_accept_quit = false


func _process(delta: float) -> void:
	# Auto-save check
	if GameState.is_dirty:
		_autosave_timer += delta
		if _autosave_timer >= AUTOSAVE_INTERVAL:
			save_game()
			_autosave_timer = 0.0


## Mobile lifecycle: app pause = save.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_game()
			get_tree().quit()
		NOTIFICATION_APPLICATION_PAUSED:
			save_game()
		NOTIFICATION_APPLICATION_RESUMED:
			_handle_offline_earnings()


# ==========================================================================
# SAVE / LOAD
# ==========================================================================

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)


func save_game() -> bool:
	var data = GameState.to_dict()
	var json = JSON.stringify(data, "\t")  # pretty-printed for debug

	# Backup old save first (atomic-ish)
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.copy(SAVE_FILE_PATH, BACKUP_FILE_PATH)

	# Write new save
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveSystem] Failed to open save file for writing")
		return false

	file.store_string(json)
	file.close()

	GameState.is_dirty = false
	GameState.last_save_timestamp = Time.get_unix_time_from_system()
	EventBus.game_saved.emit()
	print("[SaveSystem] Game saved")
	return true


func load_game() -> bool:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveSystem] Failed to open save file for reading")
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("[SaveSystem] Failed to parse save JSON: %s" % json.get_error_message())
		# Try backup
		return _load_from_backup()

	var data = json.data
	if not data is Dictionary:
		push_error("[SaveSystem] Save data is not a Dictionary")
		return _load_from_backup()

	GameState.from_dict(data)

	# Po załadowaniu — policz offline earnings
	_handle_offline_earnings()

	print("[SaveSystem] Game loaded")
	return true


func _load_from_backup() -> bool:
	if not FileAccess.file_exists(BACKUP_FILE_PATH):
		push_error("[SaveSystem] No backup save available")
		return false

	push_warning("[SaveSystem] Loading from backup")
	var file = FileAccess.open(BACKUP_FILE_PATH, FileAccess.READ)
	if file == null:
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_text) != OK:
		push_error("[SaveSystem] Backup also corrupted!")
		return false

	GameState.from_dict(json.data)
	return true


# ==========================================================================
# OFFLINE EARNINGS
# ==========================================================================

func _handle_offline_earnings() -> void:
	if GameState.last_save_timestamp <= 0:
		return  # Pierwsze uruchomienie

	var now = Time.get_unix_time_from_system()
	var elapsed = now - GameState.last_save_timestamp

	# Sanity check — clock skew, save z przyszłości
	if elapsed <= 0:
		return

	# Cap at 8h
	var capped_elapsed = min(elapsed, OFFLINE_EARNINGS_CAP_SECONDS)

	# Pobierz aktualny income per second z EconomyManager
	# (EconomyManager musi już być załadowany)
	if not Engine.has_singleton("EconomyManager") and not get_node_or_null("/root/EconomyManager"):
		push_warning("[SaveSystem] EconomyManager not ready — skipping offline earnings")
		return

	var econ = get_node_or_null("/root/EconomyManager")
	if econ == null:
		return

	var ips: BigNumber = econ.get_total_income_per_second()
	if ips.is_zero():
		return

	# Earnings = ips * elapsed * rate
	var earnings = ips.multiply_by_float(capped_elapsed * OFFLINE_EARNINGS_RATE)

	GameState.add_money(earnings)
	EventBus.offline_earnings_paid.emit(earnings, capped_elapsed)

	print("[SaveSystem] Offline earnings: %s over %d seconds (capped at %d)" % [
		earnings.to_display(), int(elapsed), int(capped_elapsed)
	])


# ==========================================================================
# DEBUG / TOOLS
# ==========================================================================

## Usuń save (dla "Delete Save" feature lub debug).
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
	if FileAccess.file_exists(BACKUP_FILE_PATH):
		DirAccess.remove_absolute(BACKUP_FILE_PATH)
	GameState.reset_to_defaults()
	print("[SaveSystem] Save deleted, state reset")
