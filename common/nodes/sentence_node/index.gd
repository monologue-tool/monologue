extends NodeIndexer


func _init() -> void:
	name = "sentence"
	display_name = "Sentence"
	description = "A line of dialogue."
	category = "Narration"
	icon_path = "res://ui/assets/icons/comment.svg"
	color = MonologuePalette.TEXT
	node_script = preload("uid://bm2we18ivulms")
