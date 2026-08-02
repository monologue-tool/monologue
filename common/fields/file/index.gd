extends FieldIndexer


func _init() -> void:
	name = "file"
	display_name = "File"
	color = MonologuePalette.ASSET
	scene_uid = "res://common/fields/file/file_field.tscn"
	default_value = ""
	default_settings = {
		PropertySettings.KEY_FILE_FILTERS: [],
	}
