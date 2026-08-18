extends FieldIndexer


func _init() -> void:
	name = "float"
	display_name = "Float"
	description = "A number with decimals. Drag across it to change it, click to type one."
	color = MonologuePalette.NUMBER
	scene_uid = "uid://dnq7v2mk8xr4c"  # number_field.tscn, shared with int
	default_value = 0.0
	compatible_types = ["int"]
	default_settings = {
		PropertySettings.KEY_ROUNDED: false,
		PropertySettings.KEY_STEP: 0.1,
	}
