## Represents a graph node property list and its UI controls in Monologue.
class_name PropertyList extends Property

## Scene used to instantiate the item field's UI control.
var item_scene: PackedScene


func _init(
	ui_item_scene: PackedScene,
	ui_setters: Dictionary = {},
	default: Variant = "",
	ui_custom_label: Variant = null
) -> void:
	item_scene = ui_item_scene
	scene = MonologueGraphNode.LIST
	setters = ui_setters
	value = default
	default_value = default
	custom_label = ui_custom_label
	visible = true


func add_item() -> Control:
	return Control.new()


func get_items() -> Array:
	return []
