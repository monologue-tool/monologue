extends NodeIndexer


func _init() -> void:
	name = "wait_input"
	display_name = "Wait Input"
	description = "Waits for the player to press something before continuing."
	category = "Flow"
	icon_path = "res://ui/assets/icons/media_play.svg"
	node_script = preload("wait_input_node.gd")
