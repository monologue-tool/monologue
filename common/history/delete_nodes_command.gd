## Removes nodes from a storyline, along with the wires that reached them.
##
## A wire to a node that is gone means nothing, so deleting takes the connections with
## it. Undo puts both back: the command holds on to the node instances, so they return
## with the ids they always had and every reference to them resolves again.
class_name DeleteNodesCommand extends AddNodesCommand

## Connection arrays as they were before the deletion, by node id and property name.
var _connections: Array[Dictionary] = []


func execute() -> void:
	_capture_connections()
	_detach_deleted_nodes()
	super.undo()


func undo() -> void:
	super.execute()
	_restore_connections()
	# super.execute() refreshes the graph before the wires are back, so ask again.
	EventBus.refresh_graph.emit()


func get_description() -> String:
	return "Delete %s nodes" % nodes.size()


func _get_storyline() -> StorylineDocument:
	return ProjectManager.current_project.get_storyline(storyline_id)


## Snapshots every node's connections. Cheap, and it saves having to work out which
## ends of which wires the deletion is about to touch.
func _capture_connections() -> void:
	_connections.clear()
	var storyline: StorylineDocument = _get_storyline()
	if not storyline:
		return

	for node: InspectableNode in storyline.nodes:
		for property: Property in node.get_properties():
			if not property.is_port_connected():
				continue
			_connections.append(
				{
					"node_id": node.get_id(),
					"property_name": property.name,
					"connected_from": property.connected_from.duplicate(true),
					"connected_to": property.connected_to.duplicate(true),
				}
			)


## Drops the deleted nodes' own connections and every entry on the surviving nodes
## that pointed at them.
func _detach_deleted_nodes() -> void:
	var storyline: StorylineDocument = _get_storyline()
	if not storyline:
		return

	var deleted_ids: Dictionary[String, bool] = {}
	for node: InspectableNode in nodes:
		deleted_ids[node.get_id()] = true

	for node: InspectableNode in storyline.nodes:
		var is_deleted: bool = deleted_ids.has(node.get_id())
		for property: Property in node.get_properties():
			if is_deleted:
				property.clear_connections()
			else:
				_drop_entries_pointing_at(property, deleted_ids)


func _restore_connections() -> void:
	var storyline: StorylineDocument = _get_storyline()
	if not storyline:
		return

	for entry: Dictionary in _connections:
		var node: InspectableNode = storyline.get_node(str(entry["node_id"]))
		if not node:
			continue
		var property: Property = node.get_property(str(entry["property_name"]))
		if not property:
			continue
		property.connected_from.assign(entry["connected_from"])
		property.connected_to.assign(entry["connected_to"])
		property.connection_changed.emit()


static func _drop_entries_pointing_at(
	property: Property, deleted_ids: Dictionary[String, bool]
) -> void:
	var keep: Callable = func(entry: Dictionary) -> bool:
		return not deleted_ids.has(str(entry.get("node_id", "")))

	var before: int = property.connected_from.size() + property.connected_to.size()
	property.connected_from.assign(property.connected_from.filter(keep))
	property.connected_to.assign(property.connected_to.filter(keep))
	if property.connected_from.size() + property.connected_to.size() != before:
		property.connection_changed.emit()
