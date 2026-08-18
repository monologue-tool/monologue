extends CollectionIndexer


func _init() -> void:
	# Renamed from "option" to "options": every other collection is plural, and the
	# singular form collided with the "option" field type and the "option" node type.
	name = "options"
	display_name = "Options"
	color = MonologuePalette.CHOICE
	description = "Choices offered by a choice node. Only ever embedded in a node."
	item_script = preload("uid://dhodjihl1pyka")
	is_project_scoped = false
	# An option has no name. What identifies it to a person is the line it offers.
	label_property = "text"
	# Matches OptionCollectionItem's main property, so an option node can be wired
	# into a choice node's option list. Guarded by test_collection_port_types.
	port_type = "option"
