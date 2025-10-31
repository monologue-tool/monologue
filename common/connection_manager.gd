class_name ConnectionManager extends RefCounted

## Manages connections between node properties for easy access and validation

var _storyline: StorylineDocument


func _init(storyline: StorylineDocument) -> void:
	_storyline = storyline


## Updates property connection tracking when a connection is made (using property names)
func register_connection_by_property(
	from_node_name: String, from_property_name: String, to_node_name: String, to_property_name: String
) -> void:
	var from_node = _get_node_by_id(from_node_name)
	var to_node = _get_node_by_id(to_node_name)

	if not from_node or not to_node:
		push_warning("Cannot register connection: node not found")
		return

	var from_prop = from_node.get_property(from_property_name)
	var to_prop = to_node.get_property(to_property_name)

	if not from_prop or not to_prop:
		push_warning("Cannot register connection: property not found")
		return

	# Track the connection in both properties using property names
	from_prop.add_connection_to(to_node_name, to_property_name, -1)
	to_prop.add_connection_from(from_node_name, from_property_name, -1)


## Updates property connection tracking when a connection is made (using port indices - legacy)
func register_connection(
	from_node_name: String, from_port: int, to_node_name: String, to_port: int
) -> void:
	var from_node = _get_node_by_id(from_node_name)
	var to_node = _get_node_by_id(to_node_name)

	if not from_node or not to_node:
		push_warning("Cannot register connection: node not found")
		return

	var from_prop = _get_property_at_port(from_node, from_port)
	var to_prop = _get_property_at_port(to_node, to_port)

	print(from_prop)

	if not from_prop or not to_prop:
		push_warning("Cannot register connection: property not found")
		return

	# Track the connection using property names
	register_connection_by_property(from_node_name, from_prop.name, to_node_name, to_prop.name)


## Updates property connection tracking when a connection is removed (using property names)
func unregister_connection_by_property(
	from_node_name: String, from_property_name: String, to_node_name: String, to_property_name: String
) -> void:
	var from_node = _get_node_by_id(from_node_name)
	var to_node = _get_node_by_id(to_node_name)

	if not from_node or not to_node:
		return

	var from_prop = from_node.get_property(from_property_name)
	var to_prop = to_node.get_property(to_property_name)

	if not from_prop or not to_prop:
		return

	# Remove the connection from both properties using property names
	from_prop.connected_to = from_prop.connected_to.filter(
		func(c): return not (c["node_id"] == to_node_name and c["property_name"] == to_property_name)
	)
	to_prop.connected_from = to_prop.connected_from.filter(
		func(c):
			return not (c["node_id"] == from_node_name and c["property_name"] == from_property_name)
	)


## Updates property connection tracking when a connection is removed (using port indices - legacy)
func unregister_connection(
	from_node_name: String, from_port: int, to_node_name: String, to_port: int
) -> void:
	var from_node = _get_node_by_id(from_node_name)
	var to_node = _get_node_by_id(to_node_name)

	if not from_node or not to_node:
		return

	var from_prop = _get_property_at_port(from_node, from_port)
	var to_prop = _get_property_at_port(to_node, to_port)

	if not from_prop or not to_prop:
		return

	# Remove the connection using property names
	unregister_connection_by_property(from_node_name, from_prop.name, to_node_name, to_prop.name)


## Gets all properties that are connected (have at least one connection)
func get_connected_properties() -> Array[Property]:
	var connected: Array[Property] = []
	for node: InspectableNode in _storyline.nodes:
		for prop: Property in node.get_properties():
			if prop.is_port_connected():
				connected.append(prop)
	return connected


## Gets the node a property is connected to (for single connection)
func get_connected_node(node: InspectableNode, property_name: String) -> InspectableNode:
	var prop = node.get_property(property_name)
	if not prop or not prop.is_port_connected():
		return null

	# Get first connection (assuming single connection for simplicity)
	var connection = null
	if prop.connected_to.size() > 0:
		connection = prop.connected_to[0]
	elif prop.connected_from.size() > 0:
		connection = prop.connected_from[0]

	if connection:
		return _get_node_by_id(connection["node_id"])

	return null


## Validates all connections are still valid (nodes and properties exist)
func validate_connections() -> bool:
	var all_valid = true
	for node: InspectableNode in _storyline.nodes:
		for prop: Property in node.get_properties():
			# Check outgoing connections
			for conn in prop.connected_to:
				var target_node = _get_node_by_id(conn["node_id"])
				if not target_node or not target_node.get_property(conn["property_name"]):
					push_warning(
						(
							"Invalid connection found from %s.%s"
							% [node.get_property_value("id"), prop.name]
						)
					)
					all_valid = false

			# Check incoming connections
			for conn in prop.connected_from:
				var source_node = _get_node_by_id(conn["node_id"])
				if not source_node or not source_node.get_property(conn["property_name"]):
					push_warning(
						(
							"Invalid connection found to %s.%s"
							% [node.get_property_value("id"), prop.name]
						)
					)
					all_valid = false

	return all_valid


## Helper: Get node by ID
func _get_node_by_id(node_id: String) -> InspectableNode:
	for node: InspectableNode in _storyline.nodes:
		if node.get_property_value("id") == node_id:
			return node
	return null


## Helper: Get property at a specific port index in the graph view
func _get_property_at_port(node: InspectableNode, port: int) -> Property:
	var properties = node.get_properties()
	var visible_props: Array[Property] = []

	# Build list of visible properties in graph (matching graph display logic)
	for prop: Property in properties:
		if not prop.settings.get("visible_in_graph", true):
			continue
		var has_input = prop.settings.get("exposed", false)
		var has_output = prop.settings.get("export", false)
		if not has_input and not has_output:
			continue

		# Main property goes first
		if prop.settings.get("is_main_property"):
			visible_props.push_front(prop)
		else:
			visible_props.append(prop)

	if port >= 0 and port < visible_props.size():
		return visible_props[port]

	return null
