extends CollectionIndexer


func _init() -> void:
	name = "characters"
	display_name = "Characters"
	description = "Everyone who can speak or be referred to in the story."
	item_script = preload("uid://bqu0a4ofohwe4")
	label_property = "name"
