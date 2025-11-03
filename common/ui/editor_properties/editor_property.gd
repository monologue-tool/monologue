class_name EditorPropertyManager extends Node


func create_editor_property(property: Property) -> HBoxContainer:
	var ep_field: Field = FieldBucket.create_field(property.type)
	if not ep_field:
		push_error("Can't find property scene for property with type '%s'." % property.type)
		return null
	property.call_deferred("bind_field", ep_field)

	var ep_label: Label = Label.new()
	ep_label.text = property.get_display_name()

	var ep_container: HBoxContainer = HBoxContainer.new()
	ep_container.add_child(ep_label)
	ep_container.add_child(ep_field)

	return ep_container
