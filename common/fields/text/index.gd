extends FieldIndexer


func _init() -> void:
	name = "text"
	display_name = "Text"
	description = "Text the player reads, stored per language."
	color = MonologuePalette.TEXT
	scene_uid = "uid://be0xxn5gocqjo"
	default_value = ""
	compatible_types = ["textarea"]
	default_settings = {
		PropertySettings.KEY_TRANSLATABLE: true,
	}
