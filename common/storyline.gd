class_name StorylineDocument extends InspectableStorylineObject

signal node_added
signal node_removed
signal content_changed
signal undo_redo_changed

var id: String = IDGen.generate()
var name: String = ""
var nodes: Array[InspectableNode] = []
var file_path: String = ""
var is_dirty: bool = false


func _init(sname: String, sfile_path: String = "") -> void:
	name = sname
	file_path = sfile_path

	var command_manager = CommandManager.new()
	command_manager.command_executed.connect(_on_command_executed)
	command_manager.undone.connect(_on_undo)
	command_manager.redone.connect(_on_redo)

	super._init(command_manager)

	_create_default_nodes()


func add_node(node: InspectableNode) -> void:
	_register_node(node)


func remove_node(node: InspectableNode) -> void:
	if not node in nodes:
		push_warning("Can't remove node %s " % node.id)
		return

	nodes.erase(node)
	node_removed.emit()


func create_node(node_type: String) -> InspectableNode:
	var node = NodeBucket.create_node(node_type, history)
	_register_node(node)
	return node


func get_node(node_id: String) -> InspectableNode:
	for node: InspectableNode in nodes:
		if node.get_property_value("id") == node_id:
			return node
	return null


func initialize_properties() -> void:
	var default_narrator: ListItem = CollectionBucket.create_item("characters", history)
	default_narrator.set_property_value("name", "Narrator")
	default_narrator.set_property_value("protected", true)

	define_property(
		"characters",
		[default_narrator._to_dict()],
		"list",
		{ "collection": "characters" },
	)

	define_property(
		"variables",
		[],
		"list",
		{ "collection": "variables" }
	)

	define_property(
		"items",
		[],
		"list",
		{ "collection": "items" }
	)

	define_property(
		"locations",
		[],
		"list",
		{ "collection": "locations" }
	)


func get_type() -> String:
	return "storyline"


func get_settings() -> Dictionary:
	return {}


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	is_dirty = true
	content_changed.emit()


func build_graph_preview() -> Array[Control]:
	return []


func _on_command_executed():
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()


func _on_undo():
	content_changed.emit()
	undo_redo_changed.emit()


func _on_redo():
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()


func _create_default_nodes() -> void:
	var defaults := ["root", "sentence", "text"]
	for node_type: String in defaults:
		var node = NodeBucket.create_node(node_type, history)
		_register_node(node)


func _register_node(node: InspectableNode) -> void:
	if not node:
		return
	if not node in nodes:
		nodes.append(node)
	node.storyline_id = id
	node.add_observer(_on_node_property_changed)
	node_added.emit()


func _on_node_property_changed(_node: InspectableNode, _property: String) -> void:
	# Maybe useless
	is_dirty = true


func _to_dict() -> Dictionary:
	var dict: Dictionary = super._to_dict()
	dict["nodes"] = []
	var root_node_id: String = ""
	for node: InspectableNode in nodes:
		if node is RootNode:
			root_node_id = node.get_property("id").get_value()
		dict["nodes"].append(node._to_dict())

	dict["root_node_id"] = root_node_id

	return dict
