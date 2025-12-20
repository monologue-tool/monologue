class_name GraphNodeViewFactory extends RefCounted

const SLOT_IN_TEXTURE := preload("res://ui/assets/icons/slot_in.svg")
const SLOT_OUT_TEXTURE := preload("res://ui/assets/icons/slot_out.svg")


static func build(node: InspectableNode) -> GraphNode:
	var graph_node := GraphNode.new()
	graph_node.custom_minimum_size.x = 192
	graph_node.draggable = true
	graph_node.selectable = true
	graph_node.resizable = false
	apply_metadata(graph_node, node)
	populate(graph_node, node)
	return graph_node


static func populate(graph_node: GraphNode, node: InspectableNode) -> void:
	if not is_instance_valid(graph_node):
		return

	apply_metadata(graph_node, node)

	for child: Control in graph_node.get_children():
		graph_node.remove_child(child)
		child.queue_free()

	if graph_node.has_method("clear_all_slots"):
		graph_node.clear_all_slots()

	var title_bar: HBoxContainer = graph_node.get_titlebar_hbox()
	if title_bar:
		title_bar.hide()

	var rows := _build_rows(node)
	for idx in rows.size():
		var row: GraphNodeRow = rows[idx]
		var container := HBoxContainer.new()
		container.mouse_filter = Control.MOUSE_FILTER_PASS
		container.theme_type_variation = "GraphNodeViewRownHBox"

		var key_label := Label.new()
		key_label.mouse_filter = Control.MOUSE_FILTER_PASS
		key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_label.text = row.get_key()

		var value_label := Label.new()
		value_label.mouse_filter = Control.MOUSE_FILTER_PASS
		if row.get_type():
			value_label.text = "[%s]" % row.get_type()

		var field_metadata := FieldBucket.get_metadata(row.get_type())
		var slot_color: Color = field_metadata.get("color", Color.WHITE)

		value_label.label_settings = LabelSettings.new()
		value_label.label_settings.font_color = slot_color

		if idx == 0:
			key_label.theme_type_variation = "GraphNodeViewTitleLabel"
		value_label.theme_type_variation = "GraphNodeViewValueLabel"

		container.add_child(key_label)
		container.add_child(value_label)
		graph_node.add_child(container)

		var type_id: int = FieldBucket.get_type_id(row.get_type())
		graph_node.set_slot(
			idx,
			row._enable_left_port,
			type_id,
			slot_color,
			row._enable_right_port,
			type_id,
			slot_color,
			SLOT_IN_TEXTURE,
			SLOT_OUT_TEXTURE,
			true
		)

		graph_node.set_slot_custom_icon_left(idx, SLOT_IN_TEXTURE)
		graph_node.set_slot_custom_icon_right(idx, SLOT_OUT_TEXTURE)

	graph_node.set_size(Vector2.ZERO)


static func apply_metadata(graph_node: GraphNode, node: InspectableNode) -> void:
	if not is_instance_valid(graph_node):
		return
	graph_node.title = Util.to_readable_name(node.get_type())
	graph_node.name = _derive_node_name(node)


static func _build_rows(node: InspectableNode) -> Array[GraphNodeRow]:
	var rows: Array[GraphNodeRow] = []
	for prop: Property in node.get_properties():
		var enable_left: bool = bool(prop.get_settings_value("exposed", false))
		var enable_right: bool = bool(prop.get_settings_value("export", false))
		if (
			not prop.get_settings_value("visible_in_graph", true)
			and not (enable_left or enable_right)
		):
			continue

		var label := (
			prop.get_display_name() if prop.get_settings_value("is_main_property") else prop.name
		)
		var row := GraphNodeRow.new(label, prop.type, enable_left, enable_right)
		if prop.get_settings_value("is_main_property"):
			rows.push_front(row)
			continue
		rows.append(row)

	return rows


static func _derive_node_name(node: InspectableNode) -> String:
	var id_value := ""
	var id_property := node.get_property("id")
	if id_property:
		id_value = String(id_property.get_value())
	if id_value.is_empty():
		id_value = IDGen.generate(5)
	return "%s_%s" % [node.get_type(), id_value]
