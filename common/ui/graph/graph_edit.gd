class_name MonologueGraphEdit extends CustomGraphEdit
signal node_view_selected(node: InspectableNode)

var storyline_id: String
var connection_manager: ConnectionManager
var current_language_index: int = 0
var _node_map: Dictionary = {}  # Maps GraphNode -> InspectableNode
var _selected_nodes: Dictionary = {}
var _copied_nodes: Array = []
var _pending_positions: Dictionary = {}  # GraphNode -> Vector2 captured during drag
var _is_applying_position: bool = false


func _ready() -> void:
	super._ready()
	connection_request.connect(_on_connection_request)
	connection_to_empty.connect(_on_connection_to_empty)
	copy_nodes_request.connect(_on_copy_nodes_request)
	cut_nodes_request.connect(_on_cut_nodes_request)
	delete_nodes_request.connect(_on_delete_nodes_request)
	disconnection_request.connect(_on_disconnection_request)
	end_node_move.connect(_on_end_node_move)
	node_deselected.connect(_on_node_deselected)
	node_selected.connect(_on_node_selected)
	paste_nodes_request.connect(_on_paste_nodes_request)

	EventBus.refresh_graph.connect(refresh)


func get_storyline() -> StorylineDocument:
	return ProjectManager.current_project.get_storyline(storyline_id)


func refresh() -> void:
	var storyline: StorylineDocument = get_storyline()
	if not storyline:
		return

	# Initialize connection manager if not already done
	if not connection_manager:
		connection_manager = ConnectionManager.new(storyline)

	# Clear node map and connections
	_node_map.clear()
	_pending_positions.clear()
	clear_connections()

	for child: GraphElement in get_all_graph_nodes():
		child.queue_free()

	for node: InspectableNode in storyline.nodes:
		add_graph_node_view(node)

	# Reconnect all tracked connections after rebuilding nodes
	_reconnect_all_slots()


func refresh_node(node: InspectableNode) -> void:
	if not node or not is_instance_valid(node.graph_view):
		return

	clear_connections()
	GraphNodeViewFactory.modulate_stylebox(node.graph_view, node)
	GraphNodeViewFactory.apply_metadata(node.graph_view, node)
	GraphNodeViewFactory.populate(node.graph_view, node)
	_sync_position_from_property(node)
	_reconnect_all_slots()


func add_graph_node_view(node: InspectableNode) -> GraphNode:
	var graph_node: GraphNode = GraphNodeViewFactory.build(node)

	# Store bidirectional mapping
	_node_map[graph_node] = node
	node.graph_view = graph_node

	# Connect signals
	if not graph_node.position_offset_changed.is_connected(
		_on_graph_node_position_changed.bind(graph_node)
	):
		graph_node.position_offset_changed.connect(_on_graph_node_position_changed.bind(graph_node))

	# Add to scene and set initial position
	add_child(graph_node)
	if not node.property_changed.is_connected(_on_inspectable_node_property_changed):
		node.property_changed.connect(_on_inspectable_node_property_changed.bind(node))

	# Apply initial position from property
	_sync_position_from_property(node)
	return graph_node


## Called when InspectableNode property changes (undo/redo, programmatic)
func _on_inspectable_node_property_changed(property_name: String, node: InspectableNode) -> void:
	if property_name == "position":
		if not _is_applying_position:
			_sync_position_from_property(node)
	else:
		refresh_node(node)


## Sync GraphNode position from InspectableNode property
func _sync_position_from_property(node: InspectableNode) -> void:
	if not node or not is_instance_valid(node.graph_view):
		return

	# Don't overwrite a position that hasn't been committed yet (active drag)
	if _pending_positions.has(node.graph_view):
		return

	var position_property: Property = node.get_property("position")
	var raw: Variant = position_property.get_value() if position_property else null
	var desired_position: Vector2
	if raw is Vector2:
		desired_position = raw
	elif raw is Array:
		var raw_arr: Array = raw
		if raw_arr.size() >= 2:
			var x_val: float = raw_arr[0] if raw_arr[0] is float else 0.0
			var y_val: float = raw_arr[1] if raw_arr[1] is float else 0.0
			desired_position = Vector2(x_val, y_val)
	else:
		desired_position = Vector2.ZERO

	if node.graph_view.position_offset == desired_position:
		return

	_is_applying_position = true
	node.graph_view.position_offset = desired_position
	_is_applying_position = false


## Called when GraphNode position changes (user drag)
func _on_graph_node_position_changed(graph_node: GraphNode) -> void:
	if _is_applying_position:
		return

	_pending_positions[graph_node] = graph_node.position_offset


func _on_node_selected(graph_node: Node) -> void:
	_selected_nodes[graph_node] = true
	var node: InspectableNode = _node_map.get(graph_node)
	if node:
		node_view_selected.emit(node)


func _on_node_deselected(graph_node: Node) -> void:
	_selected_nodes[graph_node] = false


func _on_connection_request(
	from_view_name: StringName, from_port: int, to_view_name: StringName, to_port: int
) -> void:
	var from_node: InspectableNode = get_node_from_view_name(from_view_name)
	var to_node: InspectableNode = get_node_from_view_name(to_view_name)
	var from_graph_node: GraphNode = get_node(from_view_name as String)
	var to_graph_node: GraphNode = get_node(to_view_name as String)
	var from_port_type: int = from_graph_node.get_output_port_type(from_port)
	var to_port_type: int = to_graph_node.get_input_port_type(to_port)

	if not FieldBucket.is_compatible(from_port_type, to_port_type):
		return

	# Get property names at the port indices
	var from_property_name: String = get_property_name_at_port(
		String(from_view_name), from_port, true
	)
	var to_property_name: String = get_property_name_at_port(String(to_view_name), to_port, false)

	if from_property_name.is_empty() or to_property_name.is_empty():
		push_warning("Cannot create connection: property not found at port")
		return

	var storyline: StorylineDocument = get_storyline()
	var command: NodeConnectionCommand = NodeConnectionCommand.new(
		self,
		str(from_node.get_property_value("id")),
		str(to_node.get_property_value("id")),
		from_property_name,
		to_property_name
	)
	storyline.history.execute(command)


func _has_connection_at_slot(node_name: StringName, port_index: int, is_output: bool) -> bool:
	var node_key: String = "from_node" if is_output else "to_node"
	var port_key: String = "from_port" if is_output else "to_port"
	var target_name: String = String(node_name)

	for connection: Dictionary in get_connection_list():
		if str(connection.get(node_key, "")) != target_name:
			continue
		if str(connection.get(port_key, -1)).to_int() == port_index:
			return true

	return false


func get_all_graph_nodes() -> Array:
	return get_children().filter(func(child: Node) -> bool: return child is GraphNode)


## Reconnect all slots based on tracked connections in connection_manager
func _reconnect_all_slots() -> void:
	if not connection_manager:
		return

	var storyline: StorylineDocument = get_storyline()
	var all_connections: Array[Dictionary] = connection_manager.get_all_connections()

	for conn: Dictionary in all_connections:
		var from_node_id: String = conn["from_node_id"]
		var from_property: String = conn["from_property"]
		var to_node_id: String = conn["to_node_id"]
		var to_property: String = conn["to_property"]

		var from_node: InspectableNode = storyline.get_node(from_node_id)
		var to_node: InspectableNode = storyline.get_node(to_node_id)

		if not from_node or not to_node:
			continue

		var from_view_name: String = from_node.graph_view.name
		var to_view_name: String = to_node.graph_view.name

		# Get port indices for the properties
		var from_port: int = get_port_index_for_property(from_view_name, from_property, true)
		var to_port: int = get_port_index_for_property(to_view_name, to_property, false)

		# Only connect if both ports are valid
		if from_port >= 0 and to_port >= 0:
			connect_node(from_view_name, from_port, to_view_name, to_port)


## Get visible properties in the same order as displayed in graph
func _get_visible_properties(node: InspectableNode) -> Array[Property]:
	return node.get_visible_properties()


## Get the port index for a specific property by name.
## is_output=true counts only export ports (output), false counts only exposed ports (input).
## Supports composite names like "choices:item_id" for sub-ports.
func get_port_index_for_property(
	node_name: String, property_name: String, is_output: bool = false
) -> int:
	var node: InspectableNode = get_node_from_view_name(node_name)
	if not node:
		return -1

	var rows: Array[GraphNodeRow] = GraphNodeViewFactory._build_rows(node)
	var count: int = 0
	for row: GraphNodeRow in rows:
		var has_port: bool = row._enable_right_port if is_output else row._enable_left_port
		if not has_port:
			continue
		if row.get_connection_name() == property_name:
			return count
		count += 1

	return -1


func get_node_from_view_name(graph_view_name: String) -> InspectableNode:
	var storyline: StorylineDocument = get_storyline()

	for node: InspectableNode in storyline.nodes:
		if node.graph_view.name == graph_view_name:
			return node
	return null


## Get property name at a specific port index.
## Returns composite name (e.g. "choices:item_id") for sub-ports.
func get_property_name_at_port(node_name: String, port_index: int, is_output: bool) -> String:
	var node: InspectableNode = get_node_from_view_name(node_name)
	if not node:
		return ""

	var rows: Array[GraphNodeRow] = GraphNodeViewFactory._build_rows(node)
	var count: int = 0
	for row: GraphNodeRow in rows:
		var has_port: bool = row._enable_right_port if is_output else row._enable_left_port
		if not has_port:
			continue
		if count == port_index:
			return row.get_connection_name()
		count += 1
	return ""


func _on_end_node_move() -> void:
	if _pending_positions.is_empty():
		return

	_is_applying_position = true

	var storyline: StorylineDocument = get_storyline()
	var history: CommandManager = storyline.history if storyline else null
	if not history:
		_is_applying_position = false
		_pending_positions.clear()
		return

	for graph_node: Variant in _pending_positions.keys():
		if not is_instance_valid(graph_node):
			continue

		var node: InspectableNode = _node_map.get(graph_node)
		if not node:
			continue

		var target_position: Array = [
			_pending_positions[graph_node].x, _pending_positions[graph_node].y
		]
		var position_property: Property = node.get_property("position")
		if not position_property:
			continue
		if not position_property.get_value() is Array:
			position_property.set_value([0.0, 0.0])
		var positon_value: Array = position_property.get_value()
		if positon_value == target_position:
			continue

		var command: PropertyChangeCommand = PropertyChangeCommand.new(
			node, "position", positon_value, target_position
		)
		history.execute(command)

	_is_applying_position = false
	_pending_positions.clear()


func _on_disconnection_request(
	from_view_name: StringName, from_port: int, to_view_name: StringName, to_port: int
) -> void:
	if not connection_manager:
		return

	connection_manager.unregister_connection(from_view_name, from_port, to_view_name, to_port)
	var from_node: InspectableNode = get_node_from_view_name(from_view_name)
	var to_node: InspectableNode = get_node_from_view_name(to_view_name)
	var from_graph_node: GraphNode = get_node(from_view_name as String)
	var to_graph_node: GraphNode = get_node(to_view_name as String)
	var from_port_type: int = from_graph_node.get_output_port_type(from_port)
	var to_port_type: int = to_graph_node.get_input_port_type(to_port)

	if from_port_type != to_port_type:
		return

	# Get property names at the port indices
	var from_property_name: String = get_property_name_at_port(
		String(from_view_name), from_port, true
	)
	var to_property_name: String = get_property_name_at_port(String(to_view_name), to_port, false)

	if from_property_name.is_empty() or to_property_name.is_empty():
		push_warning("Cannot create connection: property not found at port")
		return

	var storyline: StorylineDocument = get_storyline()
	var command: NodeConnectionCommand = NodeConnectionCommand.new(
		self,
		str(from_node.get_property_value("id")),
		str(to_node.get_property_value("id")),
		from_property_name,
		to_property_name
	)
	storyline.history.execute(command)


func _on_copy_nodes_request() -> void:
	if _selected_nodes.size() <= 0:
		return
	_copied_nodes.clear()

	for node: Node in get_children():
		if node is GraphNode and _selected_nodes.get(node, false):
			var source_node: InspectableNode = _node_map.get(node)
			if source_node:
				var duplicated: InspectableNode = source_node.duplicate(true)
				_copied_nodes.append(duplicated)


func _on_paste_nodes_request() -> void:
	# TODO: Move nodes based on the cursor position
	var storyline: StorylineDocument = get_storyline()
	var command: AddNodesCommand = AddNodesCommand.new(storyline_id, _copied_nodes)
	storyline.history.execute(command)


func _on_cut_nodes_request() -> void:
	if _selected_nodes.size() <= 0:
		return
	_copied_nodes.clear()

	var nodes_to_delete: Array[InspectableNode] = []

	for node: Node in get_children():
		if node is GraphNode and _selected_nodes.get(node, false):
			var source_node: InspectableNode = _node_map.get(node)
			if source_node:
				var duplicated: InspectableNode = source_node.duplicate(true)
				_copied_nodes.append(duplicated)
				nodes_to_delete.append(source_node)

	var storyline: StorylineDocument = get_storyline()
	var command: DeleteNodesCommand = DeleteNodesCommand.new(storyline_id, nodes_to_delete)
	storyline.history.execute(command)


func _on_delete_nodes_request(graph_nodes: Array[StringName]) -> void:
	var storyline: StorylineDocument = get_storyline()
	var nodes: Array[InspectableNode] = []
	for node_name: StringName in graph_nodes:
		var graph_node: GraphNode = get_node("%s" % node_name)
		var node: InspectableNode = _node_map.get(graph_node)
		nodes.append(node)

	var command: DeleteNodesCommand = DeleteNodesCommand.new(storyline_id, nodes)
	storyline.history.execute(command)

	refresh()
