extends NodeIndexer


func _init() -> void:
	name = "wait"
	display_name = "Wait"
	description = "Pauses for a moment before continuing."
	category = "Flow"
	icon_path = "res://ui/assets/icons/calendar.svg"
	color = MonologuePalette.NUMBER
	node_script = preload("wait_node.gd")
