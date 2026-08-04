extends NodeIndexer


func _init() -> void:
	name = "label"
	display_name = "Label"
	description = "A named place a jump can aim at."
	category = "Flow"
	icon_path = "res://ui/assets/icons/magnet.svg"
	node_script = preload("label_node.gd")
