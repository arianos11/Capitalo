## BigNumberTest.gd
## Unit tests for BigNumber.
## Run: scenes/main → attach this script as autoload temporarily, or use GUT framework.
##
## To run manually:
##   var test = BigNumberTest.new()
##   test.run_all_tests()

class_name BigNumberTest
extends RefCounted

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []


func run_all_tests() -> void:
	passed = 0
	failed = 0
	failures.clear()

	test_construction()
	test_normalization()
	test_addition()
	test_subtraction()
	test_multiplication()
	test_multiply_by_float()
	test_division()
	test_power()
	test_comparison()
	test_display()
	test_serialization()
	test_edge_cases()

	print("=" .repeat(60))
	print("BigNumber Test Results")
	print("=".repeat(60))
	print("Passed: %d" % passed)
	print("Failed: %d" % failed)
	if failed > 0:
		print("\nFailures:")
		for f in failures:
			print("  ✗ %s" % f)
	else:
		print("\n✓ All tests passed!")


func _assert(condition: bool, test_name: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		failures.append(test_name)
		push_error("BigNumber test FAILED: %s" % test_name)


func _assert_close(a: float, b: float, name: String, tolerance: float = 0.001) -> void:
	_assert(abs(a - b) < tolerance, "%s (expected %f, got %f)" % [name, b, a])


func test_construction() -> void:
	var n1 = BigNumber.new(5.0, 3)
	_assert_close(n1.mantissa, 5.0, "construction mantissa")
	_assert(n1.exponent == 3, "construction exponent")

	var n2 = BigNumber.from_float(1234.0)
	_assert_close(n2.mantissa, 1.234, "from_float mantissa")
	_assert(n2.exponent == 3, "from_float exponent")

	var n3 = BigNumber.from_float(0.0)
	_assert(n3.is_zero(), "from_float zero")


func test_normalization() -> void:
	# 50e2 should become 5e3
	var n1 = BigNumber.new(50.0, 2)
	_assert_close(n1.mantissa, 5.0, "normalize large mantissa")
	_assert(n1.exponent == 3, "normalize exponent up")

	# 0.5e3 should become 5e2
	var n2 = BigNumber.new(0.5, 3)
	_assert_close(n2.mantissa, 5.0, "normalize small mantissa")
	_assert(n2.exponent == 2, "normalize exponent down")

	# 0e0 stays 0e0
	var n3 = BigNumber.new(0.0, 5)
	_assert(n3.exponent == 0, "normalize zero")


func test_addition() -> void:
	var a = BigNumber.new(5.0, 3)  # 5000
	var b = BigNumber.new(3.0, 3)  # 3000
	var c = a.add(b)
	_assert_close(c.to_float(), 8000.0, "5K + 3K = 8K")

	# Different exponents
	var d = BigNumber.new(1.0, 6)   # 1M
	var e = BigNumber.new(5.0, 3)   # 5K
	var f = d.add(e)
	_assert_close(f.to_float(), 1005000.0, "1M + 5K = 1.005M")

	# Adding zero
	var g = BigNumber.new(0.0)
	var h = a.add(g)
	_assert_close(h.to_float(), 5000.0, "5K + 0 = 5K")

	# Very different exponents (one negligible)
	var huge = BigNumber.new(1.0, 100)  # 1e100
	var tiny = BigNumber.new(1.0, 10)   # 1e10 — negligible vs 1e100
	var sum = huge.add(tiny)
	_assert(sum.exponent == 100, "huge + tiny preserves huge")


func test_subtraction() -> void:
	var a = BigNumber.new(5.0, 3)   # 5000
	var b = BigNumber.new(3.0, 3)   # 3000
	var c = a.subtract(b)
	_assert_close(c.to_float(), 2000.0, "5K - 3K = 2K")

	# Result becomes zero
	var d = a.subtract(a)
	_assert(d.is_zero(), "5K - 5K = 0")

	# Negative result
	var e = b.subtract(a)
	_assert_close(e.to_float(), -2000.0, "3K - 5K = -2K")


func test_multiplication() -> void:
	var a = BigNumber.new(2.0, 3)   # 2000
	var b = BigNumber.new(3.0, 3)   # 3000
	var c = a.multiply(b)
	_assert_close(c.to_float(), 6000000.0, "2K * 3K = 6M")

	# Multiply by zero
	var z = BigNumber.new(0.0)
	var d = a.multiply(z)
	_assert(d.is_zero(), "2K * 0 = 0")

	# Very large multiplication
	var huge1 = BigNumber.new(1.0, 50)
	var huge2 = BigNumber.new(1.0, 50)
	var huge_product = huge1.multiply(huge2)
	_assert(huge_product.exponent == 100, "1e50 * 1e50 = 1e100")


func test_multiply_by_float() -> void:
	var a = BigNumber.new(5.0, 6)   # 5M
	var b = a.multiply_by_float(0.5)
	_assert_close(b.to_float(), 2500000.0, "5M * 0.5 = 2.5M")

	var c = a.multiply_by_float(2.0)
	_assert_close(c.to_float(), 10000000.0, "5M * 2.0 = 10M")

	var d = a.multiply_by_float(0.0)
	_assert(d.is_zero(), "5M * 0.0 = 0")


func test_division() -> void:
	var a = BigNumber.new(6.0, 6)   # 6M
	var b = BigNumber.new(2.0, 3)   # 2K
	var c = a.divide(b)
	_assert_close(c.to_float(), 3000.0, "6M / 2K = 3K")

	var d = BigNumber.new(1.0, 0)
	var e = BigNumber.new(2.0, 0)
	var f = d.divide(e)
	_assert_close(f.to_float(), 0.5, "1 / 2 = 0.5")


func test_power() -> void:
	var a = BigNumber.new(2.0, 0)   # 2
	var b = a.power(10.0)            # 2^10 = 1024
	_assert_close(b.to_float(), 1024.0, "2^10 = 1024")

	# Exponential growth example (idle game core)
	var base = BigNumber.from_float(1.15)
	var grown = base.power(50.0)     # 1.15^50 ~= 1083.66
	_assert(grown.to_float() > 1000.0 and grown.to_float() < 1100.0, "1.15^50 ~= 1084")


func test_comparison() -> void:
	var a = BigNumber.new(5.0, 3)   # 5K
	var b = BigNumber.new(3.0, 3)   # 3K
	var c = BigNumber.new(5.0, 3)   # 5K (same as a)

	_assert(a.compare(b) == 1, "5K > 3K")
	_assert(b.compare(a) == -1, "3K < 5K")
	_assert(a.compare(c) == 0, "5K == 5K")

	_assert(a.is_greater_than(b), "is_greater_than")
	_assert(a.is_greater_or_equal(c), "is_greater_or_equal")
	_assert(b.is_less_than(a), "is_less_than")

	# Different exponents
	var huge = BigNumber.new(1.0, 100)
	var small = BigNumber.new(9.99, 99)
	_assert(huge.is_greater_than(small), "1e100 > 9.99e99")


func test_display() -> void:
	_assert(BigNumber.new(0.0).to_display() == "0", "0 displays as 0")
	_assert(BigNumber.new(5.0, 0).to_display() == "5.00", "5 displays as 5.00")
	_assert(BigNumber.new(1.234, 3).to_display() == "1.23K", "1.234K → 1.23K")
	_assert(BigNumber.new(5.67, 6).to_display() == "5.67M", "5.67M")
	_assert(BigNumber.new(1.0, 9).to_display() == "1.00B", "1B")
	_assert(BigNumber.new(1.0, 12).to_display() == "1.00T", "1T")

	# Beyond standard suffixes
	var massive = BigNumber.new(1.0, 70)  # Beyond Vg
	var display = massive.to_display()
	_assert("e" in display or "Vg" in display, "very large uses scientific or last suffix")


func test_serialization() -> void:
	var a = BigNumber.new(7.42, 15)
	var d = a.to_dict()
	_assert("m" in d and "e" in d, "to_dict has m and e")

	var b = BigNumber.from_dict(d)
	_assert(a.compare(b) == 0, "round-trip serialization")


func test_edge_cases() -> void:
	# Subtract from self → zero
	var a = BigNumber.new(123.456, 50)
	_assert(a.subtract(a).is_zero(), "x - x = 0")

	# Multiply identity
	var one = BigNumber.new(1.0, 0)
	var b = a.multiply(one)
	_assert(a.compare(b) == 0, "x * 1 = x")

	# Division by zero (should not crash)
	var zero = BigNumber.new(0.0)
	var result = a.divide(zero)
	_assert(result.is_zero(), "division by zero returns 0 (and logs error)")

	# Negative numbers
	var neg = BigNumber.new(-5.0, 3)
	var pos = BigNumber.new(3.0, 3)
	_assert_close(neg.add(pos).to_float(), -2000.0, "-5K + 3K = -2K")
