class_name EditorPropertyManager extends Node

@onready var editor_property_label: PackedScene = preload("uid://x0daq5tsejey")


func create_editor_property(property: Property) -> HBoxContainer:
	var editor_property_scene: PackedScene = FieldBucket.get_field(property.type)
	if not editor_property_scene:
		push_error("Can't find property scene for property with type '%s'." % property.type)
		return

	var ep_field: Control = editor_property_scene.instantiate()

	var ep_label: Label = editor_property_label.instantiate()
	ep_label.text = property.get_display_name()

	var ep_container: HBoxContainer = HBoxContainer.new()
	ep_container.add_child(ep_label)
	ep_container.add_child(ep_field)

	return ep_container
