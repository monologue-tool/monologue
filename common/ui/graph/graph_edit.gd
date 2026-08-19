class_name MonologueGraphEdit extends CustomGraphEdit

signal node_view_selected(node: InspectableNode)
signal selection_changed(nodes: Array[InspectableObject])

var storyline_id: String
var connection_manager: ConnectionManager
var current_language_index: int = 0
var _node_map: Dictionary = {}  # Maps GraphNode -> InspectableNode
var _selected_nodes: Dictionary = {}
var _copied_nodes: Array = []
var _pending_positions: Dictionary = {}  # GraphNode -> Vector2 captured during drag
var _is_applying_position: bool = false
## Rebuilds asked for while a wire was being dragged, replayed once it lands.
var _refresh_deferred: bool = false
var _nodes_to_refresh: Array[InspectableObject] = []
## Selection as it was when the settle check was armed, and as last announced.
var _selection_snapshot: Array[StringName] = []
var _announced_selection: Array[StringName] = []


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

	# GraphEdit refuses a drag between differing slot types before it ever emits
	# connection_request, so every compatible pair has to be declared up front.
	MonologueRegistry.get_instance().apply_connection_types(self)

	EventBus.refresh_graph.connect(refresh)
	connection_drag_ended.connect(_flush_deferred_refresh)
	popup_request.connect(_on_popup_request)


func get_storyline() -> StorylineDocument:
	return ProjectManager.current_project.get_storyline(storyline_id)


func refresh() -> void:
	if connecting_mode:
		_refresh_deferred = true
		return

	var storyline: StorylineDocument = get_storyline()
	if not storyline:
		return

	if not connection_manager:
		connection_manager = ConnectionManager.new(storyline)

	_node_map.clear()
	_pending_positions.clear()
	clear_connections()

	MonologueRegistry.get_instance().apply_connection_types(self)

	for child: GraphElement in get_all_graph_nodes():
		child.queue_free()

	for node: InspectableNode in storyline.nodes:
		add_graph_node_view(node)

	_reconnect_all_slots()


func refresh_node(node: InspectableNode) -> void:
	if not node or not is_instance_valid(node.graph_view):
		return

	if connecting_mode:
		if node not in _nodes_to_refresh:
			_nodes_to_refresh.append(node)
		return

	clear_connections()
	GraphNodeViewFactory.modulate_stylebox(node.graph_view, node)
	GraphNodeViewFactory.apply_metadata(node.graph_view, node)
	GraphNodeViewFactory.populate(node.graph_view, node)
	_sync_position_from_property(node)
	_reconnect_all_slots()


func add_graph_node_view(node: InspectableNode) -> GraphNode:
	var graph_node: GraphNode = GraphNodeViewFactory.build(node)

	_node_map[graph_node] = node
	node.graph_view = graph_node

	if not graph_node.position_offset_changed.is_connected(
		_on_graph_node_position_changed.bind(graph_node)
	):
		graph_node.position_offset_changed.connect(_on_graph_node_position_changed.bind(graph_node))

	if node is SectionNode and not graph_node.gui_input.is_connected(_on_section_view_input):
		graph_node.gui_input.connect(_on_section_view_input.bind(node))

	add_child(graph_node)
	if not node.property_changed.is_connected(_on_inspectable_node_property_changed):
		node.property_changed.connect(_on_inspectable_node_property_changed.bind(node))

	_sync_position_from_property(node)
	return graph_node


func _on_section_view_input(event: InputEvent, node: InspectableNode) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or not click.double_click or click.button_index != MOUSE_BUTTON_LEFT:
		return

	var project: MonologueProject = ProjectManager.current_project
	var section: StorylineDocument = (
		project.get_storyline(str(node.get_property_value("target"))) if project else null
	)
	if section == null:
		return

	# GraphElement starts dragging in its own _gui_input, which runs after this signal. Taking
	# the event here means opening a section does not also pick it up and carry it.
	accept_event()
	EventBus.request_storyline_inspection.emit.call_deferred(section)


func _on_inspectable_node_property_changed(property_name: String, node: InspectableNode) -> void:
	if property_name == "editor_position":
		if not _is_applying_position:
			_sync_position_from_property(node)
	else:
		refresh_node(node)


func _sync_position_from_property(node: InspectableNode) -> void:
	if not node or not is_instance_valid(node.graph_view):
		return

	# Don't overwrite a position that hasn't been committed yet (active drag)
	if _pending_positions.has(node.graph_view):
		return

	var position_property: Property = node.get_property("editor_position")
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


func _on_graph_node_position_changed(graph_node: GraphNode) -> void:
	if _is_applying_position:
		return

	_pending_positions[graph_node] = graph_node.position_offset


func _on_node_selected(graph_node: Node) -> void:
	_selected_nodes[graph_node] = true
	var node: InspectableNode = _node_map.get(graph_node)
	if node:
		node_view_selected.emit(node)
	_announce_selection()


func _on_node_deselected(graph_node: Node) -> void:
	_selected_nodes[graph_node] = false
	_announce_selection()


## Every node currently selected, in the order they appear in the graph.
##
## Read from GraphNode.selected, not from a dictionary kept in step with the signals.
## Box-selecting updates the nodes directly, and bookkeeping runs a frame or two behind.
func get_selected_nodes() -> Array[InspectableObject]:
	var nodes: Array[InspectableObject] = []
	for graph_node: Node in get_all_graph_nodes():
		if not (graph_node as GraphNode).selected:
			continue
		var node: InspectableNode = _node_map.get(graph_node)
		if node:
			nodes.append(node)
	return nodes


## Waits for the selection to stop changing before announcing it.
##
## Godot selects nodes one at a time as the rubber band sweeps over them, across several
## frames. Announcing on the first reports a rectangle of ten as a selection of one.
## Announcing on every one rebuilds the inspector ten times.
func _announce_selection() -> void:
	_selection_snapshot = _selected_view_names()
	_settle_selection.call_deferred()


func _settle_selection() -> void:
	var current: Array[StringName] = _selected_view_names()

	# Still growing: come back once it holds still.
	if current != _selection_snapshot:
		_announce_selection()
		return

	if current == _announced_selection:
		return

	_announced_selection = current
	selection_changed.emit(get_selected_nodes())


func _selected_view_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for graph_node: Node in get_all_graph_nodes():
		if (graph_node as GraphNode).selected:
			names.append(graph_node.name)
	return names


func _on_connection_request(
	from_view_name: StringName, from_port: int, to_view_name: StringName, to_port: int
) -> void:
	var from_node: InspectableNode = get_node_from_view_name(from_view_name)
	var to_node: InspectableNode = get_node_from_view_name(to_view_name)
	var from_graph_node: GraphNode = get_node(from_view_name as String)
	var to_graph_node: GraphNode = get_node(to_view_name as String)
	var from_port_type: int = from_graph_node.get_output_port_type(from_port)
	var to_port_type: int = to_graph_node.get_input_port_type(to_port)

	if not MonologueRegistry.get_instance().is_compatible(from_port_type, to_port_type):
		return

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


## Replays whatever was asked for while a wire was in flight. Deferred a frame so GraphEdit
## has finished with the drop. connection_request fires around the same time, and rebuilding
## underneath it undoes the drop.
func _flush_deferred_refresh() -> void:
	if not _refresh_deferred and _nodes_to_refresh.is_empty():
		return
	_do_flush_deferred_refresh.call_deferred()


func _do_flush_deferred_refresh() -> void:
	var nodes: Array[InspectableObject] = _nodes_to_refresh.duplicate()
	var needs_full_refresh: bool = _refresh_deferred
	_nodes_to_refresh.clear()
	_refresh_deferred = false

	if needs_full_refresh:
		refresh()
		return

	for node: InspectableObject in nodes:
		refresh_node(node as InspectableNode)


func get_all_graph_nodes() -> Array:
	return get_children().filter(func(child: Node) -> bool: return child is GraphNode)


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

		var from_port: int = get_port_index_for_property(from_view_name, from_property, true)
		var to_port: int = get_port_index_for_property(to_view_name, to_property, false)

		if from_port >= 0 and to_port >= 0:
			connect_node(from_view_name, from_port, to_view_name, to_port)


func _get_visible_properties(node: InspectableNode) -> Array[Property]:
	return node.get_visible_properties()


## is_output counts export ports, otherwise exposed ports. Takes composite names like
## "choices:item_id" for sub-ports.
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


## Composite, as "choices:item_id", for a sub-port.
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
		var position_property: Property = node.get_property("editor_position")
		if not position_property:
			continue
		if not position_property.get_value() is Array:
			position_property.set_value([0.0, 0.0])
		var positon_value: Array = position_property.get_value()
		if positon_value == target_position:
			continue

		var command: PropertyChangeCommand = PropertyChangeCommand.new(
			node, "editor_position", positon_value, target_position
		)
		history.execute(command)

	_is_applying_position = false
	_pending_positions.clear()


func _on_disconnection_request(
	from_view_name: StringName, from_port: int, to_view_name: StringName, to_port: int
) -> void:
	if not connection_manager:
		return

	var from_node: InspectableNode = get_node_from_view_name(from_view_name)
	var to_node: InspectableNode = get_node_from_view_name(to_view_name)

	# No port-type check here on purpose. Connecting only requires the two types to be
	# *compatible*, so requiring them to be equal here would leave links that cannot be
	# undone.
	var from_property_name: String = get_property_name_at_port(
		String(from_view_name), from_port, true
	)
	var to_property_name: String = get_property_name_at_port(String(to_view_name), to_port, false)

	if from_property_name.is_empty() or to_property_name.is_empty():
		push_warning("Cannot remove connection: property not found at port")
		return

	# The last argument is what makes this a disconnection. Without it the command connects
	# instead, and pulling a wire off an input port reattaches it. The command unregisters
	# from the model itself, so there is deliberately no unregister_connection() call.
	var storyline: StorylineDocument = get_storyline()
	var command: NodeConnectionCommand = NodeConnectionCommand.new(
		self,
		str(from_node.get_property_value("id")),
		str(to_node.get_property_value("id")),
		from_property_name,
		to_property_name,
		true
	)
	storyline.history.execute(command)


## Built each time and freed with the popup, since what it offers depends on the selection.
func _on_popup_request(at_position: Vector2) -> void:
	var selection: Array[InspectableNode] = _user_owned(_selected_model_nodes())
	if selection.is_empty():
		return

	var menu: PopupMenu = PopupMenu.new()
	menu.add_item("Extract into a Section")
	menu.id_pressed.connect(func(_id: int) -> void: _extract_into_section(selection))
	menu.popup_hide.connect(menu.queue_free)
	add_child(menu)

	menu.position = Vector2i(get_screen_position() + at_position)
	menu.popup()


func _extract_into_section(selection: Array[InspectableNode]) -> void:
	var storyline: StorylineDocument = get_storyline()
	if storyline == null:
		return

	var refused: String = ExtractSectionCommand.refuse_reason(storyline, selection)
	if not refused.is_empty():
		Log.warn(refused)
		return

	storyline.history.execute(ExtractSectionCommand.new(storyline_id, selection))
	refresh()


## The nodes of a selection the user actually owns. A storyline creates its own root and
## keeps it. Copying it would make a second one, deleting it would leave no way in.
func _user_owned(nodes: Array[InspectableNode]) -> Array[InspectableNode]:
	var owned: Array[InspectableNode] = []
	for node: InspectableNode in nodes:
		if node and not NodeIndexer.is_permanent(node):
			owned.append(node)
	return owned


## Every node currently selected, whatever the graph's own bookkeeping says.
func _selected_model_nodes() -> Array[InspectableNode]:
	var nodes: Array[InspectableNode] = []
	for graph_node: Node in get_children():
		if graph_node is GraphNode and _selected_nodes.get(graph_node, false):
			var node: InspectableNode = _node_map.get(graph_node)
			if node:
				nodes.append(node)
	return nodes


func _on_copy_nodes_request() -> void:
	_copied_nodes.clear()

	for source_node: InspectableNode in _user_owned(_selected_model_nodes()):
		_copied_nodes.append(source_node.duplicate(true))


func _on_paste_nodes_request() -> void:
	# TODO: Move nodes based on the cursor position
	var storyline: StorylineDocument = get_storyline()
	var command: AddNodesCommand = AddNodesCommand.new(storyline_id, _copied_nodes)
	storyline.history.execute(command)


func _on_cut_nodes_request() -> void:
	_copied_nodes.clear()

	var nodes_to_delete: Array[InspectableNode] = _user_owned(_selected_model_nodes())
	if nodes_to_delete.is_empty():
		return

	for source_node: InspectableNode in nodes_to_delete:
		_copied_nodes.append(source_node.duplicate(true))

	var storyline: StorylineDocument = get_storyline()
	storyline.history.execute(DeleteNodesCommand.new(storyline_id, nodes_to_delete))


func _on_delete_nodes_request(graph_nodes: Array[StringName]) -> void:
	var nodes: Array[InspectableNode] = []
	for node_name: StringName in graph_nodes:
		var graph_node: GraphNode = get_node("%s" % node_name)
		var node: InspectableNode = _node_map.get(graph_node)
		if node:
			nodes.append(node)

	var removable: Array[InspectableNode] = _user_owned(nodes)
	if removable.is_empty():
		return

	var storyline: StorylineDocument = get_storyline()
	storyline.history.execute(DeleteNodesCommand.new(storyline_id, removable))

	refresh()
