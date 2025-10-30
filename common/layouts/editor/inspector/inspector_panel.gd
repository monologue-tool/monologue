## Inspector panel for viewing and editing object properties.
##
## Displays all properties of an InspectableObject grouped by category.
## Supports special categories like "Header" for placement in specific areas.
## Properties can be exposed/hidden and edited through dynamically created fields.
class_name InspectorPanel extends PanelContainer

## Reference to the header container for special header properties.
@onready var header_container: VBoxContainer = %Header

## Reference to the main property fields container.
@onready var property_container: VBoxContainer = %Fields

## Scene for inspector category containers.
@onready var inspector_category_container: PackedScene = preload("uid://bvf68w7xrfrom")

## Scene for property expose toggle buttons.
@onready var expose_button: PackedScene = preload("uid://2ehh7rdn6yg6")

## The currently inspected object.
var current_object: InspectableObject

## Array of special field controls (e.g., header fields).
var _special_fields: Array[Control] = []


## Inspects an object and displays its properties.
##
## Rebuilds the inspector with the object's properties and registers
## as an observer for property changes.
## [br][br]
## [param object] The InspectableObject to inspect.
func inspect(object: InspectableObject) -> void:
	current_object = object
	rebuild()
	object.add_observer(on_property_changed)


## Rebuilds the inspector display with current object properties.
##
## Clears existing property editors and recreates them based on the
## current object's properties, grouped by category.
func rebuild() -> void:
	for prop: Control in property_container.get_children():
		prop.queue_free()

	for field: Control in _special_fields:
		field.queue_free()
	_special_fields.clear()

	if !current_object:
		var label: Label = Label.new()
		label.text = "No node selected"
		property_container.add_child(label)

	var properties: Array[Property] = current_object.get_properties()
	var categories: Dictionary = _group_by_category(properties)
	for category_name: String in categories.keys():
		var props = categories[category_name]

		if category_name.begins_with("Special"):
			var special_category: String = category_name.trim_prefix("Special:")
			_handle_special_category_section(special_category, props)
			continue
		_create_category_section(category_name, props)


## Groups properties by their category setting.
##
## [param properties] Array of Property objects to group.
## [br][br]
## Returns a dictionary mapping category names to arrays of properties.
func _group_by_category(properties: Array) -> Dictionary:
	var groups: Dictionary = {}
	for prop in properties:
		var category: String = "General"
		if prop.settings.has("category"):
			category = prop.settings.category

		if not groups.has(category):
			groups[category] = []
		groups[category].append(prop)
	return groups


## Creates a category section with property editors.
##
## [param category_name] The name of the category section.
## [br][br]
## [param properties] Array of properties to include in this category.
func _create_category_section(category_name: String, properties: Array) -> void:
	var container: FoldableContainer = inspector_category_container.instantiate()
	container.title = category_name
	property_container.add_child(container)

	for property: Property in properties:
		var property_editor: Control = _create_property_editor(property)
		container.add_control(property_editor)


## Handles special category sections like "Header".
##
## Places properties in specific containers based on the special category name.
## [br][br]
## [param category_name] The special category name (without "Special:" prefix).
## [br][br]
## [param properties] Array of properties for this special category.
func _handle_special_category_section(category_name: String, properties: Array) -> void:
	var container: Control

	match category_name:
		"Header":
			container = header_container

	for property: Property in properties:
		var index: int = properties.find(property)
		var property_editor: Control = _create_property_editor(property)
		_special_fields.append(property_editor)

		if container.get_child_count() >= index:
			var sub_container: Control = container.get_child(index - 1)
			sub_container.add_child(property_editor)
			sub_container.move_child(property_editor, 0)
			continue
		container.add_child(property_editor)


## Creates an editor control for a property.
##
## Builds a property editor with label, expose button, and appropriate
## input field based on the property type.
## [br][br]
## [param property] The Property to create an editor for.
## [br][br]
## Returns a Control containing the property editor.
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

	if property.settings.get("flat"):
		p_hbox.hide()

	var p_field: Control
	if p_field_scene:
		p_field = p_field_scene.instantiate()

	else:
		p_field = Label.new()
		p_field.theme_type_variation = "WarnLabel"
		p_field.text = "Unknown property type"

	p_vbox.add_child(p_field)
	p_container.add_child(p_vbox)
	p_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

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


## Checks if a property is a list type.
##
## [param property] The property to check.
## [br][br]
## Returns true if the property type is "list".
func _is_list_property(property: Property) -> bool:
	return property.type == "list"


## Handles property expose state changes.
##
## Updates the property's exposed setting when the expose button is toggled.
## [br][br]
## [param toggled_on] Whether the expose button is now on.
## [br][br]
## [param node] The node containing the property.
## [br][br]
## [param property_name] The name of the property being toggled.
func _on_property_expose_state_changed(
	toggled_on: bool, node: InspectableNode, property_name: String
) -> void:
	node.set_property_settings_value(property_name, "exposed", toggled_on)


## Observer callback for property changes.
##
## Rebuilds the inspector when any property changes.
## [br][br]
## [param node] The node whose property changed.
## [br][br]
## [param property_name] The name of the changed property.
func on_property_changed(node: InspectableNode, property_name: String) -> void:
	print(property_name)
	rebuild()
