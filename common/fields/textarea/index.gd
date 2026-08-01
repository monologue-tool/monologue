extends FieldIndexer


func _init() -> void:
	name = "textarea"
	display_name = "Text Area"
	description = "Multi-line text. Shares the text field's widget."
	color = Color("af85fd")
	scene_uid = "uid://be0xxn5gocqjo"  # text_field.tscn
	default_value = ""
	compatible_types = ["text"]
	default_settings = {
		PropertySettings.KEY_MULTILINE: true,
		PropertySettings.KEY_ROWS: 3,
	}
