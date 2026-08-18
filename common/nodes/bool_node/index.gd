extends NodeIndexer


func _init() -> void:
	name = "bool"
	display_name = "Boolean"
	description = "A yes or no, fed into whatever reads it."
	category = "Value"
	enterable = false
	icon_path = "res://ui/assets/icons/toggle.svg"
	node_script = preload("bool_node.gd")
