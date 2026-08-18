extends FieldIndexer


func _init() -> void:
	name = "condition"
	display_name = "Condition"
	description = "Compares a project variable against a value."
	color = MonologuePalette.LOGIC
	scene_uid = "uid://b6bfebqeejpsg"
	default_value = {"variable": "", "operator": ">=", "value": true}


## A condition points at a variable, so it must be visible to the reverse
## reference index even though its value is a Dictionary rather than a plain id.
func extract_references(value: Variant) -> PackedStringArray:
	if value is Dictionary:
		var variable_id: String = str((value as Dictionary).get("variable", ""))
		if not variable_id.is_empty():
			return PackedStringArray([variable_id])
	return PackedStringArray()
