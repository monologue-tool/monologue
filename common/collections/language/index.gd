extends CollectionIndexer


func _init() -> void:
	name = "languages"
	display_name = "Languages"
	color = MonologuePalette.TEXT
	description = "Languages the story can be written in."
	item_script = preload("res://common/collections/language/language_item.gd")
	label_property = "name"
