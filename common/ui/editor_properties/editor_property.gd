## Manager for creating editor property controls.
##
## Creates editor controls for properties based on their type,
## combining a label with the appropriate input field.
class_name EditorPropertyManager extends Node

## Scene for editor property labels.
@onready var editor_property_label: PackedScene = preload("uid://x0daq5tsejey")


## Creates an editor property control for a given property.
##
## Instantiates the appropriate field editor based on the property type
## and combines it with a label in an HBoxContainer.
## [br][br]
## [param property] The Property to create an editor for.
## [br][br]
## Returns an HBoxContainer with label and field editor, or null on error.
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
