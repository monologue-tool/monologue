extends CollectionIndexer


func _init() -> void:
	name = "portraits"
	display_name = "Portraits"
	description = "Character artwork. Lives inside a character rather than project-wide."
	item_script = preload("uid://brhhri86u8h56")
	is_project_scoped = false
	label_property = "name"
