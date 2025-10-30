class_name InspectorPanel extends PanelContainer

@onready var property_container: VBoxContainer = %Fields
@onready var inspector_category_container: PackedScene = preload("uid://bvf68w7xrfrom")
@onready var expose_button: PackedScene = preload("uid://2ehh7rdn6yg6")

var current_object: InspectableObject


func inspect(object: InspectableObject) -> void:
	current_object = object
	rebuild()
	object.add_observer(on_property_changed)


func rebuild() -> void:
	for prop: Control in property_container.get_children():
		prop.queue_free()

	if !current_object:
		var label: Label = Label.new()
		label.text = "No node selected"
		property_container.add_child(label)

	var properties: Array[Property] = current_object.get_properties()
	var categories: Dictionary = _group_by_category(properties)
	for category_name: String in categories.keys():
		var props = categories[category_name]
		_create_category_section(category_name, props)


func _group_by_category(properties: Array) -> Dictionary:
	var groups: Dictionary = {}
	for prop in properties:
		var category = "General"
		if prop.settings.has("category"):
			category = prop.settings.category

		if not groups.has(category):
			groups[category] = []
		groups[category].append(prop)
	return groups


func _create_category_section(category_name: String, properties: Array) -> void:
	var container: Control = inspector_category_container.instantiate()
	container.title = category_name
	property_container.add_child(container)

	for property: Property in properties:
		var property_editor: Control = _create_property_editor(property)
		container.add_control(property_editor)


func _create_property_editor(property: Property) -> Control:
	if _is_list_property(property):
		pass  # TODO
		# return _create_list_property_editor(property)

	var p_container: PanelContainer = PanelContainer.new()
	var p_hbox: HBoxContainer = HBoxContainer.new()
	var p_vbox: VBoxContainer = VBoxContainer.new()
	var p_expose_button: TextureButton = expose_button.instantiate()
	var p_label: Label = Label.new()
	var p_field_scene: PackedScene = FieldBucket.get_scene(property.type)

	p_label.text = property.get_display_name()
	p_hbox.add_child(p_expose_button)
	p_hbox.add_child(p_label)
	p_vbox.add_child(p_hbox)

	var p_field: Control
	if p_field_scene:
		p_field = p_field_scene.instantiate()
	else:
		p_field = Label.new()
		p_field.theme_type_variation = "WarnLabel"
		p_field.text = "Unknown property type"

	p_vbox.add_child(p_field)
	p_container.add_child(p_vbox)

	p_expose_button.disabled = property.settings.get("private", false) or false
	p_expose_button.button_pressed = property.settings.get("exposed", false) or false
	p_expose_button.toggled.connect(
		_on_property_expose_state_changed.bind(current_object, property.name)
	)

	# TODO: Input field
	return p_container


#func _create_list_property_editor(property: Property) -> Control:
#pass
#
#
#func _create_list_item_editor(list_property, item, index: int) -> Control:
#pass
#
#
#func _create_nested_property_editor(property: Property, parent: Control) -> Control:
#pass


func _is_list_property(property: Property) -> bool:
	return property.type == "list"


func _on_property_expose_state_changed(
	toggled_on: bool, node: InspectableNode, property_name: String
) -> void:
	node.set_property_settings_value(property_name, "exposed", toggled_on)


func on_property_changed(node: InspectableNode, property_name: String) -> void:
	rebuild()
