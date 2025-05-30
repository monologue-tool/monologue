## Side panel which displays graph node details. This panel should not contain
## references to MonologueControl or GraphEditSwitcher.
class_name SidePanel extends PanelContainer


@onready var fields_container = %Fields
@onready var topbox = %TopBox
@onready var ribbon_scene = preload("res://common/ui/ribbon/ribbon.tscn")
@onready var collapsible_field = preload("res://common/ui/fields/collapsible_field/collapsible_field.tscn")

var collapsibles: Dictionary[String, CollapsibleField]
var id_field_container: Control
var selected_node: MonologueGraphNode


func _ready():
	GlobalSignal.add_listener("close_panel", _on_close_button_pressed)
	hide()


func clear():
	for field in fields_container.get_children():
		field.free()
	if is_instance_valid(id_field_container):
		id_field_container.queue_free()
	collapsibles.clear()


func on_graph_node_deselected(_node):
	hide.call_deferred()


func on_graph_node_selected(node: MonologueGraphNode, bypass: bool = false):
	if not bypass:
		var graph_edit = node.get_parent()
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(node) and not graph_edit.moving_mode and \
				graph_edit.selected_nodes.size() == 1:
			graph_edit.active_graphnode = node
		else:
			graph_edit.active_graphnode = null
			return
	
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
		if item is String:
			var field = node.get(item).show(fields_container)
			field.set_label_text(item.capitalize())
			already_invoke.append(item)
		else:
			for group in item:
				var fields = item[group]
				var field_obj: CollapsibleField = collapsible_field.instantiate()
				fields_container.add_child(field_obj, true)
				field_obj.set_title(group)
				
				for field_name in fields:
					var property = node.get(field_name)
					var field = property.show(fields_container)
					field.set_label_text(field_name.capitalize())
					
					fields_container.remove_child(property.field_container)
					field_obj.add_item(property.field_container)
					already_invoke.append(field_name)
					
					field.collapsible_field = field_obj
					if property.uncollapse:
						field_obj.open()
						property.uncollapse = false
					collapsibles[field_name] = field_obj
	
	for property_name in property_names:
		if property_name in already_invoke:
			continue

		if property_name == "id":
			var field = node.get(property_name)
			field.show(topbox, 0, false)
			id_field_container = field.field_container
		else:
			var field = node.get(property_name).show(fields_container)
			field.set_label_text(property_name.capitalize())
	
	show()
	restore_collapsible_state(uncollapse_paths)
	# if focus was preserved, restore it
	restore_focus(refocus_path, refocus_line, refocus_column)


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
