extends NodeIndexer


func _init() -> void:
	name = "root"
	display_name = "Root"
	description = "Entry point of a storyline."
	category = "Flow"
	color = Color("ffffff")
	icon_path = "res://ui/assets/icons/root.svg"
	node_script = preload("uid://csx2ec4ra5m8k")
