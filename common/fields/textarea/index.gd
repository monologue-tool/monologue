extends FieldIndexer


func _init() -> void:
	name = "textarea"
	display_name = "Text Area"
	description = "Multi-line notes for whoever writes the story. Not translated."
	color = MonologuePalette.TEXT
	scene_uid = "uid://be0xxn5gocqjo"  # text_field.tscn
	default_value = ""
	compatible_types = ["text"]
	default_settings = {
		PropertySettings.KEY_TRANSLATABLE: false,
		PropertySettings.KEY_MULTILINE: true,
		PropertySettings.KEY_ROWS: 3,
	}
