extends NodeIndexer


func _init() -> void:
	name = "event"
	display_name = "Event"
	description = "Interrupts the story when a variable changes to match."
	category = "Logic"
	icon_path = "res://ui/assets/icons/sparkles.svg"
	color = MonologuePalette.EVENT
	node_script = preload("event_node.gd")
