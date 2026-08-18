extends CollectionIndexer


func _init() -> void:
	name = "eases"
	display_name = "Easing Curves"
	color = MonologuePalette.CURVE
	description = "Reusable easing curves referenced by animated fields."
	item_script = preload("uid://cyubx671gs3ng")
	label_property = "name"
