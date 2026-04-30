## SignalSpy.gd
## Minimal signal spy for headless tests.
## Connect to a signal, then check count and last_args.
##
## Usage:
##   var spy = SignalSpy.new()
##   EventBus.shop_slot_tapped.connect(spy.on_2)
##   # ... trigger signal ...
##   assert(spy.count == 1)
##   assert(spy.last_args == ["fashion", "empty"])
##   EventBus.shop_slot_tapped.disconnect(spy.on_2)

class_name SignalSpy
extends RefCounted

var count: int = 0
var last_args: Array = []


func on_0() -> void:
	count += 1
	last_args = []


func on_1(a: Variant) -> void:
	count += 1
	last_args = [a]


func on_2(a: Variant, b: Variant) -> void:
	count += 1
	last_args = [a, b]


func reset() -> void:
	count = 0
	last_args = []
