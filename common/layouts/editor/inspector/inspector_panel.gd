class_name InspectorPanel extends PanelContainer

@onready var property_container: VBoxContainer = %Fields
@onready var inspector_category_container: PackedScene = preload("uid://bvf68w7xrfrom")

var current_object: InspectableObject


func inspect(object: InspectableObject) -> void:
	current_object = object
	rebuild()
	object.add_observer(self)


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
		if prop.options.has("category"):
			category = prop.options.category

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
	var p_vbox: VBoxContainer = VBoxContainer.new()
	var p_label: Label = Label.new()
	p_label.text = property.get_display_name()
	p_vbox.add_child(p_label)
	p_container.add_child(p_vbox)

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


func on_property_changed(node: InspectableNode, property_name: String) -> void:
	if _is_list_property(
		node.get_properties().filter(func(p: Property): return p.name == property_name)[0]
	):
		rebuild()
