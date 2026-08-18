extends CollectionIndexer


func _init() -> void:
	name = "variations"
	display_name = "Variations"
	color = MonologuePalette.ASSET
	description = "How a place looks. Lives inside a location rather than project-wide."
	item_script = preload("variation_item.gd")
	is_project_scoped = false
	label_property = "name"
