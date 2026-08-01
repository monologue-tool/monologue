extends CollectionIndexer


func _init() -> void:
	# Renamed from "option" to "options": every other collection is plural, and the
	# singular form collided with the "option" field type and the "option" node type.
	name = "options"
	display_name = "Options"
	description = "Choices offered by a choice node. Only ever embedded in a node."
	item_script = preload("uid://dhodjihl1pyka")
	is_project_scoped = false
	label_property = "name"
