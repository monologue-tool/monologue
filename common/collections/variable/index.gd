extends CollectionIndexer


func _init() -> void:
	name = "variables"
	display_name = "Variables"
	description = "Named values the story can read in conditions and write with setters."
	item_script = preload("uid://b8gmqtdncql4s")
	label_property = "name"
