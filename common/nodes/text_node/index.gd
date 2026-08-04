extends NodeIndexer


func _init() -> void:
	name = "text"
	display_name = "Text"
	description = "A piece of text, fed into whatever reads it."
	category = "Value"
	icon_path = "res://ui/assets/icons/text.svg"
	node_script = preload("uid://8hoiik6d0qim")
