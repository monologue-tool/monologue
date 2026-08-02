extends NodeIndexer


func _init() -> void:
	name = "text"
	display_name = "Text"
	description = "Narration text with no speaker."
	category = "Narration"
	icon_path = "res://ui/assets/icons/text.svg"
	color = Color("af85fd")
	node_script = preload("uid://8hoiik6d0qim")
