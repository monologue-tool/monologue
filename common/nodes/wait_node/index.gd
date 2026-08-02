extends NodeIndexer


func _init() -> void:
	name = "wait"
	display_name = "Wait"
	description = "Pauses for a moment before continuing."
	category = "Flow"
	color = Color("45cee9")
	node_script = preload("wait_node.gd")
