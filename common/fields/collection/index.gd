extends FieldIndexer


func _init() -> void:
	name = "collection"
	display_name = "Collection"
	description = "An ordered list of full collection items, unlike `list` which holds primitives."
	color = MonologuePalette.CONTAINER
	scene_uid = "res://common/fields/collection/collection_field.tscn"
	default_value = []
