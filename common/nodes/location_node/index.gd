extends NodeIndexer


func _init() -> void:
	name = "location"
	display_name = "Location"
	description = "Moves the story to a place."
	category = "World"
	icon_path = "res://ui/assets/icons/globe.svg"
	node_script = preload("location_node.gd")
