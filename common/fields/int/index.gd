extends FieldIndexer


func _init() -> void:
	name = "int"
	display_name = "Integer"
	description = "A whole number. Drag across it to change it, click to type one."
	color = MonologuePalette.NUMBER
	scene_uid = "uid://dnq7v2mk8xr4c"  # number_field.tscn, shared with float
	default_value = 0
	compatible_types = ["float"]
	default_settings = {
		PropertySettings.KEY_ROUNDED: true,
		PropertySettings.KEY_STEP: 1.0,
	}
