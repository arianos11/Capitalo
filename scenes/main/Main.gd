## Main.gd
## Entry point sceny gry. Attached to scenes/main/Main.tscn.
##
## Phase 1 placeholder: wyświetla cash, manual click button do dodawania kasy (debug),
## listę sklepów (placeholder), basic UI test.

extends Node2D


@onready var cash_label: Label = $UI/HUD/CashLabel
@onready var ips_label: Label = $UI/HUD/IPSLabel
@onready var debug_button: Button = $UI/Debug/AddMoneyButton
@onready var status_label: Label = $UI/Debug/StatusLabel


func _ready() -> void:
	# Connect to events
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.income_per_second_changed.connect(_on_ips_changed)
	EventBus.shop_purchased.connect(_on_shop_purchased)
	EventBus.viral_hit.connect(_on_viral_hit)
	EventBus.offline_earnings_paid.connect(_on_offline_earnings)

	debug_button.pressed.connect(_on_debug_add_money)

	# Initial UI update
	_on_money_changed(GameState.money)
	_on_ips_changed(EconomyManager.get_total_income_per_second())

	print("[Main] Scene ready. Capitalo v0.1 starting...")


func _process(_delta: float) -> void:
	# IPS może się zmieniać między event-ami (np. event/reputation timer) — refresh co frame
	# (potem optymalizacja: tylko gdy faktycznie się zmienia)
	pass


# ==========================================================================
# EVENT HANDLERS
# ==========================================================================

func _on_money_changed(new_money: BigNumber) -> void:
	cash_label.text = Formatters.format_money(new_money)


func _on_ips_changed(new_ips: BigNumber) -> void:
	ips_label.text = "%s/sec" % Formatters.format_money(new_ips)


func _on_shop_purchased(shop_id: String) -> void:
	status_label.text = "Shop unlocked: %s" % shop_id


func _on_viral_hit(campaign_id: String, multiplier: float) -> void:
	status_label.text = "🚀 VIRAL HIT! %s x%.1f" % [campaign_id, multiplier]
	# TODO: screen shake, particles


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
	# Add $1000 for testing
	GameState.add_money(BigNumber.from_float(1000.0))
	status_label.text = "Debug: +$1,000"
