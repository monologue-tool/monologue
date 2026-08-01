class_name InspectorPanel extends PanelContainer

var _fields: Array[Field] = []
var _pending_expand_category: String = ""

@onready var back_button: Button = %BackButton
@onready var header_container: HBoxContainer = %FieldHeader
@onready var field_container: VBoxContainer = %Fields
@onready var run_button: Button = %RunButton
@onready var inspector_category_container: PackedScene = preload("uid://bvf68w7xrfrom")
@onready var expose_button: PackedScene = preload("uid://2ehh7rdn6yg6")

var current_object: InspectableObject
var history: Array[InspectableObject] = []


func _ready() -> void:
	EventBus.request_object_inspection.connect(inspect)
	EventBus.inspector_property_changed.connect(_on_external_property_changed)
	EventBus.show_inspector.connect(_on_event_show_inspector)

	ProjectManager.project_loaded.connect(_on_project_loaded)
	back_button.pressed.connect(_on_back_button_pressed)
	visible = ConfigManager.get_config("show_inspector")


func _on_project_loaded() -> void:
	var command_manager: CommandManager = ProjectManager.current_project.command_manager
	command_manager.undone.connect(_on_history_undo_redo)
	command_manager.redone.connect(_on_history_undo_redo)


func _on_event_show_inspector(_visible: bool) -> void:
	inspect(current_object)


## Called after every undo or redo. Re-resolves the inspection stack from the
## root so stale CollectionItem references are replaced with fresh objects, then rebuilds.
func _on_history_undo_redo() -> void:
	rebuild()


func inspect(object: InspectableObject, from_history: bool = false) -> void:
	var old_root: InspectableObject = current_object
	if object and old_root and old_root != object:
		if not from_history:
			history.append(old_root)

		var old_node: InspectableNode = old_root as InspectableNode
		if old_node and is_instance_valid(old_node.graph_view):
			old_node.graph_view.selected = false

	back_button.disabled = history.is_empty()
	current_object = object
	if not object or object is not InspectableObject:
		hide()
		Log.warn("Inspector hidden due to invalid object")
		return

	if not ConfigManager.get_config("show_inspector"):
		hide()
		return

	show()
	Log.info("Inspect object", object.get_property_value("id") if object else "<null>")

	rebuild()


func rebuild() -> void:
	var inspected: InspectableObject = current_object
	run_button.visible = current_object is InspectableNode
	_fields.clear()
	await get_tree().process_frame  # TODO: Bad practice

	for field: Control in field_container.get_children():
		field.queue_free()

	for child: Control in header_container.get_children():
		child.queue_free()

	var separator: HSeparator = HSeparator.new()
	separator.theme_type_variation = "UltraWideHSeparator"
	field_container.add_child(separator)

	if not inspected:
		var label: Label = Label.new()
		label.text = "Nothing to show here."
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		field_container.add_child(label)
	else:
		var properties: Array[Property] = inspected.get_properties()
		var categories: Dictionary = _group_by_category(properties)

		for category_name: String in categories.keys():
			var props: Array = categories[category_name]

			if category_name.begins_with("Special"):
				var special_category: String = category_name.trim_prefix("Special:")
				_handle_special_category_section(special_category, props)
				continue

			_create_category_section(category_name, props)

	_pending_expand_category = ""


func _find_labels(node: Node, labels: Array) -> void:
	if node is Label:
		labels.append(node)
	for child: Node in node.get_children():
		_find_labels(child, labels)


func _restore_focus_to_property(property_name: String) -> void:
	# Walk into each category container and find the p_container tagged with property_name
	for category: Node in field_container.get_children():
		for p_container: Node in category.get_children():
			if not p_container.has_meta("property_name"):
				continue
			if p_container.get_meta("property_name") != property_name:
				continue
			var fields: Array = []
			_find_focusable_fields(p_container, fields)
			if fields.size() > 0:
				var first_field: Control = fields[0]
				first_field.grab_focus()
			return


func _find_focusable_fields(node: Node, fields: Array) -> void:
	if (
		node is LineEdit
		or node is TextEdit
		or node is OptionButton
		or node is CheckBox
		or node is SpinBox
		or node is ColorPickerButton
		or (node is Button and not node is TextureButton)
	):
		fields.append(node)
	for child: Node in node.get_children():
		_find_focusable_fields(child, fields)


func _group_by_category(properties: Array[Property]) -> Dictionary:
	var groups: Dictionary[String, Array] = {}
	for prop: Property in properties:
		# Skip properties not visible in inspector
		if not prop.get_settings_value("visible_in_inspector", true):
			continue

		var category: String = "General"
		if prop.has_settings("category"):
			category = prop.get_settings_value("category")

		if not groups.has(category):
			groups[category] = []

		groups[category].append(prop)
	return groups


func _create_category_section(
	category_name: String, properties: Array
) -> InspectorCategoryContainer:
	# If the section only contains list properties.
	var is_ghost_section: bool = (
		properties.filter(func(p: Property) -> bool: return _is_list(p)).size() == properties.size()
		and properties.size() != 0
	)

	var separator: HSeparator = HSeparator.new()
	separator.theme_type_variation = "UltraWideHSeparator"
	var container: InspectorCategoryContainer = inspector_category_container.instantiate()
	container.title = category_name

	if not is_ghost_section:
		field_container.add_child(container)
		field_container.add_child(separator)

	for property: Property in properties:
		var property_editor: Control = _create_property_editor(property)
		if property_editor:
			container.add_control(property_editor)

	return container


func _handle_special_category_section(category_name: String, properties: Array) -> void:
	var container: Control

	match category_name:
		"Header":
			container = header_container

	for property: Property in properties:
		var property_editor: Control = _create_property_editor(property, true, true)
		if not property_editor:
			continue

		container.add_child(property_editor)
		container.move_child(property_editor, 0)


func _create_property_editor(
	property: Property, flat: bool = false, hide_left: bool = false
) -> Control:
	var is_list: bool = _is_list(property)
	var is_editable: bool = property.get_settings_value(PropertySettings.KEY_EDITABLE, true)
	var is_read_only: bool = property.get_settings_value(PropertySettings.KEY_READ_ONLY, false)
	var has_port: bool = (
		property.get_settings_value(PropertySettings.KEY_EXPOSED, false)
		or property.get_settings_value(PropertySettings.KEY_EXPORT, false)
	)
	if not is_editable and not is_read_only and not has_port:
		return null

	var p_field: Control
	if property.is_input_connected() and not is_list:
		var inspect_button: Button = Button.new()
		inspect_button.text = "Go to connected node"
		inspect_button.tooltip_text = "Inspect connected node"
		inspect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inspect_button.pressed.connect(_on_inspect_connected_node.bind(property))
		p_field = inspect_button
	else:
		p_field = FieldWidgetFactory.create_or_placeholder(property.type)

	var is_vertical: bool = false
	if p_field is Field:
		is_vertical = (p_field as Field).prefers_vertical_layout(property.get_settings())

	var p_container: PanelContainer = PanelContainer.new()
	p_container.set_meta("property_name", property.name)
	p_container.theme_type_variation = "FieldContainer"
	if property.get_settings_value("expand", true):
		p_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if flat:
		p_container.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var p_hbox: Control
	if not hide_left:
		if is_vertical:
			var p_vbox: VBoxContainer = VBoxContainer.new()
			p_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			p_container.add_child(p_vbox)

			var p_label_row: HBoxContainer = HBoxContainer.new()
			p_vbox.add_child(p_label_row)

			var p_expose_button: TextureButton = expose_button.instantiate()
			p_expose_button.disabled = (
				not current_object is InspectableNode
				or not property.get_settings_value(PropertySettings.KEY_EXPOSABLE, false)
			)
			p_expose_button.button_pressed = property.get_settings_value(
				PropertySettings.KEY_EXPOSED, false
			)
			p_expose_button.toggled.connect(
				_on_property_expose_state_changed.bind(current_object, property.name)
			)
			p_label_row.add_child(p_expose_button)

			var p_label: Label = Label.new()
			p_label.clip_text = true
			p_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			p_label.text = property.name
			p_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS_FORCE
			p_label_row.add_child(p_label)

			p_hbox = p_vbox
		else:
			var p_ahbox: AdvancedHBoxContainer = AdvancedHBoxContainer.new()
			p_ahbox.ratio = [2, 3]
			p_ahbox.force_ratio = true
			p_ahbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			p_container.add_child(p_ahbox)

			var p_left_main_container: HBoxContainer = HBoxContainer.new()
			p_left_main_container.clip_contents = true
			p_ahbox.add_child(p_left_main_container)

			var p_left_container: HBoxContainer = HBoxContainer.new()
			p_left_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			p_left_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			p_left_main_container.add_child(p_left_container)

			var p_expose_button: TextureButton = expose_button.instantiate()
			p_expose_button.disabled = (
				not current_object is InspectableNode
				or not property.get_settings_value(PropertySettings.KEY_EXPOSABLE, false)
			)
			p_expose_button.button_pressed = property.get_settings_value(
				PropertySettings.KEY_EXPOSED, false
			)
			p_expose_button.toggled.connect(
				_on_property_expose_state_changed.bind(current_object, property.name)
			)
			p_left_container.add_child(p_expose_button)

			var p_label: Label = Label.new()
			p_label.clip_text = true
			p_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			p_label.text = property.name
			p_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS_FORCE
			p_left_container.add_child(p_label)

			if is_list:
				p_left_main_container.hide()

			p_hbox = p_ahbox
	else:
		p_hbox = VBoxContainer.new()
		p_container.add_child(p_hbox)

	if p_field is not Field:
		p_hbox.add_child(p_field)
		return p_container
	_fields.append(p_field)

	if is_list:
		var list_section: InspectorCategoryContainer = _create_category_section(
			property.get_display_name(), []
		)
		list_section.add_control.call_deferred(p_container)

	property.bind_field.call_deferred(p_field, current_object)
	p_hbox.add_child(p_field)
	return p_container if not is_list else null


func _cache_category_states(category_states: Dictionary) -> void:
	for child: Control in field_container.get_children():
		var fc: FoldableContainer = child as FoldableContainer
		if fc:
			category_states[fc.title] = fc.folded


func _apply_category_state(
	container: FoldableContainer, category_name: String, category_states: Dictionary
) -> void:
	var stored_state: Variant = category_states.get(category_name)
	if stored_state is bool:
		container.folded = stored_state
	else:
		container.folded = false

	if _pending_expand_category == category_name:
		container.folded = false

	category_states[category_name] = container.folded


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

	var graph_edit: MonologueGraphEdit = node.graph_view.get_parent() as MonologueGraphEdit
	if not graph_edit:
		return

	if not graph_edit.connection_manager:
		return

	# Get the connected node from the connection manager
	var connected_node: InspectableNode = graph_edit.connection_manager.get_connected_node(
		node, property.name
	)

	if connected_node and connected_node.graph_view:
		EventBus.request_node_selection.emit(connected_node, connected_node.storyline_id)


func _is_list(property: Property) -> bool:
	return property.type in ["list", "collection"]


func _on_external_property_changed(
	obj: InspectableObject, property_name: String, _is_undo: bool
) -> void:
	if not obj:
		return

	var property: Property = obj.get_property(property_name)
	if not property:
		return

	if not property.get_settings_value("visible_in_inspector", true):
		return

	if current_object in obj.get_property_children(property_name):
		return

	_pending_expand_category = property.get_category()

	if obj == current_object:
		rebuild()
		return

	inspect(obj)


func _on_back_button_pressed() -> void:
	if history.is_empty():
		return

	inspect(history.pop_back(), true)
