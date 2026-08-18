extends CollectionIndexer


func _init() -> void:
	name = "exits"
	display_name = "Exits"
	color = MonologuePalette.FLOW
	description = "Ways out of a called function. Computed, never written by hand."
	item_script = preload("exit_item.gd")
	is_project_scoped = false
	label_property = "name"
	# Matches ExitCollectionItem's main property, so an exit can be wired onward.
	port_type = "context"
