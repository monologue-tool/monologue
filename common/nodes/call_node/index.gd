extends NodeIndexer


func _init() -> void:
	name = "call"
	display_name = "Call"
	description = "Runs a function, then carries on from wherever it stopped."
	category = "Logic"
	icon_path = ""
	node_script = preload("call_node.gd")
