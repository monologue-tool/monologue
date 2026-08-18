extends NodeIndexer


func _init() -> void:
	name = "waypoint"
	display_name = "Waypoint"
	description = "A named place a jump can aim at."
	category = "Flow"
	icon_path = "res://ui/assets/icons/magnet.svg"
	node_script = preload("waypoint_node.gd")
