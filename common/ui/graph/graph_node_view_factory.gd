class_name GraphNodeViewFactory extends RefCounted

const SLOT_IN_TEXTURE: Texture2D = preload("res://ui/assets/icons/slot_in.svg")
const SLOT_OUT_TEXTURE: Texture2D = preload("res://ui/assets/icons/slot_out.svg")
## The preview panel, named so that a value changing can replace it without the rest of the
## view being torn down around it.
const PREVIEW_NAME: StringName = &"Preview"
## As tall as a preview is ever drawn, whatever it decided to build.
const PREVIEW_MAX_HEIGHT: float = 96.0
## How much of a list item's name a node shows. A node is a diagram of the story, not the
## story itself: past this the name is cut and the whole of it read in the inspector.
const MAX_LIST_LABEL: int = 28
## How far a list item's type is faded behind the properties framing it.
const LIST_LABEL_ALPHA: float = 0.5


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
		# What a row gives back is the informative half when the two differ: an empty reroute
		# reads "any", and one with something plugged in reads what it is carrying.
		var shown_label: String = (
			row.output_type_label if not row.output_type_label.is_empty()
			else row.get_type_label()
		)
		if shown_label:
			value_label.text = "[%s]" % shown_label

		var slot_color: Color = NodePort.color_of(row.get_type())

		value_label.label_settings = LabelSettings.new()
		value_label.label_settings.font_color = slot_color

		if idx == 0:
			key_label.theme_type_variation = "GraphNodeViewTitleLabel"
		value_label.theme_type_variation = "GraphNodeViewValueLabel"

		# What a list holds is the node's contents rather than its shape, so it reads
		# behind the properties that frame it.
		if not row.sub_property_id.is_empty():
			key_label.theme_type_variation = "GraphNodeViewListLabel"
			value_label.label_settings.font_color = Color(slot_color, LIST_LABEL_ALPHA)

		container.add_child(key_label)
		container.add_child(value_label)
		graph_node.add_child(container)

		if row.port_size == "large":
			container.custom_minimum_size.y = 32

		var type_id: int = row.port_type_id
		if type_id == 0:
			type_id = MonologueRegistry.get_instance().get_field_type_id(row.get_type())
		# The two sides are typed apart so that a reroute can take in anything and still give
		# back only what it was given.
		var out_type_id: int = row.output_type_id if row.output_type_id != 0 else type_id
		var out_color: Color = (
			row.output_color if row.output_color != Color.TRANSPARENT else slot_color
		)
		graph_node.set_slot(
			idx,
			row._enable_left_port,
			type_id,
			slot_color,
			row._enable_right_port,
			out_type_id,
			out_color,
			SLOT_IN_TEXTURE,
			SLOT_OUT_TEXTURE,
			true
		)

		graph_node.set_slot_custom_icon_left(idx, SLOT_IN_TEXTURE)
		graph_node.set_slot_custom_icon_right(idx, SLOT_OUT_TEXTURE)

	_add_preview(graph_node, node)

	# reset_size() shrinks to the minimum size directly. set_size(Vector2.ZERO) got
	# there too, but left the node at zero until the next layout pass, and any port
	# position read during that window was meaningless.
	graph_node.reset_size()


## Replaces the preview without touching anything else. The ports keep their indices, so
## the wires hanging off them are never disturbed.
static func refresh_preview(graph_node: GraphNode, node: InspectableNode) -> void:
	if not is_instance_valid(graph_node):
		return

	var showing: Node = graph_node.get_node_or_null(NodePath(PREVIEW_NAME))
	if showing:
		graph_node.remove_child(showing)
		showing.queue_free()

	_add_preview(graph_node, node)
	graph_node.reset_size()


## Draws what the node holds under its ports, when it has anything to show.
##
## Clipped rather than fitted: the preview gets whatever width the ports above it already
## gave the node and is cut where that runs out, so no node is ever made wider by one, nor
## taller than [constant PREVIEW_MAX_HEIGHT] however much its preview decided to draw.
static func _add_preview(graph_node: GraphNode, node: InspectableNode) -> void:
	var preview: Control = node._build_preview(_language())
	if preview == null:
		return

	var panel: PanelContainer = PanelContainer.new()
	panel.name = PREVIEW_NAME
	panel.theme_type_variation = "GraphNodeViewPreviewPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_PASS

	# A plain Control rather than a container: it does not grow to hold what is inside it,
	# which is the whole of how a preview is kept from deciding how big its node is.
	var window: Control = Control.new()
	window.clip_contents = true
	window.mouse_filter = Control.MOUSE_FILTER_PASS
	window.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	window.custom_minimum_size.y = clampf(
		preview.custom_minimum_size.y, NodePreview.LINE_HEIGHT, PREVIEW_MAX_HEIGHT
	)

	preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	window.add_child(preview)
	panel.add_child(window)
	graph_node.add_child(panel)


static func _language() -> String:
	var project: MonologueProject = ProjectManager.current_project
	return project.active_language_code if project else ""


## Names the view after the node's id and titles it with the node's own title,
## falling back to the type name when the title is blank.
static func apply_metadata(graph_node: GraphNode, node: InspectableNode) -> void:
	if not is_instance_valid(graph_node):
		return
	graph_node.title = str(node.get_property_value("label"))
	var id_prop: Property = node.get_property("id")
	graph_node.name = str(id_prop.get_value()) if id_prop else _derive_node_name(node)


static func _build_rows(node: InspectableNode) -> Array[GraphNodeRow]:
	var rows: Array[GraphNodeRow] = []
	for prop: Property in node.get_properties():
		if not prop.is_visible_in_graph():
			continue

		var row: GraphNodeRow = _build_property_row(prop, node)
		if prop.get_settings_value("is_main_property"):
			rows.push_front(row)
			continue
		rows.append(row)

		if prop.type == "collection":
			rows.append_array(_build_list_sub_rows(node, prop))

	return rows


static func _build_property_row(prop: Property, owner: InspectableNode) -> GraphNodeRow:
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

	# What a node takes in is what it declares. What it gives back may be something it is
	# only carrying. The two are one row for every node but a reroute.
	var taken: Dictionary = NodePort.declared(owner, prop)
	var given: Dictionary = NodePort.of(owner, prop)
	row.port_type_id = int(taken["type_id"])
	row.type_label = str(taken["label"])

	if int(given["type_id"]) != int(taken["type_id"]):
		row.output_type_id = int(given["type_id"])
		row.output_type_label = str(given["label"])
		row.output_color = given["color"]
	return row


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

	var indexer: CollectionIndexer = MonologueRegistry.get_instance().get_collection(coll_name)
	var label_property: String = indexer.label_property if indexer else "name"

	# Internal items from the property value
	var list_value: Variant = prop.get_value()
	if list_value is Array:
		for item_index: int in list_value.size():
			var item_data: Variant = list_value[item_index]
			if not item_data is Dictionary:
				continue
			var item_id: String = _extract_dict_string(item_data, "id")
			if item_id.is_empty():
				continue
			var sub_label: String = "  %s" % _shorten(
				_item_label(item_data, label_property, probe.get_type(), item_index)
			)
			var sub_row: GraphNodeRow = GraphNodeRow.new(sub_label, "context", false, true)
			sub_row.sub_property_id = "%s%s%s" % [
				prop.name, NodeConnection.ITEM_SEPARATOR, item_id
			]
			sub_rows.append(sub_row)

	# External items (e.g. connected OptionNodes)
	var externals: Array[Dictionary] = node.get_external_list_items(prop.name)
	for ext_index: int in externals.size():
		var ext_data: Dictionary = externals[ext_index]
		var ext_name: String = ext_data.get("name", "")
		var ext_src_id: String = ext_data.get("source_node_id", "")
		if ext_src_id.is_empty():
			continue
		if ext_name.is_empty():
			ext_name = "%s %d" % [Util.to_readable_name(probe.get_type()), ext_index + 1]
		var sub_label: String = "  %s" % _shorten(ext_name)
		var sub_row: GraphNodeRow = GraphNodeRow.new(sub_label, "context", false, true)
		sub_row.sub_property_id = "%s%s%s%s" % [
			prop.name, NodeConnection.ITEM_SEPARATOR, NodeConnection.EXTERNAL_PREFIX, ext_src_id
		]
		sub_rows.append(sub_row)

	return sub_rows


## Cuts a list item's name down to what a node has room for, since the name is written
## with no thought for how wide the node it lands in is.
static func _shorten(label: String) -> String:
	if label.length() <= MAX_LIST_LABEL:
		return label
	return "%s…" % label.substr(0, MAX_LIST_LABEL - 1).strip_edges(false, true)


static func _extract_dict_string(data: Dictionary, key: String) -> String:
	return str(data.get(key, ""))


## How one list item is named in the graph. Falls back to its type and position rather
## than its id: an id says nothing to the person reading the node.
static func _item_label(
	item_data: Dictionary, label_property: String, type_name: String, item_index: int
) -> String:
	var project: MonologueProject = ProjectManager.current_project
	var label: String = Util.to_label(
		item_data.get(label_property), project.active_language_code if project else ""
	)
	if not label.is_empty():
		return label
	return "%s %d" % [Util.to_readable_name(type_name), item_index + 1]


## Returns the node's id, allocating one when it somehow has none.
static func _derive_node_name(node: InspectableNode) -> String:
	var id_value: String = ""
	var id_property: Property = node.get_property("id")
	if id_property:
		id_value = str(id_property.get_value())
	if id_value.is_empty():
		id_value = IDGen.generate_object_id(node.get_type())
	return id_value
