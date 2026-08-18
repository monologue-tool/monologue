extends NodeIndexer


func _init() -> void:
	name = "inventory"
	display_name = "Inventory"
	description = "Gives the player an item, takes one away, or sets how many they hold."
	category = "World"
	icon_path = "res://ui/assets/icons/object.svg"
	node_script = preload("inventory_node.gd")
