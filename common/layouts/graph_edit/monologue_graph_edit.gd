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

	for child: GraphElement in get_all_graph_nodes():
		child.queue_free()

	for node: InspectableNode in storyline.nodes:
		add_graph_node_view(node)


func refresh_node(node: InspectableNode) -> void:
	if node.graph_view:
		build_graph_node_view_content(node.graph_view, node)


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


func _on_node_view_position_offset_changed(node: InspectableNode) -> void:
	pass


func on_property_changed(node: InspectableNode, _pname: String) -> void:
	refresh_node(node)


## Connects/disconnects and updates a given connection's NextID if possible.
## If [param next] is true, establish connection and propagate NextIDs.
## If it is false, destroy connection and clear all linked NextIDs.
func propagate_connection(from_node: StringName, from_port, to_node, to_port, next = true) -> void:
	if next:
		connect_node(from_node, from_port, to_node, to_port)
		# Register connection in connection manager
		if connection_manager:
			connection_manager.register_connection(
				String(from_node), from_port, String(to_node), to_port
			)
	else:
		disconnect_node(from_node, from_port, to_node, to_port)
		# Unregister connection from connection manager
		if connection_manager:
			connection_manager.unregister_connection(
				String(from_node), from_port, String(to_node), to_port
			)

	# TODO: Rework this

	var graph_node = get_node_or_null(NodePath(from_node))
	if graph_node and graph_node.has_method("update_next_id"):
		if next:
			var next_node = get_node_or_null(NodePath(to_node))
			graph_node.update_next_id(from_port, next_node)
		else:
			graph_node.update_next_id(from_port, null)


func _on_connection_request(
	from_node: StringName, from_port: int, to_node: StringName, to_port: int
) -> void:
	if get_all_connections_from_slot(from_node, from_port).size() > 0:
		return

	var from_graph_node: GraphNode = get_node(from_node as String)
	var to_graph_node: GraphNode = get_node(to_node as String)
	var from_port_type: int = from_graph_node.get_output_port_type(from_port)
	var to_port_type: int = to_graph_node.get_input_port_type(to_port)

	if from_port_type != to_port_type:
		return

	# Get property names at the port indices
	var from_property_name = get_property_name_at_port(String(from_node), from_port)
	var to_property_name = get_property_name_at_port(String(to_node), to_port)
	
	if from_property_name.is_empty() or to_property_name.is_empty():
		push_warning("Cannot create connection: property not found at port")
		return

	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)
	var command: NodeConnectionCommand = NodeConnectionCommand.new(
		self, String(from_node), String(to_node), from_property_name, to_property_name
	)
	storyline.history.execute(command)


func get_all_graph_nodes() -> Array:
	return get_children().filter(func(child) -> bool: return child is GraphNode)


## Get the port index for a specific property by name
## This allows connections to be maintained even when ports are reordered
func get_port_index_for_property(node_id: String, property_name: String) -> int:
	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)
	var node: InspectableNode = null
	
	# Find the node by ID
	for n: InspectableNode in storyline.nodes:
		if n.get_property_value("id") == node_id:
			node = n
			break
	
	if not node:
		return -1
	
	var properties = node.get_properties()
	var visible_props: Array[Property] = []
	
	# Build list of visible properties in graph (matching graph display logic)
	for prop: Property in properties:
		if not prop.settings.get("visible_in_graph", true):
			continue
		var has_input = prop.settings.get("has_input_port", false)
		var has_output = prop.settings.get("has_output_port", false)
		if not has_input and not has_output:
			continue
		
		# Main property goes first
		if prop.settings.get("is_main_property"):
			visible_props.push_front(prop)
		else:
			visible_props.append(prop)
	
	# Find the property by name and return its index
	for i in range(visible_props.size()):
		if visible_props[i].name == property_name:
			return i
	
	return -1


## Get property name at a specific port index
func get_property_name_at_port(node_id: String, port_index: int) -> String:
	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)
	var node: InspectableNode = null
	
	# Find the node by ID
	for n: InspectableNode in storyline.nodes:
		if n.get_property_value("id") == node_id:
			node = n
			break
	
	if not node:
		return ""
	
	var properties = node.get_properties()
	var visible_props: Array[Property] = []
	
	# Build list of visible properties in graph (matching graph display logic)
	for prop: Property in properties:
		if not prop.settings.get("visible_in_graph", true):
			continue
		var has_input = prop.settings.get("has_input_port", false)
		var has_output = prop.settings.get("has_output_port", false)
		if not has_input and not has_output:
			continue
		
		# Main property goes first
		if prop.settings.get("is_main_property"):
			visible_props.push_front(prop)
		else:
			visible_props.append(prop)
	
	if port_index >= 0 and port_index < visible_props.size():
		return visible_props[port_index].name
	
	return ""
