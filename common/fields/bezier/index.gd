extends FieldIndexer


func _init() -> void:
	name = "bezier"
	display_name = "Bezier"
	description = "Easing curve, stored as the four control-point coordinates."
	color = Color("9df27e")
	scene_uid = "uid://dlmxs2fcef1a1"
	default_value = [0.25, 0.10, 0.25, 1.0]
