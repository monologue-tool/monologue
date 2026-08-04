class_name StorylineDocument extends InspectableDocument

signal node_added
signal node_removed
signal connections_changed

var id: String:
	get = _get_id
var name: String = ""
var nodes: Array[InspectableNode] = []
## Every wire in this storyline, and the only place they are stored. Each property's
## connected_from / connected_to are views onto this list.
var connections: Array[NodeConnection] = []
## Anything [method _from_dict] could not make sense of, collected for the reader to
## report. Cleared on every load; never serialized.
var load_issues: Array[ValidationIssue] = []
var _node_index: Dictionary = {}


func _init(sname: String, command_manager: CommandManager) -> void:
	name = sname
	super._init(command_manager)

	_create_default_nodes()


func add_node(node: InspectableNode) -> void:
	_register_node(node)


## Removes a node and every wire that touched it, and returns those wires so that
## undoing the removal can put them back exactly as they were.
func remove_node(node: InspectableNode) -> Array[NodeConnection]:
	if not node in nodes:
		push_warning("Can't remove node %s " % str(node.get_property_value("id")))
		return []

	var node_id: String = node.get_property_value("id")
	var removed: Array[NodeConnection] = []
	var kept: Array[NodeConnection] = []
	for connection: NodeConnection in connections:
		if connection.involves(node_id):
			removed.append(connection)
		else:
			kept.append(connection)

	connections = kept
	_node_index.erase(node_id)
	nodes.erase(node)
	rebuild_connection_views()
	node_removed.emit()
	return removed


# --- connections ----------------------------------------------------------------


## Adds a wire, ignoring one that is already there. Returns whether anything changed.
func add_connection(connection: NodeConnection) -> bool:
	if connection == null or has_connection(connection):
		return false

	connections.append(connection)
	rebuild_connection_views()
	connections_changed.emit()
	return true


func remove_connection(connection: NodeConnection) -> bool:
	if connection == null:
		return false

	for existing: NodeConnection in connections:
		if existing.equals(connection):
			connections.erase(existing)
			rebuild_connection_views()
			connections_changed.emit()
			return true
	return false


func has_connection(connection: NodeConnection) -> bool:
	for existing: NodeConnection in connections:
		if existing.equals(connection):
			return true
	return false


## Wires arriving at a node, narrowed to one property when [param property_name] is given.
func get_incoming(node_id: String, property_name: String = "") -> Array[NodeConnection]:
	var found: Array[NodeConnection] = []
	for connection: NodeConnection in connections:
		if connection.to_node_id != node_id:
			continue
		if property_name.is_empty() or connection.to_property == property_name:
			found.append(connection)
	return found


## Wires leaving a node, narrowed to one property when [param property_name] is given.
func get_outgoing(node_id: String, property_name: String = "") -> Array[NodeConnection]:
	var found: Array[NodeConnection] = []
	for connection: NodeConnection in connections:
		if connection.from_node_id != node_id:
			continue
		if property_name.is_empty() or connection.from_property == property_name:
			found.append(connection)
	return found


## Where the chain starting at [param start_node_id] runs out: the nodes it reaches
## that lead nowhere further. A call node grows one exit per answer.
##
## Walks forward through the wires, remembering where it has been, so a chain that
## loops back on itself is followed once rather than for ever.
func find_terminations(start_node_id: String) -> Array[InspectableNode]:
	var terminations: Array[InspectableNode] = []
	var visited: Dictionary[String, bool] = {start_node_id: true}
	var pending: Array[String] = [start_node_id]

	while not pending.is_empty():
		var node_id: String = pending.pop_front()
		var outgoing: Array[NodeConnection] = get_outgoing(node_id)

		if outgoing.is_empty():
			var node: InspectableNode = get_node(node_id)
			if node and node_id != start_node_id:
				terminations.append(node)
			continue

		for connection: NodeConnection in outgoing:
			if visited.has(connection.to_node_id):
				continue
			visited[connection.to_node_id] = true
			pending.append(connection.to_node_id)

	return terminations


## Refills every property's connected_from / connected_to from [member connections].
## Run after any change to the list; properties only announce it when their own view
## actually moved.
func rebuild_connection_views() -> void:
	var incoming: Dictionary = {}
	var outgoing: Dictionary = {}

	for connection: NodeConnection in connections:
		var out_key: String = _view_key(connection.from_node_id, connection.from_property)
		var out_entry: Dictionary = {
			"node_id": connection.to_node_id, "property_name": connection.get_to_name()
		}
		if not connection.from_item_id.is_empty():
			out_entry["item_id"] = connection.from_item_id
		(outgoing.get_or_add(out_key, []) as Array).append(out_entry)

		var in_key: String = _view_key(connection.to_node_id, connection.to_property)
		var in_entry: Dictionary = {
			"node_id": connection.from_node_id, "property_name": connection.get_from_name()
		}
		if not connection.to_item_id.is_empty():
			in_entry["item_id"] = connection.to_item_id
		(incoming.get_or_add(in_key, []) as Array).append(in_entry)

	for node: InspectableNode in nodes:
		var node_id: String = node.get_id()
		for property: Property in node.get_properties():
			var key: String = _view_key(node_id, property.name)
			property.set_connection_views(incoming.get(key, []), outgoing.get(key, []))


static func _view_key(node_id: String, property_name: String) -> String:
	return "%s::%s" % [node_id, property_name]


func create_node(node_type: String) -> InspectableNode:
	var node: InspectableNode = MonologueRegistry.get_instance().create_node(node_type, history)
	_register_node(node)
	return node


func get_node(node_id: String) -> InspectableNode:
	return _node_index.get(node_id)


func initialize_properties() -> void:
	pass


## Reports wires whose ends are missing, and a storyline that does not have exactly the
## one entry point it is supposed to, as issues for the problems panel rather than as
## engine warnings nobody reads.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	for connection: NodeConnection in connections:
		_validate_end(result, connection, connection.from_node_id, connection.from_property)
		_validate_end(result, connection, connection.to_node_id, connection.to_property)

	_validate_singletons(result)


## A storyline holds exactly one of each singleton node type. Nothing in the editor can
## add or remove one, so anything else got here through a hand-edited file.
func _validate_singletons(result: ValidationResult) -> void:
	var counts: Dictionary[String, int] = {}
	for node: InspectableNode in nodes:
		if NodeIndexer.is_permanent(node):
			counts[node.get_type()] = counts.get(node.get_type(), 0) + 1

	for indexer: MonologueIndexer in MonologueRegistry.get_instance().list(MonologueObjectType.NODE):
		if not (indexer as NodeIndexer).is_singleton:
			continue
		var found: int = counts.get(indexer.name, 0)
		if found == 1:
			continue
		result.add(
			ValidationIssue.error(
				"This storyline has %d '%s' nodes; it must have exactly one."
				% [found, indexer.name],
				&"singleton_count"
			).in_document(name)
		)


func _validate_end(
	result: ValidationResult, connection: NodeConnection, node_id: String, property_name: String
) -> void:
	var node: InspectableNode = get_node(node_id)
	if not node:
		result.add(
			ValidationIssue.error(
				"Connection %s points at '%s', which is not in this storyline."
				% [connection, node_id],
				&"broken_connection"
			).in_document(name)
		)
		return

	if not node.get_property(property_name):
		result.add(
			ValidationIssue.error(
				"Connection %s uses property '%s', which '%s' does not have."
				% [connection, property_name, node_id],
				&"broken_connection"
			).at(node, property_name)
		)


func get_type() -> String:
	return "storyline"


func get_document_name() -> String:
	return name


func get_settings() -> Dictionary:
	return {}


func build_graph_preview() -> Array[Control]:
	return []


func _get_id() -> String:
	return get_property_value("id")


func _create_default_nodes() -> void:
	var root_node: InspectableNode = MonologueRegistry.get_instance().create_node("root", history)
	var root_mp: Property = root_node.get_main_property()

	var sent_node: InspectableNode = MonologueRegistry.get_instance().create_node(
		"sentence", history
	)
	var sent_mp: Property = sent_node.get_main_property()

	var option_node: InspectableNode = MonologueRegistry.get_instance().create_node(
		"option", history
	)
	var option_mp: Property = option_node.get_main_property()

	var choice_node: InspectableNode = MonologueRegistry.get_instance().create_node(
		"choice", history
	)
	var choice_mp: Property = choice_node.get_main_property()
	var choice_opt: Array[Dictionary] = []
	for _i: int in range(2):
		var choice_item: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
			"options", history
		)
		choice_opt.append(choice_item._to_dict())

	sent_node.get_property("editor_position").set_value([240.0, 0])
	option_node.get_property("editor_position").set_value([240.0, 120.0])
	choice_node.get_property("editor_position").set_value([480.0, 0])
	choice_node.get_property("choices").set_value(choice_opt)
	choice_node.get_property("choices").set_settings_value("exposed", true)

	_register_node(root_node)
	_register_node(sent_node)
	_register_node(option_node)
	_register_node(choice_node)

	add_connection(
		NodeConnection.create(root_node.get_id(), root_mp.name, sent_node.get_id(), sent_mp.name)
	)
	add_connection(
		NodeConnection.create(sent_node.get_id(), sent_mp.name, choice_node.get_id(), choice_mp.name)
	)
	add_connection(
		NodeConnection.create(option_node.get_id(), option_mp.name, choice_node.get_id(), "choices")
	)


func _register_node(node: InspectableNode) -> void:
	if not node:
		return

	if not node in nodes:
		nodes.append(node)

	node.storyline_id = id
	var node_id: String = node.get_property_value("id")
	if not node_id.is_empty():
		_node_index[node_id] = node

	node_added.emit()


func _to_dict() -> Dictionary:
	var dict: Dictionary = super._to_dict()
	dict["nodes"] = []
	var root_node_id: String = ""
	for node: InspectableNode in nodes:
		if node is RootNode:
			root_node_id = node.get_property("id").get_value()
		var nodes_arr: Array = dict["nodes"]
		nodes_arr.append(node._to_dict())

	dict["root_node_id"] = root_node_id

	var connection_list: Array = []
	for connection: NodeConnection in connections:
		connection_list.append(connection._to_dict())
	dict["connections"] = connection_list

	return dict


func _from_dict(dict: Dictionary) -> void:
	if not dict or dict.is_empty():
		return

	nodes.clear()
	connections.clear()
	_node_index.clear()
	load_issues.clear()

	super._from_dict(dict)

	# Reconstruct graph nodes
	var node_list: Array = dict.get("nodes", [])
	for node_data: Dictionary in node_list:
		var node_type: String = node_data.get("$type", "")
		if node_type.is_empty():
			load_issues.append(
				ValidationIssue.error("A node in this storyline has no type.", &"node_without_type")
			)
			continue
		var node: InspectableNode = MonologueRegistry.get_instance().create_node(node_type, history)
		if not node:
			# Most likely a node type from a plugin that is not installed. Say so
			# instead of dropping it silently, which is what used to happen.
			load_issues.append(
				ValidationIssue.error(
					"Unknown node type '%s'; the node was left out." % node_type,
					&"unknown_node_type"
				)
			)
			continue
		node._from_dict(node_data)
		_register_node(node)

	for entry: Variant in dict.get("connections", []):
		if entry is Dictionary:
			connections.append(NodeConnection.from_dict(entry))

	rebuild_connection_views()
