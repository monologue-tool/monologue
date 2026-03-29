class_name InspectorPanel extends PanelContainer

var _fields: Array[Field] = []
var _special_fields: Array[Control] = []
var _pending_expand_category: String = ""

@onready var header_container: VBoxContainer = %Header
#@onready var breadcrumb_container: HBoxContainer = %Breadcrumb
@onready var field_container: VBoxContainer = %Fields
@onready var run_button: Button = %RunButton
@onready var inspector_category_container: PackedScene = preload("uid://bvf68w7xrfrom")
@onready var expose_button: PackedScene = preload("uid://2ehh7rdn6yg6")

var current_object: InspectableObject


func _ready() -> void:
	EventBus.request_object_inspection.connect(inspect)
	EventBus.inspector_property_changed.connect(_on_external_property_changed)
	StorylineManager.storyline_switched.connect(_on_storyline_switched)
	# Handle the storyline that is already active at startup.
	call_deferred("_on_storyline_switched")


func _on_storyline_switched() -> void:
	var storyline: StorylineDocument = StorylineManager.get_active_storyline()
	if not storyline:
		return
	var h: CommandManager = storyline.history
	if not h.undone.is_connected(_on_history_undo_redo):
		h.undone.connect(_on_history_undo_redo)
	if not h.redone.is_connected(_on_history_undo_redo):
		h.redone.connect(_on_history_undo_redo)


## Called after every undo or redo. Re-resolves the inspection stack from the
## root so stale ListItem references are replaced with fresh objects, then rebuilds.
func _on_history_undo_redo() -> void:
	rebuild()


func inspect(object: InspectableObject) -> void:
	Log.info("Inspect object", object.get_property_value("id") if object else "<null>")
	var old_root: InspectableObject = current_object
	if old_root and old_root != object:
		var old_node: InspectableNode = old_root as InspectableNode
		if old_node and is_instance_valid(old_node.graph_view):
			old_node.graph_view.selected = false
	
	current_object = object

	rebuild()


func rebuild() -> void:
	var inspected: InspectableObject = current_object
	run_button.visible = current_object is InspectableNode
	_fields.clear()
	await get_tree().process_frame # TODO: Bad practice

	for field: Control in field_container.get_children():
		field.queue_free()

	for field: Control in _special_fields:
		field.queue_free()
	_special_fields.clear()

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
		
		# Restore focus after rebuild completes
		#var focus_owner: Control = get_viewport().gui_get_focus_owner()
		#if focus_owner and focus_owner.is_inside_tree():
			#var node: Node = focus_owner
			#while node:
				#if node.has_meta("property_name"):
					#var prop_name: String = str(node.get_meta("property_name"))
					## Property had focus before rebuild
					#await get_tree().process_frame
					#_restore_focus_to_property(prop_name)
					#break
				#node = node.get_parent()

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
	if node is LineEdit or node is TextEdit or node is OptionButton \
			or node is CheckBox or node is SpinBox or node is ColorPickerButton \
			or (node is Button and not node is TextureButton):
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


func _create_category_section(category_name: String, properties: Array) -> void:
	var container: InspectorCategoryContainer = inspector_category_container.instantiate()
	container.title = category_name
	field_container.add_child(container)

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
	var is_editable: bool = property.get_settings_value(PropertySettings.KEY_EDITABLE, true)
	var is_read_only: bool = property.get_settings_value(PropertySettings.KEY_READ_ONLY, false)
	var has_port: bool = (
		property.get_settings_value(PropertySettings.KEY_EXPOSED, false)
		or property.get_settings_value(PropertySettings.KEY_EXPORT, false)
	)
	# Hidden when: not editable, not read_only, and no ports
	if not is_editable and not is_read_only and not has_port:
		return null

	var p_container: PanelContainer = PanelContainer.new()
	p_container.set_meta("property_name", property.name)
	var p_hbox: HBoxContainer = HBoxContainer.new()
	var p_vbox: VBoxContainer = VBoxContainer.new()
	var p_expose_button: TextureButton = expose_button.instantiate()
	var p_label: Label = Label.new()

	p_container.theme_type_variation = "FieldContainer"

	p_label.text = property.get_display_name()
	p_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_hbox.add_child(p_expose_button)
	p_hbox.add_child(p_label)

	p_vbox.add_child(p_hbox)

	if property.get_settings_value("flat"):
		p_container.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		p_hbox.hide()

	var p_field: Control
	if property.is_input_connected() and property.type != "list":
		var inspect_button: Button = Button.new()
		inspect_button.text = "Go to connected node"
		inspect_button.tooltip_text = "Inspect connected node"
		inspect_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inspect_button.pressed.connect(_on_inspect_connected_node.bind(property))
		p_field = inspect_button
	else:
		p_field = FieldBucket.safe_create_field(property.type)
		if p_field is Field:
			var _owner: InspectableObject = current_object
			var _field: Field = p_field as Field
			_fields.append(_field)
			(func() -> void: property.bind_field(_field, _owner)).call_deferred()

	if property.type == "list":
		var add_btn: Button = Button.new()
		add_btn.icon = preload("res://ui/assets/icons/plus_min.svg")
		add_btn.flat = true
		add_btn.tooltip_text = "Add item"
		add_btn.pressed.connect(func() -> void:
			var list_field: ListField = p_field as ListField
			if list_field:
				list_field.add_item()
		)
		p_hbox.add_child(add_btn)

	p_vbox.add_child(p_field)
	p_container.add_child(p_vbox)
	if property.get_settings_value("expand", true):
		p_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	p_expose_button.disabled = not current_object is InspectableNode or not property.get_settings_value(PropertySettings.KEY_EXPOSABLE, false)
	p_expose_button.button_pressed = property.get_settings_value(PropertySettings.KEY_EXPOSED, false)
	p_expose_button.toggled.connect(
		_on_property_expose_state_changed.bind(current_object, property.name)
	)

	# Apply read-only visual treatment: muted opacity + lock-icon tooltip suffix.
	# The actual field.set_editable(false) is called by FieldBinding._update_editable_state().
	if is_read_only:
		p_container.modulate = Color(1, 1, 1, 0.6)
		if p_label.tooltip_text.is_empty():
			p_label.tooltip_text = "(read-only)"
		else:
			p_label.tooltip_text += " (read-only)"

	return p_container


func _cache_category_states(category_states: Dictionary) -> void:
	for child: Control in field_container.get_children():
		var fc: FoldableContainer = child as FoldableContainer
		if fc:
			category_states[fc.title] = fc.folded


func _apply_category_state(container: FoldableContainer, category_name: String, category_states: Dictionary) -> void:
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
	var connected_node: InspectableNode = graph_edit.connection_manager.get_connected_node(node, property.name)

	if connected_node and connected_node.graph_view:
		EventBus.request_node_selection.emit(connected_node, connected_node.storyline_id)


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
		print("yooo")
		return

	_pending_expand_category = property.get_category()

	if obj == current_object:
		rebuild()
		return

	inspect(obj)
