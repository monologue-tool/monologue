class_name InspectorPanel extends PanelContainer

@onready var header_container: VBoxContainer = %Header
@onready var property_container: VBoxContainer = %Fields
@onready var inspector_category_container: PackedScene = preload("uid://bvf68w7xrfrom")
@onready var expose_button: PackedScene = preload("uid://2ehh7rdn6yg6")

var current_object: InspectableObject
var _special_fields: Array[Control] = []
var _storyline_button: Button


func _ready() -> void:
	GlobalSignal.add_listener("inspector_property_changed", _on_external_property_changed)
	_create_storyline_button()


func _exit_tree() -> void:
	GlobalSignal.remove_listener("inspector_property_changed", _on_external_property_changed)


func _create_storyline_button() -> void:
	_storyline_button = Button.new()
	_storyline_button.text = "⚙ Storyline Settings"
	_storyline_button.tooltip_text = "Edit storyline characters and variables"
	_storyline_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_storyline_button.pressed.connect(_on_storyline_settings_pressed)
	header_container.add_child(_storyline_button)
	header_container.move_child(_storyline_button, 0)


func _on_storyline_settings_pressed() -> void:
	var storyline = StorylineManager.get_active_storyline()
	if storyline:
		inspect(storyline)


func inspect(object: InspectableObject) -> void:
	if current_object and current_object != object:
		if current_object is InspectableNode and is_instance_valid(current_object.graph_view):
			current_object.graph_view.selected = false
		current_object.remove_observer(on_property_changed)
	elif current_object:
		current_object.remove_observer(on_property_changed)

	current_object = object
	rebuild()

	if current_object:
		current_object.add_observer(on_property_changed)


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

	post_build()


func _group_by_category(properties: Array) -> Dictionary:
	var groups: Dictionary = {}
	for prop in properties:
		# Skip properties not visible in inspector
		if not prop.settings.get("visible_in_inspector", true):
			continue

		var category: String = "General"
		if prop.settings.has("category"):
			category = prop.settings.category

		if not groups.has(category):
			groups[category] = []
		groups[category].append(prop)
	return groups


func _create_category_section(category_name: String, properties: Array) -> void:
	var container: FoldableContainer = inspector_category_container.instantiate()
	container.title = category_name
	property_container.add_child(container)

	if not property_container.is_node_ready():
		await property_container.ready

	for property: Property in properties:
		var property_editor: Control = _create_property_editor(property)
		if property_editor:
			container.add_control(property_editor)


func _handle_special_category_section(category_name: String, properties: Array) -> void:
	var container: Control

	match category_name:
		"Header":
			container = header_container

	for property: Property in properties:
		var index: int = properties.find(property)
		var property_editor: Control = _create_property_editor(property)
		if not property_editor:
			continue

		_special_fields.append(property_editor)

		if container.get_child_count() >= index:
			var sub_container: Control = container.get_child(index - 1)
			sub_container.add_child(property_editor)
			sub_container.move_child(property_editor, 0)
			continue
		container.add_child(property_editor)


func _create_property_editor(property: Property) -> Control:
	if (
		not property.settings.get("editable", true)
		and not property.settings.get("exposed", false)
		and not property.settings.get("export", false)
	):
		return

	if _is_list_property(property):
		return _create_list_property_editor(property)

	var p_container: PanelContainer = PanelContainer.new()
	var p_hbox: HBoxContainer = HBoxContainer.new()
	var p_vbox: VBoxContainer = VBoxContainer.new()
	var p_expose_button: TextureButton = expose_button.instantiate()
	var p_label: Label = Label.new()
	
	p_container.theme_type_variation = "FieldContainer"

	p_label.text = property.get_display_name()
	p_hbox.add_child(p_expose_button)
	p_hbox.add_child(p_label)

	p_vbox.add_child(p_hbox)

	if property.settings.get("flat"):
		p_hbox.hide()

	var p_field: Control
	if property.is_intput_connected():  # Add inspect connected node button if property is connected
		var inspect_button: Button = Button.new()
		inspect_button.text = "Go to connected node"
		inspect_button.tooltip_text = "Inspect connected node"
		inspect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inspect_button.pressed.connect(_on_inspect_connected_node.bind(property))
		p_field = inspect_button
	else:
		var new_field: Field = FieldBucket.create_field(property.type)
		if new_field:
			property.call_deferred("bind_field", new_field, current_object)
			p_field = new_field
		else:
			p_field = Label.new()
			p_field.theme_type_variation = "WarnLabel"
			p_field.text = "Unknown property type"

	p_vbox.add_child(p_field)
	p_container.add_child(p_vbox)
	p_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	p_expose_button.disabled = not property.settings.get("exposable", false)
	p_expose_button.button_pressed = property.settings.get("exposed", false)
	p_expose_button.toggled.connect(
		_on_property_expose_state_changed.bind(current_object, property.name)
	)

	# TODO: Make field read-only if property is not editable or is connected
	#if p_field and p_field.has_method("set_editable"):
	#var is_editable = (
	#property.settings.get("editable", true) and not property.is_intput_connected()
	#)
	#p_field.set_editable(is_editable)

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


func _create_list_property_editor(property: Property) -> Control:
	var p_container: PanelContainer = PanelContainer.new()
	var p_vbox: VBoxContainer = VBoxContainer.new()
	var p_label: Label = Label.new()
	
	p_container.theme_type_variation = "FieldContainer"
	
	p_label.text = property.get_display_name()
	p_vbox.add_child(p_label)
	
	var p_field: Field = FieldBucket.create_field(property.type)
	if p_field:
		property.call_deferred("bind_field", p_field, current_object)
		p_vbox.add_child(p_field)
	else:
		var warn_label = Label.new()
		warn_label.theme_type_variation = "WarnLabel"
		warn_label.text = "Unknown property type: " + property.type
		p_vbox.add_child(warn_label)
	
	p_container.add_child(p_vbox)
	p_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	return p_container


func post_build() -> void:
	for child: Control in property_container.get_children():
		if child is FoldableContainer and child.is_empty():
			child.queue_free()


func _is_list_property(property: Property) -> bool:
	return property.type == "list"


func _on_property_expose_state_changed(
	toggled_on: bool, node: InspectableNode, property_name: String
) -> void:
	node.set_property_settings_value(property_name, "exposed", toggled_on)


func _on_inspect_connected_node(property: Property) -> void:
	if not current_object or not current_object is InspectableNode:
		return

	var node: InspectableNode = current_object as InspectableNode

	# Get the graph edit from the node's graph view
	if not node.graph_view or not node.graph_view.get_parent():
		return

	var graph_edit := node.graph_view.get_parent()
	if not (graph_edit is GraphEdit):
		return

	if not graph_edit.connection_manager:
		return

	# Get the connected node from the connection manager
	var connected_node = graph_edit.connection_manager.get_connected_node(node, property.name)

	if connected_node and connected_node.graph_view:
		GlobalSignal.emit(
			"request_node_inspection", [connected_node, connected_node.storyline_id]
		)


func on_property_changed(obj: InspectableObject, _property_name: String) -> void:
	if not obj:
		return

	rebuild()


func _on_external_property_changed(
	obj: InspectableObject, property_name: String, _is_undo: bool
) -> void:
	if not obj:
		return

	var property: Property = obj.get_property(property_name)
	if not property:
		return

	if not property.settings.get("visible_in_inspector", true):
		return

	if obj == current_object:
		rebuild()
		return

	inspect(obj)
