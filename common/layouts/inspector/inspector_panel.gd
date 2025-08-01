## Side panel which displays graph node details. This panel should not contain
## references to MonologueEditor or GraphEditSwitcher.
class_name InspectorPanel extends PanelContainer

@onready var fields_container = %Fields
@onready var topbox = %TopBox
@onready var ribbon_scene = preload("res://common/ui/ribbon/ribbon.tscn")
@onready var collapsible_field = preload("res://common/ui/fields/collapsible_field/collapsible_field.tscn")

var collapsibles: Dictionary[String, CollapsibleField]
var id_field_container: Control
var selected_node: MonologueGraphNode


func _ready():
	GlobalSignal.add_listener("close_panel", _on_close_button_pressed)


func clear():
	for field in fields_container.get_children():
		field.free()
	if is_instance_valid(id_field_container):
		id_field_container.queue_free()
	collapsibles.clear()


func on_graph_node_deselected(_node: MonologueGraphNode) -> void:
	pass


func on_graph_node_selected(node: MonologueGraphNode, bypass: bool = false) -> void:
	if not node:
		return
	
	if not bypass:
		var graph_edit = node.get_parent()
		await get_tree().process_frame
		if (
			is_instance_valid(node)
			and not graph_edit.moving_mode
			and graph_edit.selected_nodes.size() == 1
		):
			graph_edit.active_graphnode = node
		else:
			graph_edit.active_graphnode = null
			return
	
	if node is BackgroundNode:
		return on_new_graph_node_selected(node, bypass)

	# hack to preserve focus if the side panel contains the same node paths
	var focus_owner = get_viewport().gui_get_focus_owner()
	var refocus_path: NodePath = ""
	var refocus_line: int = -1
	var refocus_column: int = -1
	if focus_owner:
		refocus_path = get_path_to(focus_owner)
		if focus_owner is TextEdit:
			refocus_line = focus_owner.get_caret_line()
			refocus_column = focus_owner.get_caret_column()
		elif focus_owner is LineEdit:
			refocus_column = focus_owner.get_caret_column()
	var uncollapse_paths: Array[NodePath] = []
	if node == selected_node:
		for collapsible: CollapsibleField in collapsibles.values():
			if collapsible.is_open():
				uncollapse_paths.append(get_path_to(collapsible))

	clear()
	selected_node = node
	node._update()

	if not node.is_editable():
		return

	var items = node._get_field_groups()
	var already_invoke := []
	var property_names = node.get_property_names()

	for item in items:
		_load_groups(item, node, already_invoke)

	for property_name in property_names:
		if property_name in already_invoke:
			continue

		if property_name == "id":
			var property = node.get(property_name)
			var field = property.show(topbox, 0, false)
			field.set_label_visible(false)
			id_field_container = property.field_container
		else:
			var field = node.get(property_name).show(fields_container)
			field.set_label_text(property_name.capitalize())

	show()
	restore_collapsible_state(uncollapse_paths)
	# if focus was preserved, restore it
	restore_focus(refocus_path, refocus_line, refocus_column)


func on_new_graph_node_selected(node: MonologueGraphNode, bypass: bool = false) -> void:
	var properties := node._get_inspector_property_list()
	print(properties)
	# Create a field in the inspector
	# Link the field to the property and if any changes to the property is made, update the value of the property
	# + Undo/Redo


func _load_groups(item, graph_node: MonologueGraphNode, already_invoke) -> void:
	if item is String:
		var property = graph_node.get(item)
		var field = property.show(fields_container)

		if property.custom_label != null:
			field.set_label_text(property.custom_label)
		else:
			field.set_label_text(item.capitalize())

		already_invoke.append(item)
	else:
		for group in item:
			_recursive_build_collapsible_field(
				fields_container, item, group, graph_node, already_invoke
			)


func _recursive_build_collapsible_field(
	parent: Control,
	item: Dictionary,
	group: String,
	graph_node: MonologueGraphNode,
	already_invoke: Array
) -> CollapsibleField:
	var fields = item[group]
	var field_obj: CollapsibleField = collapsible_field.instantiate()
	var field_margin = MarginContainer.new()
	field_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_margin.add_theme_constant_override("margin_right", 0)
	field_margin.add_theme_constant_override("margin_bottom", 0)
	field_margin.add_child(field_obj)
	if parent is CollapsibleField:
		parent.add_item(field_margin)
	else:
		parent.add_child(field_margin)
	field_obj.set_title(group)

	for field_name in fields:
		if field_name is Dictionary:
			for sub_group in field_name:
				_recursive_build_collapsible_field(
					field_obj, field_name, sub_group, graph_node, already_invoke
				)
			continue

		var property: Property = graph_node.get(field_name)
		var field = property.show(fields_container)
		var field_container = property.field_container

		if property.custom_label != null:
			field.set_label_text(property.custom_label)
		else:
			field.set_label_text(field_name.capitalize())

		fields_container.remove_child(field_container)
		field_obj.add_item(field_container)
		already_invoke.append(field_name)

		field.collapsible_field = field_obj
		if property.uncollapse:
			field_obj.open()
			property.uncollapse = false
	return field_obj


## If the side panel for the node is visible, release the focus so that
## text controls trigger the focus_exited() signal to update.
func refocus(node: MonologueGraphNode) -> void:
	if visible and selected_node == node:
		var focus_owner = get_viewport().gui_get_focus_owner()
		if focus_owner:
			focus_owner.release_focus()
			focus_owner.grab_focus()


## If any collapsible fields were opened before the side panel was refreshed,
## this method will reopen them via their node paths.
func restore_collapsible_state(uncollapse_paths: Array[NodePath]) -> void:
	for path in uncollapse_paths:
		var field = get_node_or_null(path)
		if is_instance_valid(field) and field is CollapsibleField:
			field.open()


## Hacky improvement for #52 to maintain focus on side panel refresh.
func restore_focus(node_path: NodePath, line: int, column: int) -> void:
	if node_path:
		var node = get_node_or_null(node_path)
		if is_instance_valid(node) and node is Control:
			node.grab_focus()
			if line >= 0:
				node.set_caret_line(line)
			if column >= 0:
				node.set_caret_column(column)


func _on_rfh_button_pressed() -> void:
	GlobalSignal.emit("test_trigger", [selected_node.id.value])


func _on_close_button_pressed(node: MonologueGraphNode = null) -> void:
	if not node or selected_node == node:
		selected_node.get_parent().set_selected(null)
