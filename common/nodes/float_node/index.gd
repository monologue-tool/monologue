extends NodeIndexer


func _init() -> void:
	name = "float"
	display_name = "Float"
	description = "A number with decimals, fed into whatever reads it."
	category = "Value"
	enterable = false
	icon_path = "res://ui/assets/icons/object.svg"
	node_script = preload("float_node.gd")
