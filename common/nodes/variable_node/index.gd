extends NodeIndexer


func _init() -> void:
	name = "variable"
	display_name = "Variable"
	description = "Changes the value of a project variable."
	category = "Logic"
	icon_path = "res://ui/assets/icons/object.svg"
	node_script = preload("variable_node.gd")
