## RunBigNumberTest.gd
## Headless runner wrapper around legacy BigNumberTest (extends RefCounted).
## Run: godot --headless --script tests/RunBigNumberTest.gd --path .

extends SceneTree


func _initialize() -> void:
	var test = BigNumberTest.new()
	test.run_all_tests()

	if test.failed > 0:
		push_error("BigNumber tests failed: %d/%d" % [test.failed, test.passed + test.failed])
		quit(1)
	else:
		print("✓ BigNumberTest: %d/%d passed" % [test.passed, test.passed + test.failed])
		quit(0)
