class_name ConnectionManager extends RefCounted

## Manages connections between node properties for easy access and validation

var _storyline: StorylineDocument
var _suspended_connections: Dictionary = {}


func _init(storyline: StorylineDocument) -> void:
	_storyline = storyline


## Splits a composite property name like "choices:item_id" into [base_name, item_id].
## Returns [property_name, ""] for simple names.
static func parse_composite_name(property_name: String) -> Array:
	if ":" in property_name:
		var parts := property_name.split(":", true, 1)
		return [parts[0], parts[1]]
	return [property_name, ""]


## Updates property connection tracking when a connection is made (using property names)
## All parameters are node_ids, not scene node names.
## Supports composite property names like "choices:item_id" for sub-ports.
func register_connection_by_property(
	from_node_id: String, from_property_name: String, to_node_id: String, to_property_name: String
) -> void:
	var from_node: InspectableNode = _get_node_view_by_id(from_node_id)
	var to_node: InspectableNode = _get_node_view_by_id(to_node_id)

	if not from_node or not to_node:
		push_warning("Cannot register connection: node not found")
		return

	# Resolve composite sub-port names
	var from_parsed := parse_composite_name(from_property_name)
	var from_base_name: String = from_parsed[0]
	var from_item_id: String = from_parsed[1]

	var to_parsed := parse_composite_name(to_property_name)
	var to_base_name: String = to_parsed[0]
	var to_item_id: String = to_parsed[1]

	var from_prop: Property = from_node.get_property(from_base_name)
	var to_prop: Property = to_node.get_property(to_base_name)

	if not from_prop or not to_prop:
		push_warning("Cannot register connection: property not found")
		return

	# Build connection dict, including item_id if it's a sub-port
	var to_conn := {"node_id": to_node_id, "property_name": to_property_name}
	if not from_item_id.is_empty():
		to_conn["item_id"] = from_item_id
	var from_conn := {"node_id": from_node_id, "property_name": from_property_name}
	if not to_item_id.is_empty():
		from_conn["item_id"] = to_item_id

	if to_conn not in from_prop.connected_to:
		from_prop.connected_to.append(to_conn)
		from_prop.connection_changed.emit()
	if from_conn not in to_prop.connected_from:
		to_prop.connected_from.append(from_conn)
		to_prop.connection_changed.emit()


## Updates property connection tracking when a connection is made (using port indices - legacy)
## Parameters are node_ids for compatibility with GraphEdit using ids for names.
func register_connection(
	from_node_id: String, from_port: int, to_node_id: String, to_port: int
) -> void:
	var from_node = _get_node_view_by_id(from_node_id)
	var to_node = _get_node_view_by_id(to_node_id)

	if not from_node or not to_node:
		push_warning("Cannot register connection: node not found")
		return

	var from_prop = _get_property_at_port(from_node, from_port)
	var to_prop = _get_property_at_port(to_node, to_port)

	if not from_prop or not to_prop:
		push_warning("Cannot register connection: property not found")
		return

	# Track the connection using property names
	register_connection_by_property(from_node_id, from_prop.name, to_node_id, to_prop.name)


## Updates property connection tracking when a connection is removed (using property names)
## All parameters are node_ids, not scene node names.
## Supports composite property names like "choices:item_id" for sub-ports.
func unregister_connection_by_property(
	from_node_id: String, from_property_name: String, to_node_id: String, to_property_name: String
) -> void:
	var from_node = _get_node_view_by_id(from_node_id)
	var to_node = _get_node_view_by_id(to_node_id)

	if not from_node or not to_node:
		return

	# Resolve composite sub-port names
	var from_base_name: String = parse_composite_name(from_property_name)[0]
	var to_base_name: String = parse_composite_name(to_property_name)[0]

	var from_prop = from_node.get_property(from_base_name)
	var to_prop = to_node.get_property(to_base_name)

	if not from_prop or not to_prop:
		return

	# Remove the connection from both properties, matching full property_name (with sub-port)
	var old_to_size: int = from_prop.connected_to.size()
	from_prop.connected_to.assign(from_prop.connected_to.filter(
		func(c): return not (c["node_id"] == to_node_id and c["property_name"] == to_property_name)
	))
	if from_prop.connected_to.size() != old_to_size:
		from_prop.connection_changed.emit()

	var old_from_size: int = to_prop.connected_from.size()
	to_prop.connected_from.assign(to_prop.connected_from.filter(
		func(c):
			return not (c["node_id"] == from_node_id and c["property_name"] == from_property_name)
	))
	if to_prop.connected_from.size() != old_from_size:
		to_prop.connection_changed.emit()


## Updates property connection tracking when a connection is removed (using port indices - legacy)
## Parameters are node_ids for compatibility.
func unregister_connection(
	from_node_id: String, from_port: int, to_node_id: String, to_port: int
) -> void:
	var from_node = _get_node_view_by_id(from_node_id)
	var to_node = _get_node_view_by_id(to_node_id)

	if not from_node or not to_node:
		return

	var from_prop = _get_property_at_port(from_node, from_port)
	var to_prop = _get_property_at_port(to_node, to_port)

	if not from_prop or not to_prop:
		return

	# Remove the connection using property names
	unregister_connection_by_property(from_node_id, from_prop.name, to_node_id, to_prop.name)


## Gets all connections tracked by properties
## Returns array of {from_node_id, from_property, to_node_id, to_property}
func get_all_connections() -> Array[Dictionary]:
	var connections: Array[Dictionary] = []
	var processed_connections = {}  # To avoid duplicates

	for node: InspectableNode in _storyline.nodes:
		var node_id: String = node.get_property("id").get_value()
		for prop: Property in node.get_properties():
			# Only process outgoing connections to avoid duplicates
			for conn in prop.connected_to:
				# Reconstruct composite from_property for sub-port connections
				var from_property: String = prop.name
				var item_id: String = conn.get("item_id", "")
				if not item_id.is_empty():
					from_property = "%s:%s" % [prop.name, item_id]
				var key = (
					"%s.%s->%s.%s" % [node_id, from_property, conn["node_id"], conn["property_name"]]
				)
				if key not in processed_connections:
					connections.append(
						{
							"from_node_id": node_id,
							"from_property": from_property,
							"to_node_id": conn["node_id"],
							"to_property": conn["property_name"]
						}
					)
					processed_connections[key] = true

	return connections


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
		return _get_node_view_by_id(connection["node_id"])

	return null


## Validates all connections are still valid (nodes and properties exist)
func validate_connections() -> bool:
	var all_valid = true
	for node: InspectableNode in _storyline.nodes:
		for prop: Property in node.get_properties():
			# Check outgoing connections
			for conn in prop.connected_to:
				var target_node = _get_node_view_by_id(conn["node_id"])
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
				var source_node = _get_node_view_by_id(conn["node_id"])
				if not source_node or not source_node.get_property(conn["property_name"]):
					push_warning(
						(
							"Invalid connection found to %s.%s"
							% [node.get_property_value("id"), prop.name]
						)
					)
					all_valid = false

	return all_valid


## Rename a node id across all connection references and suspended snapshots
func rename_node_id(old_id: String, new_id: String) -> void:
	if old_id == new_id or old_id.is_empty() or new_id.is_empty():
		return

	# Update connections on all properties
	for node: InspectableNode in _storyline.nodes:
		for prop: Property in node.get_properties():
			for i in range(prop.connected_to.size()):
				var conn: Dictionary = prop.connected_to[i]
				if conn.get("node_id", "") == old_id:
					conn["node_id"] = new_id
					prop.connected_to[i] = conn
			for i in range(prop.connected_from.size()):
				var conn_in: Dictionary = prop.connected_from[i]
				if conn_in.get("node_id", "") == old_id:
					conn_in["node_id"] = new_id
					prop.connected_from[i] = conn_in

	# Update suspended connection snapshots
	var keys := _suspended_connections.keys()
	for k: String in keys:
		var parts: Array = k.split("::")
		if parts.size() != 2:
			continue
		if parts[0] != old_id:
			continue
		var new_key := "%s::%s" % [new_id, parts[1]]
		var snapshot: Dictionary = _suspended_connections[k]
		# Update inner arrays
		for dir in ["incoming", "outgoing"]:
			if snapshot.has(dir):
				var arr: Array = snapshot[dir]
				for i in range(arr.size()):
					var c: Dictionary = arr[i]
					if c.get("node_id", "") == old_id:
						c["node_id"] = new_id
						arr[i] = c
				snapshot[dir] = arr
		_suspended_connections.erase(k)
		_suspended_connections[new_key] = snapshot


func suspend_incoming_property_connections(node_id: String, property_name: String) -> void:
	_suspend_property_connections(node_id, property_name, "incoming", "connected_from", true)


func suspend_outgoing_property_connections(node_id: String, property_name: String) -> void:
	_suspend_property_connections(node_id, property_name, "outgoing", "connected_to", false)


func restore_incoming_property_connections(node_id: String, property_name: String) -> void:
	_restore_property_connections(node_id, property_name, "incoming", true)


func restore_outgoing_property_connections(node_id: String, property_name: String) -> void:
	_restore_property_connections(node_id, property_name, "outgoing", false)


func _suspend_property_connections(
	node_id: String,
	property_name: String,
	direction: String,
	connection_array_name: String,
	is_incoming: bool
) -> void:
	var key: String = _connection_key(node_id, property_name)
	if not _suspended_connections.has(key):
		_suspended_connections[key] = {}

	var node := _get_node_view_by_id(node_id)
	if not node:
		return

	var prop := node.get_property(property_name)
	if not prop:
		return

	var connections: Array = prop.get(connection_array_name).duplicate(true)
	if connections.is_empty():
		return

	_suspended_connections[key][direction] = connections

	# Unregister each connection
	for conn_dict in connections:
		var other_node: String = conn_dict.get("node_id", "")
		var other_property: String = conn_dict.get("property_name", "")
		if other_node.is_empty() or other_property.is_empty():
			continue

		if is_incoming:
			unregister_connection_by_property(other_node, other_property, node_id, property_name)
		else:
			unregister_connection_by_property(node_id, property_name, other_node, other_property)


func _restore_property_connections(
	node_id: String, property_name: String, direction: String, is_incoming: bool
) -> void:
	var key: String = _connection_key(node_id, property_name)
	if not _suspended_connections.has(key):
		return

	var snapshot: Dictionary = _suspended_connections[key]
	_suspended_connections.erase(key)

	# Re-register each connection
	var connections: Array = snapshot.get(direction, [])
	for conn_dict in connections:
		var other_node: String = conn_dict.get("node_id", "")
		var other_property: String = conn_dict.get("property_name", "")
		if other_node.is_empty() or other_property.is_empty():
			continue

		if is_incoming:
			register_connection_by_property(other_node, other_property, node_id, property_name)
		else:
			register_connection_by_property(node_id, property_name, other_node, other_property)


func _connection_key(node_id: String, property_name: String) -> String:
	return "%s::%s" % [node_id, property_name]


func _get_node_view_by_id(node_id: String) -> InspectableNode:
	for node: InspectableNode in _storyline.nodes:
		if node.get_property("id").get_value() == node_id:
			return node
	return null


## Helper: Get property at a specific port index in the graph view
func _get_property_at_port(node: InspectableNode, port: int) -> Property:
	var properties = node.get_properties()
	var visible_props: Array[Property] = []

	# Build list of visible properties in graph (matching graph display logic)
	for prop: Property in properties:
		if not prop.get_settings_value("visible_in_graph", true):
			continue
		var has_input = prop.get_settings_value("exposed", false)
		var has_output = prop.get_settings_value("export", false)
		if not has_input and not has_output:
			continue

		# Main property goes first
		if prop.get_settings_value("is_main_property"):
			visible_props.push_front(prop)
		else:
			visible_props.append(prop)

	if port >= 0 and port < visible_props.size():
		return visible_props[port]

	return null
