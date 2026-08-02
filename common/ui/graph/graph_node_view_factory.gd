class_name GraphNodeViewFactory extends RefCounted

const SLOT_IN_TEXTURE: Texture2D = preload("res://ui/assets/icons/slot_in.svg")
const SLOT_OUT_TEXTURE: Texture2D = preload("res://ui/assets/icons/slot_out.svg")


static func build(node: InspectableNode) -> GraphNode:
	var graph_node: GraphNode = GraphNode.new()
	graph_node.custom_minimum_size.x = 192
	graph_node.draggable = true
	graph_node.selectable = true
	graph_node.resizable = false
	modulate_stylebox(graph_node, node)
	apply_metadata(graph_node, node)
	populate(graph_node, node)
	return graph_node


static func modulate_stylebox(graph_node: GraphNode, node: InspectableNode) -> void:
	var color_prop: Property = node.get_property("color")
	if not color_prop:
		return

	var node_color: Color = Color(str(color_prop.get_value()))
	var sb_names: Array = ["panel", "panel_selected"]

	for sb_name: String in sb_names:
		graph_node.remove_theme_stylebox_override(sb_name)

	if node_color == Color.BLACK:
		return

	for sb_name: String in sb_names:
		var base_sb: StyleBox = graph_node.get_theme_stylebox(sb_name)

		if base_sb is StyleBoxFlat:
			var flat_sb: StyleBoxFlat = base_sb as StyleBoxFlat
			var new_sb: StyleBoxFlat = flat_sb.duplicate()
			var new_bg_color: Color = Color(node_color, 0.35)
			var new_border_color: Color = Color(node_color, 0.35)
			new_bg_color = flat_sb.bg_color.blend(new_bg_color)
			new_border_color = flat_sb.border_color.blend(new_border_color)
			new_sb.bg_color = new_bg_color
			new_sb.border_color = new_border_color
			graph_node.add_theme_stylebox_override(sb_name, new_sb)


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

	var rows: Array[GraphNodeRow] = _build_rows(node)
	for idx: int in rows.size():
		var row: GraphNodeRow = rows[idx]
		var container: HBoxContainer = HBoxContainer.new()
		container.mouse_filter = Control.MOUSE_FILTER_PASS
		container.theme_type_variation = "GraphNodeViewRownHBox"

		var key_label: Label = Label.new()
		key_label.mouse_filter = Control.MOUSE_FILTER_PASS
		key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_label.text = row.get_key()

		var value_label: Label = Label.new()
		value_label.mouse_filter = Control.MOUSE_FILTER_PASS
		if row.get_type():
			value_label.text = "[%s]" % row.get_type()

		var row_indexer: FieldIndexer = MonologueRegistry.get_instance().get_field(row.get_type())
		var slot_color: Color = row_indexer.color if row_indexer else Color.WHITE

		value_label.label_settings = LabelSettings.new()
		value_label.label_settings.font_color = slot_color

		if idx == 0:
			key_label.theme_type_variation = "GraphNodeViewTitleLabel"
		value_label.theme_type_variation = "GraphNodeViewValueLabel"

		container.add_child(key_label)
		container.add_child(value_label)
		graph_node.add_child(container)

		if row.port_size == "large":
			container.custom_minimum_size.y = 32

		var type_id: int = row.port_type_id
		if type_id == 0:
			type_id = MonologueRegistry.get_instance().get_field_type_id(row.get_type())
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

	# reset_size() shrinks to the minimum size directly. set_size(Vector2.ZERO) got
	# there too, but left the node at zero until the next layout pass, and any port
	# position read during that window was meaningless.
	graph_node.reset_size()


## Names the view after the node's id and titles it with the node's own title,
## falling back to the type name when the title is blank.
static func apply_metadata(graph_node: GraphNode, node: InspectableNode) -> void:
	if not is_instance_valid(graph_node):
		return
	var title: String = str(node.get_property_value("title"))
	graph_node.title = title if not title.is_empty() else Util.to_readable_name(node.get_type())
	var id_prop: Property = node.get_property("id")
	graph_node.name = str(id_prop.get_value()) if id_prop else _derive_node_name(node)


static func _build_rows(node: InspectableNode) -> Array[GraphNodeRow]:
	var rows: Array[GraphNodeRow] = []
	for prop: Property in node.get_properties():
		if not prop.is_visible_in_graph():
			continue

		var row: GraphNodeRow = _build_property_row(prop)
		if prop.get_settings_value("is_main_property"):
			rows.push_front(row)
			continue
		rows.append(row)

		if prop.type == "collection":
			rows.append_array(_build_list_sub_rows(node, prop))

	return rows


static func _build_property_row(prop: Property) -> GraphNodeRow:
	var enable_left: bool = prop.get_settings_value("exposed", false) == true
	var enable_right: bool = prop.get_settings_value("export", false) == true
	var label: String = (
		prop.get_display_name() if prop.get_settings_value("is_main_property") else prop.name
	)
	# A collection port accepts whatever its items' main property exports, so that an
	# option node can be plugged into a choice node's option list.
	# TODO: do the same for `list` properties, whose port type is still just "list".
	var row_type: String = prop.type
	if prop.type == "collection":
		var collection_name: String = prop.get_settings_value(PropertySettings.KEY_COLLECTION, "")
		var indexer: CollectionIndexer = MonologueRegistry.get_instance().get_collection(
			collection_name
		)
		if indexer and not indexer.port_type.is_empty():
			row_type = indexer.port_type
	var row: GraphNodeRow = GraphNodeRow.new(label, row_type, enable_left, enable_right)
	row._property_name = prop.name
	row.port_size = prop.get_settings_value(PropertySettings.KEY_PORT_SIZE, "normal")
	if prop.type == "reference":
		_apply_reference_port(row, prop)
	return row


## Types a reference row after what it points at, so a character port only accepts
## another character port.
static func _apply_reference_port(row: GraphNodeRow, prop: Property) -> void:
	var scope: String = str(prop.get_settings_value(PropertySettings.KEY_REFERENCE_SCOPE, ""))
	if scope.is_empty():
		return
	row.port_type_id = MonologueRegistry.get_instance().get_reference_type_id(scope)


static func _build_list_sub_rows(node: InspectableNode, prop: Property) -> Array[GraphNodeRow]:
	var sub_rows: Array[GraphNodeRow] = []
	var coll_name: String = prop.get_settings_value(PropertySettings.KEY_COLLECTION, "")
	if coll_name.is_empty():
		return sub_rows

	var probe: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		coll_name, CommandManager.new()
	)
	if not probe or not probe.has_main_property():
		return sub_rows

	# Internal items from the property value
	var list_value: Variant = prop.get_value()
	if list_value is Array:
		for item_data: Dictionary in list_value:
			if not item_data is Dictionary:
				continue
			var item_id: String = _extract_dict_string(item_data, "id")
			if item_id.is_empty():
				continue
			var item_name: String = _extract_dict_string(item_data, "name")
			var sub_label: String = "  %s" % [item_name if not item_name.is_empty() else item_id]
			var sub_row: GraphNodeRow = GraphNodeRow.new(sub_label, "context", false, true)
			sub_row.sub_property_id = "%s%s%s" % [
				prop.name, NodeConnection.ITEM_SEPARATOR, item_id
			]
			sub_rows.append(sub_row)

	# External items (e.g. connected OptionNodes)
	var externals: Array[Dictionary] = node.get_external_list_items(prop.name)
	for ext_data: Dictionary in externals:
		var ext_name: String = ext_data.get("name", "")
		var ext_src_id: String = ext_data.get("source_node_id", "")
		if ext_src_id.is_empty():
			continue
		var sub_label: String = "  %s" % [ext_name if not ext_name.is_empty() else ext_src_id]
		var sub_row: GraphNodeRow = GraphNodeRow.new(sub_label, "context", false, true)
		sub_row.sub_property_id = "%s:ext_%s" % [prop.name, ext_src_id]
		sub_rows.append(sub_row)

	return sub_rows


## Extracts a string from a dict value.
static func _extract_dict_string(data: Dictionary, key: String) -> String:
	var raw_dict: Dictionary = data.get(key, {})
	return str(raw_dict.get("value", ""))


## Returns the node's id, allocating one when it somehow has none.
static func _derive_node_name(node: InspectableNode) -> String:
	var id_value: String = ""
	var id_property: Property = node.get_property("id")
	if id_property:
		id_value = str(id_property.get_value())
	if id_value.is_empty():
		id_value = IDGen.generate_object_id(node.get_type())
	return id_value
