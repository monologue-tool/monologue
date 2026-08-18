## Queries and edits a storyline's wires on behalf of the graph view.
##
## Holds nothing of its own. [member StorylineDocument.connections] is the source of truth.
## The one exception is [member _suspended_connections], which parks wires while a port is
## gone so they can be put back when it returns.
class_name ConnectionManager extends RefCounted

var _storyline: StorylineDocument
var _suspended_connections: Dictionary = {}


func _init(storyline: StorylineDocument) -> void:
	_storyline = storyline


func register_connection_by_property(
	from_node_id: String, from_property_name: String, to_node_id: String, to_property_name: String
) -> void:
	var connection: NodeConnection = NodeConnection.from_names(
		from_node_id, from_property_name, to_node_id, to_property_name
	)
	if not _endpoints_exist(connection):
		push_warning("Cannot register connection: %s" % connection)
		return

	_storyline.add_connection(connection)


func unregister_connection_by_property(
	from_node_id: String, from_property_name: String, to_node_id: String, to_property_name: String
) -> void:
	_storyline.remove_connection(
		NodeConnection.from_names(
			from_node_id, from_property_name, to_node_id, to_property_name
		)
	)


## Every wire, as {from_node_id, from_property, to_node_id, to_property}. Names are
## composite where a wire touches one list item.
func get_all_connections() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for connection: NodeConnection in _storyline.connections:
		result.append(
			{
				"from_node_id": connection.from_node_id,
				"from_property": connection.get_from_name(),
				"to_node_id": connection.to_node_id,
				"to_property": connection.get_to_name(),
			}
		)
	return result


func get_connected_properties() -> Array[Property]:
	var connected: Array[Property] = []
	for node: InspectableNode in _storyline.nodes:
		for prop: Property in node.get_properties():
			if prop.is_port_connected():
				connected.append(prop)
	return connected


## The node at the other end of a property's first wire, whichever way it points.
func get_connected_node(node: InspectableNode, property_name: String) -> InspectableNode:
	var node_id: String = node.get_id()

	var outgoing: Array[NodeConnection] = _storyline.get_outgoing(node_id, property_name)
	if not outgoing.is_empty():
		return _storyline.get_node(outgoing[0].to_node_id)

	var incoming: Array[NodeConnection] = _storyline.get_incoming(node_id, property_name)
	if not incoming.is_empty():
		return _storyline.get_node(incoming[0].from_node_id)

	return null


# --- suspend and restore ---------------------------------------------------------


func suspend_incoming_property_connections(node_id: String, property_name: String) -> void:
	_suspend(node_id, property_name, true)


func suspend_outgoing_property_connections(node_id: String, property_name: String) -> void:
	_suspend(node_id, property_name, false)


func restore_incoming_property_connections(node_id: String, property_name: String) -> void:
	_restore(node_id, property_name, true)


func restore_outgoing_property_connections(node_id: String, property_name: String) -> void:
	_restore(node_id, property_name, false)


## Parks a property's wires, so a port about to disappear does not take them with it.
func _suspend(node_id: String, property_name: String, is_incoming: bool) -> void:
	var parked: Array[NodeConnection] = (
		_storyline.get_incoming(node_id, property_name)
		if is_incoming
		else _storyline.get_outgoing(node_id, property_name)
	)
	if parked.is_empty():
		return

	for connection: NodeConnection in parked:
		_storyline.remove_connection(connection)

	_suspended_connections[_connection_key(node_id, property_name, is_incoming)] = parked


func _restore(node_id: String, property_name: String, is_incoming: bool) -> void:
	var key: String = _connection_key(node_id, property_name, is_incoming)
	if not _suspended_connections.has(key):
		return

	var parked: Array = _suspended_connections[key]
	_suspended_connections.erase(key)
	for connection: NodeConnection in parked:
		_storyline.add_connection(connection)


static func _connection_key(node_id: String, property_name: String, is_incoming: bool) -> String:
	return "%s::%s::%s" % [node_id, property_name, "in" if is_incoming else "out"]


func _endpoints_exist(connection: NodeConnection) -> bool:
	var from_node: InspectableNode = _storyline.get_node(connection.from_node_id)
	var to_node: InspectableNode = _storyline.get_node(connection.to_node_id)
	if not from_node or not to_node:
		return false
	return (
		from_node.get_property(connection.from_property) != null
		and to_node.get_property(connection.to_property) != null
	)
