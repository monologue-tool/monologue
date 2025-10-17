class_name Property extends RefCounted

var name: String = ""
var value: Variant = 0
var type: String = ""
var options: Dictionary = {}
var _observers: Array = []


func _init(pname: String, pvalue: Variant, ptype: String, poptions: Dictionary = {}) -> void:
	name = pname
	value = pvalue
	type = ptype
	options = poptions


func set_value(new_value: Variant) -> void:
	var old_value: Variant = value
	value = new_value
	_notify_change(old_value, new_value)


func get_value() -> Variant:
	return value


func add_observer(callback: Callable) -> void:
	if callback in _observers:
		push_warning("Observer is already registered.")
		return

	_observers.append(callback)


func _notify_change(old_value: Variant, new_value: Variant) -> void:
	for observer: Callable in _observers:
		if not observer.is_valid():
			return

		observer.call(old_value, new_value)


func get_display_name() -> String:
	return Util.to_readable_name(options.get("label", name))


func get_category() -> String:
	return options.get("category", "General")
