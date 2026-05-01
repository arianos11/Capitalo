## AudioManager.gd
## Wrapper na audio playback. AUTOLOAD as "AudioManager".
##
## Phase 1: stub. Phase 2: wczytuje pliki z assets/audio/, podpięcie pod EventBus.
## Phase 3: settings (mute SFX / mute music osobno).

extends Node

# ==========================================================================
# CONSTANTS
# ==========================================================================

const SFX_PLAYER_POOL_SIZE: int = 8

# ==========================================================================
# CONFIG
# ==========================================================================

var music_volume_db: float = -6.0
var sfx_volume_db: float = 0.0
var music_muted: bool = false
var sfx_muted: bool = false

# ==========================================================================
# NODES (do utworzenia w Phase 2)
# ==========================================================================

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []

# ==========================================================================
# INIT
# ==========================================================================

func _ready() -> void:
	# Music player
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music"
	add_child(_music_player)

	# SFX pool (8 concurrent sounds)
	for i in range(SFX_PLAYER_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

	# Connect to EventBus events
	EventBus.viral_hit.connect(_on_viral_hit)
	EventBus.shop_purchased.connect(_on_shop_purchased)
	EventBus.campaign_completed.connect(_on_campaign_completed)
	EventBus.prestige_performed.connect(_on_prestige_performed)


# ==========================================================================
# PUBLIC API
# ==========================================================================

func play_sfx(sfx_path: String, volume_offset_db: float = 0.0) -> void:
	if _is_headless() or sfx_muted:
		return
	# Find idle player
	for p in _sfx_players:
		if not p.playing:
			var stream = load(sfx_path)
			if stream == null:
				push_warning("[AudioManager] SFX not found: %s" % sfx_path)
				return
			p.stream = stream
			p.volume_db = sfx_volume_db + volume_offset_db
			p.play()
			return
	# All players busy — just drop the sound (acceptable for SFX)


func play_music(music_path: String, _fade_in_seconds: float = 0.5) -> void:
	if _is_headless() or music_muted:
		return
	var stream = load(music_path)
	if stream == null:
		push_warning("[AudioManager] Music not found: %s" % music_path)
		return
	_music_player.stream = stream
	_music_player.volume_db = music_volume_db
	_music_player.play()
	# TODO: fade-in tween


func stop_music(_fade_out_seconds: float = 0.5) -> void:
	if _is_headless():
		return
	# TODO: fade-out tween
	_music_player.stop()


# ==========================================================================
# INTERNAL
# ==========================================================================

func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


# ==========================================================================
# EVENT HANDLERS
# ==========================================================================

func _on_viral_hit(_campaign_id: String, _multiplier: float) -> void:
	play_sfx("res://assets/audio/sfx/viral_stinger.wav", 3.0)


func _on_shop_purchased(_shop_id: String) -> void:
	play_sfx("res://assets/audio/sfx/shop_unlock.wav")


func _on_campaign_completed(_campaign_id: String, result: String, _payout) -> void:
	match result:
		"success":
			play_sfx("res://assets/audio/sfx/cash_register.wav")
		"viral":
			pass  # Już zagrane przez viral_hit
		"fail":
			play_sfx("res://assets/audio/sfx/fail_trombone.wav", -3.0)


func _on_prestige_performed(_ip_earned: int, _prestige_count: int) -> void:
	play_sfx("res://assets/audio/sfx/prestige_fanfare.wav")
