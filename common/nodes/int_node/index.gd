extends NodeIndexer


func _init() -> void:
	name = "int"
	display_name = "Integer"
	description = "A whole number, fed into whatever reads it."
	category = "Value"
	enterable = false
	icon_path = "res://ui/assets/icons/object.svg"
	node_script = preload("int_node.gd")
