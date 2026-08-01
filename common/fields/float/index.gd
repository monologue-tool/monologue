extends FieldIndexer


func _init() -> void:
	name = "float"
	display_name = "Float"
	color = Color("45cee9")
	scene_uid = "uid://c7513qgkxx0m8"  # int_field.tscn
	default_value = 0.0
	compatible_types = ["int", "slider"]
	default_settings = {
		"rounded": false,
		"step": 0.1,
		"allow_greater": true,
		"allow_lesser": true,
	}
