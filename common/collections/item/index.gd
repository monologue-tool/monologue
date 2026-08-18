extends CollectionIndexer


func _init() -> void:
	name = "items"
	display_name = "Items"
	color = MonologuePalette.CONTAINER
	item_script = preload("uid://y8hn47i11ixd")
	label_property = "name"
