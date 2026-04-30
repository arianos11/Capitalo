## BigNumber.gd
## Idle game number representation supporting values up to 10^308+
## Stored as {mantissa: 1.0..10.0, exponent: int}
##
## Usage:
##   var a = BigNumber.new(5.0, 3)        # 5e3 = 5000
##   var b = BigNumber.from_float(1234)   # 1.234e3
##   var c = a.add(b)                     # 6.234e3
##   var d = a.multiply(b)                # 6.17e6
##   print(c.to_display())                # "6.23K"
##
## CRITICAL: Always normalize after any arithmetic operation.
## CRITICAL: Idle games operate on numbers 10^100+, regular floats break.
## CRITICAL: This class must remain serializable (used in save system).

class_name BigNumber
extends RefCounted

# ==========================================================================
# CONSTANTS
# ==========================================================================

## Suffix list from idle game conventions (AdVenture Capitalist, Cookie Clicker)
## Index = exponent / 3
## Examples: 1K = 10^3, 1M = 10^6, 1B = 10^9, 1T = 10^12, 1Qa = 10^15...
const SUFFIXES: Array[String] = [
	"",     # 10^0 - 10^2
	"K",    # 10^3 (Thousand)
	"M",    # 10^6 (Million)
	"B",    # 10^9 (Billion)
	"T",    # 10^12 (Trillion)
	"Qa",   # 10^15 (Quadrillion)
	"Qi",   # 10^18 (Quintillion)
	"Sx",   # 10^21 (Sextillion)
	"Sp",   # 10^24 (Septillion)
	"Oc",   # 10^27 (Octillion)
	"No",   # 10^30 (Nonillion)
	"Dc",   # 10^33 (Decillion)
	"Ud",   # 10^36 (Undecillion)
	"Dd",   # 10^39 (Duodecillion)
	"Td",   # 10^42 (Tredecillion)
	"Qad",  # 10^45 (Quattuordecillion)
	"Qid",  # 10^48 (Quindecillion)
	"Sxd",  # 10^51 (Sexdecillion)
	"Spd",  # 10^54 (Septendecillion)
	"Ocd",  # 10^57 (Octodecillion)
	"Nod",  # 10^60 (Novemdecillion)
	"Vg",   # 10^63 (Vigintillion)
]

# ==========================================================================
# PROPERTIES
# ==========================================================================

var mantissa: float = 0.0
var exponent: int = 0

# ==========================================================================
# CONSTRUCTORS
# ==========================================================================

func _init(m: float = 0.0, e: int = 0) -> void:
	mantissa = m
	exponent = e
	normalize()


## Create from a regular float. Handles 0, negative, and very large values.
static func from_float(value: float) -> BigNumber:
	if value == 0:
		return BigNumber.new(0.0, 0)
	var sign_v: float = 1.0 if value > 0 else -1.0
	var abs_v: float = abs(value)
	var exp: int = int(floor(log(abs_v) / log(10.0)))
	var mant: float = abs_v / pow(10.0, exp)
	return BigNumber.new(mant * sign_v, exp)


## Create from save data dict (used by SaveSystem).
static func from_dict(d: Dictionary) -> BigNumber:
	return BigNumber.new(d.get("m", 0.0), d.get("e", 0))


# ==========================================================================
# NORMALIZATION
# ==========================================================================

## Ensure mantissa is in range [1.0, 10.0) for non-zero values, or 0.0 with exp=0.
func normalize() -> void:
	if mantissa == 0:
		exponent = 0
		return

	# Handle large mantissas
	while abs(mantissa) >= 10.0:
		mantissa /= 10.0
		exponent += 1

	# Handle small mantissas
	while abs(mantissa) < 1.0 and mantissa != 0.0:
		mantissa *= 10.0
		exponent -= 1


# ==========================================================================
# ARITHMETIC
# ==========================================================================

## Returns NEW BigNumber. Does not modify self.
func add(other: BigNumber) -> BigNumber:
	if mantissa == 0:
		return BigNumber.new(other.mantissa, other.exponent)
	if other.mantissa == 0:
		return BigNumber.new(mantissa, exponent)

	# Align exponents (shift smaller one)
	var exp_diff: int = exponent - other.exponent
	if exp_diff > 15:
		# Other is negligibly small
		return BigNumber.new(mantissa, exponent)
	elif exp_diff < -15:
		# Self is negligibly small
		return BigNumber.new(other.mantissa, other.exponent)

	if exp_diff >= 0:
		# Bring other up to self's exponent
		var aligned_other_m: float = other.mantissa / pow(10.0, exp_diff)
		return BigNumber.new(mantissa + aligned_other_m, exponent)
	else:
		# Bring self up to other's exponent
		var aligned_self_m: float = mantissa / pow(10.0, -exp_diff)
		return BigNumber.new(aligned_self_m + other.mantissa, other.exponent)


## Returns NEW BigNumber: self - other
func subtract(other: BigNumber) -> BigNumber:
	var negated = BigNumber.new(-other.mantissa, other.exponent)
	return add(negated)


## Returns NEW BigNumber: self * other
func multiply(other: BigNumber) -> BigNumber:
	if mantissa == 0 or other.mantissa == 0:
		return BigNumber.new(0.0, 0)
	return BigNumber.new(mantissa * other.mantissa, exponent + other.exponent)


## Returns NEW BigNumber: self * scalar
func multiply_by_float(scalar: float) -> BigNumber:
	if mantissa == 0 or scalar == 0:
		return BigNumber.new(0.0, 0)
	return BigNumber.new(mantissa * scalar, exponent)


## Returns NEW BigNumber: self / other
func divide(other: BigNumber) -> BigNumber:
	if other.mantissa == 0:
		push_error("BigNumber: division by zero")
		return BigNumber.new(0.0, 0)
	if mantissa == 0:
		return BigNumber.new(0.0, 0)
	return BigNumber.new(mantissa / other.mantissa, exponent - other.exponent)


## Returns NEW BigNumber: self ^ exp
func power(exp: float) -> BigNumber:
	if mantissa == 0:
		return BigNumber.new(0.0, 0)
	# (m * 10^e) ^ p = m^p * 10^(e*p)
	var new_mantissa: float = pow(mantissa, exp)
	var new_exponent: float = float(exponent) * exp
	# new_exponent might be fractional - convert
	var int_part: int = int(floor(new_exponent))
	var frac_part: float = new_exponent - float(int_part)
	new_mantissa *= pow(10.0, frac_part)
	return BigNumber.new(new_mantissa, int_part)


# ==========================================================================
# COMPARISON
# ==========================================================================

## Returns: -1 if self < other, 0 if equal, 1 if self > other
func compare(other: BigNumber) -> int:
	# Handle zero edge cases
	if mantissa == 0 and other.mantissa == 0:
		return 0
	if mantissa == 0:
		return -1 if other.mantissa > 0 else 1
	if other.mantissa == 0:
		return 1 if mantissa > 0 else -1

	# Different signs
	var self_pos: bool = mantissa > 0
	var other_pos: bool = other.mantissa > 0
	if self_pos and not other_pos:
		return 1
	if other_pos and not self_pos:
		return -1

	# Same sign — compare exponents first
	if exponent > other.exponent:
		return 1 if self_pos else -1
	if exponent < other.exponent:
		return -1 if self_pos else 1

	# Same exponent — compare mantissas
	if mantissa > other.mantissa:
		return 1
	if mantissa < other.mantissa:
		return -1
	return 0


func is_greater_than(other: BigNumber) -> bool:
	return compare(other) > 0

func is_greater_or_equal(other: BigNumber) -> bool:
	return compare(other) >= 0

func is_less_than(other: BigNumber) -> bool:
	return compare(other) < 0

func is_zero() -> bool:
	return mantissa == 0


# ==========================================================================
# DISPLAY
# ==========================================================================

## Format for UI display: "1.23K", "5.67M", "1.20 Vg" etc.
func to_display() -> String:
	if mantissa == 0:
		return "0"

	# Handle small numbers (< 1000) — show as plain number
	if exponent < 3:
		var value: float = mantissa * pow(10.0, exponent)
		if value < 10:
			return "%.2f" % value
		elif value < 100:
			return "%.1f" % value
		else:
			return "%.0f" % value

	# Calculate suffix index
	var suffix_idx: int = exponent / 3
	var display_exp: int = exponent % 3

	# Beyond named suffix list — use scientific notation
	if suffix_idx >= SUFFIXES.size():
		return "%.2fe%d" % [mantissa, exponent]

	# Format display mantissa with leading exponent shift
	var display_mantissa: float = mantissa * pow(10.0, display_exp)

	if display_mantissa < 10:
		return "%.2f%s" % [display_mantissa, SUFFIXES[suffix_idx]]
	elif display_mantissa < 100:
		return "%.1f%s" % [display_mantissa, SUFFIXES[suffix_idx]]
	else:
		return "%.0f%s" % [display_mantissa, SUFFIXES[suffix_idx]]


## Compact display for very long values (e.g., HUD): "1.23K", "5M", "8B"
func to_display_compact() -> String:
	if mantissa == 0:
		return "0"
	if exponent < 3:
		return "%.0f" % (mantissa * pow(10.0, exponent))

	var suffix_idx: int = exponent / 3
	var display_exp: int = exponent % 3
	if suffix_idx >= SUFFIXES.size():
		return "%.0fe%d" % [mantissa, exponent]
	var display_mantissa: float = mantissa * pow(10.0, display_exp)
	return "%.1f%s" % [display_mantissa, SUFFIXES[suffix_idx]]


## Convert to plain float (for small values or rough approximations).
## WARNING: Loses precision for values > 10^15.
func to_float() -> float:
	if mantissa == 0:
		return 0.0
	return mantissa * pow(10.0, exponent)


# ==========================================================================
# SERIALIZATION
# ==========================================================================

## Convert to dict for JSON saving.
func to_dict() -> Dictionary:
	return {"m": mantissa, "e": exponent}


# ==========================================================================
# DEBUG
# ==========================================================================

func _to_string() -> String:
	return "BigNumber(%fe%d → %s)" % [mantissa, exponent, to_display()]
