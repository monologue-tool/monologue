extends FieldIndexer


func _init() -> void:
	name = "translatable"
	display_name = "Translatable"
	description = "Text stored per language code, keyed by the project's languages."
	color = Color("628cff")
	scene_uid = "uid://bg1c7vlg63ty1"
	default_value = {"en": ""}
