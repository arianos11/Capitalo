## HUD.gd
## Top-bar HUD: cash label, IPS label, settings button.
## Pure EventBus consumer — never reads GameState/EconomyManager in _process.
## Initial snapshot in _ready() avoids one-frame blank labels.

class_name HUD
extends Control

var _last_cash: String = ""
var _last_ips: String = ""

@onready var cash_label: Label = $VBox/CashLabel
@onready var ips_label: Label = $VBox/IPSLabel
@onready var settings_button: Button = $VBox/TitleRow/SettingsButton


func _ready() -> void:
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.income_per_second_changed.connect(_on_ips_changed)
	settings_button.pressed.connect(_on_settings_pressed)
	# Initial render — don't wait for first emit
	_on_money_changed(GameState.money)
	_on_ips_changed(EconomyManager.get_total_income_per_second())


func _exit_tree() -> void:
	if EventBus.money_changed.is_connected(_on_money_changed):
		EventBus.money_changed.disconnect(_on_money_changed)
	if EventBus.income_per_second_changed.is_connected(_on_ips_changed):
		EventBus.income_per_second_changed.disconnect(_on_ips_changed)


func _on_money_changed(new_money: BigNumber) -> void:
	var s := Formatters.format_money(new_money)
	if s != _last_cash:
		_last_cash = s
		cash_label.text = s


func _on_ips_changed(new_ips: BigNumber) -> void:
	var s := "%s/sec" % Formatters.format_money(new_ips)
	if s != _last_ips:
		_last_ips = s
		ips_label.text = s


func _on_settings_pressed() -> void:
	EventBus.settings_requested.emit()
