class_name MonologueGraphEdit extends CustomGraphEdit

signal node_view_selected(node: InspectableNode)

var characters := Property.new("characters", {}, "character", {})
var variables := Property.new("variables", {}, "variable", {})

var storyline_id: String
var connection_manager: ConnectionManager


func _ready() -> void:
	super._ready()


func refresh() -> void:
	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)

	# Initialize connection manager if not already done
	if not connection_manager:
		connection_manager = ConnectionManager.new(storyline)

	# Disconnect all existing graph connections
	clear_connections()

	for child: GraphElement in get_all_graph_nodes():
		child.queue_free()

	for node: InspectableNode in storyline.nodes:
		add_graph_node_view(node)

	# Reconnect all tracked connections after rebuilding nodes
	_reconnect_all_slots()


func refresh_node(node: InspectableNode) -> void:
	clear_connections()
	if node.graph_view:
		build_graph_node_view_content(node.graph_view, node)
	_reconnect_all_slots()


func add_graph_node_view(node: InspectableNode) -> void:
	var new_node: GraphNode = GraphNode.new()
	new_node.custom_minimum_size.x = 192
	build_graph_node_view_content(new_node, node)

	var new_node_title_bar: HBoxContainer = new_node.get_titlebar_hbox()
	new_node_title_bar.hide()

	new_node.node_selected.connect(_on_node_view_selected.bind(node))
	add_child(new_node)
	new_node.position_offset_changed.connect(_on_node_view_position_offset_changed.bind(node))

	node.graph_view = new_node
	node.add_observer(on_property_changed)


func build_graph_node_view_content(graph_node: GraphNode, node: InspectableNode) -> void:
	for child: Control in graph_node.get_children():
		graph_node.remove_child(child)
		child.queue_free()

	var title_bar: HBoxContainer = graph_node.get_titlebar_hbox()
	title_bar.hide()

	var properties: Array = node.get_properties()
	var rows: Array = []

	for prop: Property in properties:
		# Skip properties not visible in graph
		if not prop.settings.get("visible_in_graph", true):
			continue

		var enable_left: bool = prop.get_settings_value("exposed", false) or false
		var enable_right: bool = prop.get_settings_value("export", false) or false
		if prop.settings.get("is_main_property"):
			rows.push_front(
				GraphNodeRow.new(prop.get_display_name(), prop.type, enable_left, enable_right)
			)
			continue
		rows.append(GraphNodeRow.new(prop.name, prop.type, enable_left, enable_right))

	for row: GraphNodeRow in rows:
		var idx: int = rows.find(row)
		var hbox: HBoxContainer = HBoxContainer.new()
		var key_label: Label = Label.new()
		var value_label: Label = Label.new()

		hbox.theme_type_variation = "GraphNodeViewRownHBox"
		hbox.add_child(key_label)
		hbox.add_child(value_label)

		key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_label.text = row.get_key()
		if row.get_type():
			value_label.text = "[%s]" % row.get_type()

		var field_metadata: Dictionary = FieldBucket.get_metadata(row.get_type())
		var type_id: int = FieldBucket.get_type_id(row.get_type())
		var slot_in_texture: Texture2D = preload("res://ui/assets/icons/slot_in.svg")
		var slot_out_texture: Texture2D = preload("res://ui/assets/icons/slot_out.svg")

		var slot_color: Color = field_metadata.get("color", Color.WHITE)
		value_label.label_settings = LabelSettings.new()
		value_label.label_settings.font_color = slot_color

		# If is title row
		if idx <= 0:
			key_label.theme_type_variation = "GraphNodeViewTitleLabel"
		value_label.theme_type_variation = "GraphNodeViewValueLabel"

		graph_node.add_child(hbox)

		graph_node.set_slot(
			idx,
			row._enable_left_port,
			type_id,
			slot_color,
			row._enable_right_port,
			type_id,
			slot_color,
			slot_in_texture,
			slot_out_texture,
			true
		)

		graph_node.set_slot_custom_icon_left(idx, slot_in_texture)
		graph_node.set_slot_custom_icon_right(idx, slot_out_texture)

	graph_node.set_size(Vector2.ZERO)


func _on_node_view_selected(node: InspectableNode) -> void:
	node_view_selected.emit(node)


func _on_node_view_position_offset_changed(_node: InspectableNode) -> void:
	pass


func on_property_changed(node: InspectableNode, _pname: String) -> void:
	refresh_node(node)


func _on_connection_request(
	from_node: StringName, from_port: int, to_node: StringName, to_port: int
) -> void:
	if (
		_has_connection_at_slot(from_node, from_port, true)
		or _has_connection_at_slot(to_node, to_port, false)
	):
		return

	var from_graph_node: GraphNode = get_node(from_node as String)
	var to_graph_node: GraphNode = get_node(to_node as String)
	var from_port_type: int = from_graph_node.get_output_port_type(from_port)
	var to_port_type: int = to_graph_node.get_input_port_type(to_port)

	if from_port_type != to_port_type:
		return

	# Get property names at the port indices
	var from_property_name = get_property_name_at_port(String(from_node), from_port, true)
	var to_property_name = get_property_name_at_port(String(to_node), to_port, false)

	if from_property_name.is_empty() or to_property_name.is_empty():
		push_warning("Cannot create connection: property not found at port")
		return

	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)
	var command: NodeConnectionCommand = NodeConnectionCommand.new(
		self, String(from_node), String(to_node), from_property_name, to_property_name
	)
	storyline.history.execute(command)


func _has_connection_at_slot(node_name: StringName, port_index: int, is_output: bool) -> bool:
	var node_key := "from_node" if is_output else "to_node"
	var port_key := "from_port" if is_output else "to_port"
	var target_name := String(node_name)

	for connection: Dictionary in get_connection_list():
		if String(connection.get(node_key, "")) != target_name:
			continue
		if int(connection.get(port_key, -1)) == port_index:
			return true

	return false


func get_all_graph_nodes() -> Array:
	return get_children().filter(func(child) -> bool: return child is GraphNode)


## Reconnect all slots based on tracked connections in connection_manager
func _reconnect_all_slots() -> void:
	if not connection_manager:
		return

	var all_connections = connection_manager.get_all_connections()

	for conn in all_connections:
		var from_node_name = conn["from_node_name"]
		var from_property = conn["from_property"]
		var to_node_name = conn["to_node_name"]
		var to_property = conn["to_property"]

		# Get port indices for the properties
		var from_port = get_port_index_for_property(from_node_name, from_property)
		var to_port = get_port_index_for_property(to_node_name, to_property)

		# Only connect if both ports are valid
		if from_port >= 0 and to_port >= 0:
			connect_node(from_node_name, from_port, to_node_name, to_port)


## Get visible properties in the same order as displayed in graph
func _get_visible_properties(node: InspectableNode) -> Array[Property]:
	var visible_props: Array[Property] = []
	var properties = node.get_properties()

	for prop: Property in properties:
		if not prop.settings.get("visible_in_graph", true):
			continue
		var exposed = prop.get_settings_value("exposed", false) or false
		var export = prop.get_settings_value("export", false) or false

		# Skip if no ports
		if not exposed and not export:
			continue

		# Main property goes first
		if prop.settings.get("is_main_property"):
			visible_props.push_front(prop)
		else:
			visible_props.append(prop)

	return visible_props


## Get the port index for a specific property by name
func get_port_index_for_property(node_name: String, property_name: String) -> int:
	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)

	for node: InspectableNode in storyline.nodes:
		if node.graph_view.name == node_name:
			var visible_props = _get_visible_properties(node)

			# Find the property by name and return its index
			for i in range(visible_props.size()):
				if visible_props[i].name == property_name:
					return i
			break

	return -1


## Get property name at a specific port index
func get_property_name_at_port(node_name: String, port_index: int, is_output: bool) -> String:
	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)

	for node: InspectableNode in storyline.nodes:
		if node.graph_view.name == node_name:
			var count := 0
			for prop: Property in node.get_properties():
				var has_port: bool = (
					prop.get_settings_value("export", false)
					if is_output
					else prop.get_settings_value("exposed", false)
				)
				if not has_port:
					continue
				if count == port_index:
					return prop.name
				count += 1

	return ""
