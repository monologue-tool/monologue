extends NodeIndexer


func _init() -> void:
	name = "audio"
	display_name = "Audio"
	description = "Plays a sound or a piece of music."
	category = "Stage"
	icon_path = "res://ui/assets/icons/media_play.svg"
	node_script = preload("audio_node.gd")
