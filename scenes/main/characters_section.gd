extends VBoxContainer

var section_icon := preload("res://ui/assets/icons/character.svg")


func clear() -> void:
	for child in get_children():
		child.queue_free()


func load_items(property: Property) -> void:
	clear()
	property.setters["flat"] = true
	property.show(self)
