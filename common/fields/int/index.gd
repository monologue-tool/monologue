extends FieldIndexer


func _init() -> void:
	name = "int"
	display_name = "Integer"
	color = Color("45cee9")
	scene_uid = "uid://c7513qgkxx0m8"
	default_value = 0
	compatible_types = ["float", "slider"]
	default_settings = {
		"rounded": true,
		"step": 1.0,
		"allow_greater": true,
		"allow_lesser": true,
	}
