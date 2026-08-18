extends FieldIndexer


func _init() -> void:
	name = "ease"
	display_name = "Ease"
	description = "Easing curve. Cubic bezier for now, stored as its four coordinates."
	color = MonologuePalette.CURVE
	scene_uid = "uid://dlmxs2fcef1a1"
	default_value = [0.25, 0.10, 0.25, 1.0]
