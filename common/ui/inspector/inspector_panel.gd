class_name InspectorPanel extends PanelContainer

var _fields: Array[Field] = []
var _pending_expand_category: String = ""

@onready var back_button: Button = %BackButton
@onready var header_container: HBoxContainer = %FieldHeader
@onready var field_container: VBoxContainer = %Fields
@onready var run_button: Button = %RunButton
@onready var inspector_category_container: PackedScene = preload("uid://bvf68w7xrfrom")
@onready var expose_button: PackedScene = preload("uid://2ehh7rdn6yg6")

var current_objects: Array[InspectableObject] = []
## Selections the back button steps through, most recent last. Each entry is a whole
## selection, not a single object.
var history: Array[Array] = []
## Objects currently listened to, so a property that decides whether others are shown
## can be unsubscribed from when the selection moves on.
var _watched_objects: Array[InspectableObject] = []


func _ready() -> void:
	EventBus.request_objects_inspection.connect(inspect)
	EventBus.show_inspector.connect(_on_event_show_inspector)

	ProjectManager.project_loaded.connect(_on_project_loaded)
	back_button.pressed.connect(_on_back_button_pressed)
	visible = ConfigManager.get_config("show_inspector")


func _on_project_loaded() -> void:
	var command_manager: CommandManager = ProjectManager.current_project.command_manager
	command_manager.undone.connect(_on_history_undo_redo)
	command_manager.redone.connect(_on_history_undo_redo)


func _on_event_show_inspector(_visible: bool) -> void:
	inspect(current_objects)


## Called after every undo or redo. Re-resolves the inspection stack from the
## root so stale CollectionItem references are replaced with fresh objects, then rebuilds.
func _on_history_undo_redo() -> void:
	rebuild()


## Shows a selection. One object is not a special case here, just a selection of one.
##
## The graph's highlight is left alone: the graph owns it, and reaching in to clear it
## makes the graph announce a selection the user never made. Inspecting a collection
## item keeps its owning node highlighted, which is where the back button leads.
func inspect(objects: Array[InspectableObject], from_history: bool = false) -> void:
	var previous: Array[InspectableObject] = current_objects
	if not objects.is_empty() and not previous.is_empty() and previous != objects:
		if not from_history:
			history.append(previous)

	back_button.disabled = history.is_empty()
	current_objects = objects
	_watch_gates(objects)

	# Nothing selected means nothing to inspect. This used to hide the panel whenever
	# both the old and the new selection were non-empty, which is the normal case.
	if objects.is_empty() or not ConfigManager.get_config("show_inspector"):
		hide()
		return

	show()
	Log.info("Inspect %d object(s): %s" % [objects.size(), ", ".join(_selection_ids(objects))])

	rebuild()


func _selection_ids(objects: Array[InspectableObject]) -> PackedStringArray:
	var ids: PackedStringArray = []
	for object: InspectableObject in objects:
		ids.append(str(object.get_property_value("id")))
	return ids


func rebuild() -> void:
	_fields.clear()
	await get_tree().process_frame

	# Read the selection after the wait, not before: inspect() can run during that
	# frame, and building fields from one selection while binding them to another is
	# how a field ends up with no owner at all.
	var inspected: Array[InspectableObject] = current_objects

	var inspecting_nodes: bool = not inspected.is_empty()
	for obj: InspectableObject in inspected:
		if obj is not InspectableNode:
			inspecting_nodes = false
			break
	run_button.visible = inspecting_nodes  # TODO: Bad practice

	for field: Control in field_container.get_children():
		field.queue_free()

	for child: Control in header_container.get_children():
		child.queue_free()

	var separator: HSeparator = HSeparator.new()
	separator.theme_type_variation = "UltraWideHSeparator"
	field_container.add_child(separator)

	var properties: Array[Property] = _get_common_properties(inspected)

	if inspected.is_empty():
		_add_notice("Nothing to show here.", true)
	elif properties.is_empty():
		_add_notice(
			"These %d objects have no editable property in common." % inspected.size(), true
		)
	else:
		if inspected.size() > 1:
			_add_notice("Editing %d objects at once." % inspected.size())

		var categories: Dictionary = _group_by_category(properties)

		for category_name: String in categories.keys():
			var props: Array = categories[category_name]

			if category_name.begins_with("Special"):
				var special_category: String = category_name.trim_prefix("Special:")
				_handle_special_category_section(special_category, props)
				continue

			_create_category_section(category_name, props)

	_pending_expand_category = ""


## The object the inspector reads its context from: ports, exposure toggles, the run
## button. Those are per-object, so with several selected they follow the first.
func _primary() -> InspectableObject:
	return current_objects[0] if not current_objects.is_empty() else null


## Follows the inspected objects so that changing a property which decides whether
## others are shown redraws the panel around it.
func _watch_gates(objects: Array[InspectableObject]) -> void:
	for object: InspectableObject in _watched_objects:
		if not is_instance_valid(object):
			continue
		if object.property_changed.is_connected(_on_inspected_property_changed):
			object.property_changed.disconnect(_on_inspected_property_changed)

	_watched_objects = objects.duplicate()
	for object: InspectableObject in _watched_objects:
		object.property_changed.connect(_on_inspected_property_changed)


func _on_inspected_property_changed(property_name: String) -> void:
	for object: InspectableObject in _watched_objects:
		if is_instance_valid(object) and object.gates_other_properties(property_name):
			rebuild()
			return


## What the inspector shows for a selection. One object gives all its properties;
## several give only what they genuinely share, so editing is never ambiguous.
##
## The returned properties belong to the first object -- that is what the fields read
## and display. Writing fans out to the rest, see [FieldBinding].
func _get_common_properties(objects: Array[InspectableObject]) -> Array[Property]:
	var common: Array[Property] = []
	if objects.is_empty():
		return common

	var single: bool = objects.size() == 1
	for candidate: Property in objects[0].get_properties():
		if not single and not _is_shareable(candidate):
			continue
		if not single and not _every_object_declares(candidate, objects):
			continue
		common.append(candidate)

	return common


## Unique properties -- ids, names -- exist to tell objects apart, so editing them
## across a selection could only ever produce duplicates. Properties that own child
## objects are per-object by nature and have nothing to merge.
func _is_shareable(candidate: Property) -> bool:
	if candidate.get_settings_value(PropertySettings.KEY_UNIQUE, false):
		return false
	return candidate.type not in ["collection", "list"]


## Shared means same name and same type everywhere. Two "text" properties can be
## edited together; a text and a dropdown cannot.
func _every_object_declares(candidate: Property, objects: Array[InspectableObject]) -> bool:
	for object: InspectableObject in objects:
		var match_property: Property = object.get_property(candidate.name)
		if match_property == null or match_property.type != candidate.type:
			return false
	return true


## A centred line of text. [param fill] makes it take the whole panel, which is what
## the empty state wants; a heading above a property list does not.
func _add_notice(text: String, fill: bool = false) -> void:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if fill:
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field_container.add_child(label)


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
	var owner: InspectableObject = _primary()
	for prop: Property in properties:
		# Skip properties not visible in inspector
		if not prop.get_settings_value("visible_in_inspector", true):
			continue
		if owner and not owner.is_property_shown(prop):
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
				not _primary() is InspectableNode
				or not property.get_settings_value(PropertySettings.KEY_EXPOSABLE, false)
			)
			p_expose_button.button_pressed = property.get_settings_value(
				PropertySettings.KEY_EXPOSED, false
			)
			p_expose_button.toggled.connect(
				_on_property_expose_state_changed.bind(_primary(), property.name)
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
				not _primary() is InspectableNode
				or not property.get_settings_value(PropertySettings.KEY_EXPOSABLE, false)
			)
			p_expose_button.button_pressed = property.get_settings_value(
				PropertySettings.KEY_EXPOSED, false
			)
			p_expose_button.toggled.connect(
				_on_property_expose_state_changed.bind(_primary(), property.name)
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

	# The whole selection, so one edit reaches every object. A selection of one is the
	# ordinary case and needs no special handling.
	FieldWidgetFactory.bind_deferred(property, p_field, current_objects)
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
	if not _primary() or not _primary() is InspectableNode:
		return

	var node: InspectableNode = _primary() as InspectableNode

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
		var selection: Array[InspectableObject] = [connected_node]
		EventBus.request_nodes_selection.emit(selection, connected_node.storyline_id, false)


func _is_list(property: Property) -> bool:
	return property.type in ["list", "collection"]


func _on_back_button_pressed() -> void:
	if history.is_empty():
		return

	# history holds whole selections, so the entry has to be retyped on the way out.
	var previous: Array[InspectableObject] = []
	previous.assign(history.pop_back())
	inspect(previous, true)
