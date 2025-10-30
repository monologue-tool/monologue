class_name Property extends RefCounted

signal changed
signal value_changed(old_value: Variant, new_value: Variant)

var name: String = ""  # Protected
var value: Variant = 0
var type: String = ""  # Protected
var settings: Dictionary = {}


func _init(pname: String, pvalue: Variant, ptype: String, psettings: Dictionary = {}) -> void:
	name = pname
	value = pvalue
	type = ptype
	settings = psettings


func set_value(new_value: Variant) -> void:
	var old_value: Variant = value
	value = new_value

	changed.emit()
	value_changed.emit(old_value, new_value)


func get_value() -> Variant:
	return value


func get_settings_value(skey: String, default_value: Variant) -> Variant:
	return settings.get(skey, default_value)


func get_display_name() -> String:
	return Util.to_readable_name(settings.get("label", name))


func get_category() -> String:
	return settings.get("category", "General")
