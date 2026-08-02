extends CollectionIndexer


func _init() -> void:
	name = "locations"
	display_name = "Locations"
	color = MonologuePalette.ASSET
	item_script = preload("uid://bcl51sy34f52y")
	label_property = "name"
