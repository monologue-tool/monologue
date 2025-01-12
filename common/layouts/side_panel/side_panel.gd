## Side panel which displays graph node details. This panel should not contain
## references to MonologueControl or GraphEditSwitcher.
class_name SidePanel extends PanelContainer


@onready var fields_container = $OuterMargin/Scroller/InnerMargin/VBox/Fields
@onready var topbox = $OuterMargin/Scroller/InnerMargin/VBox/HBox
@onready var ribbon_scene = preload("res://common/ui/ribbon/ribbon.tscn")
@onready var collapsible_field = preload("res://common/ui/fields/collapsible_field/collapsible_field.tscn")

var id_field: MonologueField
var selected_node: MonologueGraphNode


func _ready():
	GlobalSignal.add_listener("close_panel", _on_close_button_pressed)
	hide()


func clear():
	for field in fields_container.get_children():
		field.queue_free()
	if is_instance_valid(id_field):
		id_field.queue_free()


func on_graph_node_deselected(node):
	hide()


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
			id_field = node.get(property_name).show(topbox, 0)
		else:
			var field = node.get(property_name).show(fields_container)
			field.set_label_text(property_name.capitalize())

	show()


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
			_recursive_build_collapsible_field(fields_container, item, group, graph_node, already_invoke)

func _recursive_build_collapsible_field(parent: Control, item: Dictionary, group: String, graph_node: MonologueGraphNode, already_invoke: Array) -> CollapsibleField:
	var fields = item[group]
	var field_obj: CollapsibleField = collapsible_field.instantiate()
	if parent is CollapsibleField:
		parent.add_item(field_obj)
	else:
		parent.add_child(field_obj)
	field_obj.set_title(group)
	
	for field_name in fields:
		if field_name is Dictionary:
			for sub_group in field_name:
				_recursive_build_collapsible_field(field_obj, field_name, sub_group, graph_node, already_invoke)
			continue
		
		var property = graph_node.get(field_name)
		var field = property.show(fields_container)
		
		if property.custom_label != null:
			field.set_label_text(property.custom_label)
		else:
			field.set_label_text(field_name.capitalize())

		fields_container.remove_child(field)
		field_obj.add_item(field)
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


func _on_rfh_button_pressed() -> void:
	GlobalSignal.emit("test_trigger", [selected_node.id.value])


func _on_close_button_pressed(node: MonologueGraphNode = null) -> void:
	if not node or selected_node == node:
		selected_node.get_parent().set_selected(null)
