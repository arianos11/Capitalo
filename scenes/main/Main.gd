## Main.gd
## Entry point sceny gry. Attached to scenes/main/Main.tscn.
## HUD autonomicznie subskrybuje EventBus — Main.gd nie zarządza cash/IPS labels.

extends Node2D


@onready var debug_button: Button = $UI/Debug/AddMoneyButton
@onready var status_label: Label = $UI/Debug/StatusLabel


func _ready() -> void:
	EventBus.shop_purchased.connect(_on_shop_purchased)
	EventBus.viral_hit.connect(_on_viral_hit)
	EventBus.offline_earnings_paid.connect(_on_offline_earnings)

	debug_button.pressed.connect(_on_debug_add_money)

	print("[Main] Scene ready. Capitalo v0.1 starting...")


func _process(_delta: float) -> void:
	pass


# ==========================================================================
# EVENT HANDLERS
# ==========================================================================

func _on_shop_purchased(shop_id: String) -> void:
	status_label.text = "Shop unlocked: %s" % shop_id


func _on_viral_hit(campaign_id: String, multiplier: float) -> void:
	status_label.text = "VIRAL HIT! %s x%.1f" % [campaign_id, multiplier]


func _on_offline_earnings(amount: BigNumber, seconds: float) -> void:
	var msg = "Offline earnings: %s over %s" % [
		Formatters.format_money(amount),
		Formatters.format_time(seconds)
	]
	status_label.text = msg
	print("[Main] %s" % msg)


# ==========================================================================
# DEBUG
# ==========================================================================

func _on_debug_add_money() -> void:
	GameState.add_money(BigNumber.from_float(1000.0))
	status_label.text = "Debug: +$1,000"
