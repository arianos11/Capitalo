## Formatters.gd
## Static utility class do formatowania liczb, czasu, procentów dla UI.
## Use: Formatters.format_money(big_num), Formatters.format_time(seconds), etc.

class_name Formatters
extends RefCounted


## "$1.23M" / "$5.67B"
static func format_money(value: BigNumber) -> String:
	return "$" + value.to_display()


## "1.2K", "5M" — krótka wersja do HUD
static func format_money_compact(value: BigNumber) -> String:
	return "$" + value.to_display_compact()


## "5h 23m 12s" / "23m 12s" / "12s"
static func format_time(seconds: float) -> String:
	if seconds < 0:
		return "0s"
	var s = int(seconds)
	var h = s / 3600
	var m = (s % 3600) / 60
	var sec = s % 60

	if h > 0:
		return "%dh %dm %ds" % [h, m, sec]
	elif m > 0:
		return "%dm %ds" % [m, sec]
	else:
		return "%ds" % sec


## "23:45" — krótszy zegarkowy format dla cooldownów
static func format_time_short(seconds: float) -> String:
	if seconds < 0:
		return "0:00"
	var s = int(seconds)
	var m = s / 60
	var sec = s % 60
	return "%d:%02d" % [m, sec]


## "+23.5%" / "-12.0%"
static func format_percent(value: float, signed: bool = false) -> String:
	if signed and value > 0:
		return "+%.1f%%" % (value * 100.0)
	return "%.1f%%" % (value * 100.0)


## "x1.5" / "x2.34"
static func format_multiplier(value: float) -> String:
	if value >= 10:
		return "x%.1f" % value
	return "x%.2f" % value


## "5,432" / "1,234,567"
static func format_int_with_commas(value: int) -> String:
	var s = str(abs(value))
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count == 3 and i > 0:
			result = "," + result
			count = 0
	if value < 0:
		result = "-" + result
	return result


## Procent paska postępu, dla UI
static func progress_percent(current: float, target: float) -> float:
	if target <= 0:
		return 0.0
	return clamp(current / target, 0.0, 1.0)
