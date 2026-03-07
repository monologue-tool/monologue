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
## Active language code in the editor for this storyline (e.g. "en", "fr").
var active_language_code: String = "en"
## Fast lookup: node_id -> InspectableNode
var _node_index: Dictionary = {}


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

	var node_id: String = node.get_property_value("id")
	_node_index.erase(node_id)
	nodes.erase(node)
	node_removed.emit()


func create_node(node_type: String) -> InspectableNode:
	var node = NodeBucket.create_node(node_type, history)
	_register_node(node)
	return node


func get_node(node_id: String) -> InspectableNode:
	return _node_index.get(node_id)


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

	var default_language: ListItem = CollectionBucket.create_item("languages", history)
	default_language.set_property_value("name", "English")
	default_language.set_property_value("code", "en")
	default_language.set_property_value("protected", true)
	define_property(
		"languages",
		[default_language._to_dict()],
		"list",
		{ "collection": "languages" }
	)
	
	var default_beziers: Dictionary = {
		"Ease": [0.25, 0.10, 0.25, 1.0],
		"Linear": [0.0, 0.0, 1.0, 1.0],
		"Ease-In": [0.42, 0.0, 1.0, 1.0],
		"Ease-Out": [0.0, 0.0, 0.58, 1.0],
		"Ease-In-Out": [0.42, 0.0, 0.58, 1.0]
	}
	var beziers_data: Array = []
	for bezier_name: String in default_beziers:
		var bezier_item: ListItem = CollectionBucket.create_item("beziers", history)
		bezier_item.set_property_value("name", bezier_name)
		bezier_item.set_property_value("bezier", default_beziers.get(bezier_name))
		beziers_data.append(bezier_item._to_dict())
	
	define_property(
		"beziers",
		beziers_data,
		"list",
		{ "collection": "beziers" }
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
		dict["nodes"].append(node._to_dict())

	dict["root_node_id"] = root_node_id

	return dict


func _from_dict(dict: Dictionary) -> void:
	if not dict or dict.is_empty():
		return

	nodes.clear()
	_node_index.clear()
	
	super._from_dict(dict)

	# Reconstruct graph nodes
	var node_list: Array = dict.get("nodes", [])
	for node_data: Dictionary in node_list:
		var node_type: String = node_data.get("$type", "")
		if node_type.is_empty():
			continue
		var node: InspectableNode = NodeBucket.create_node(node_type, history)
		if not node:
			push_warning("Could not create node of type '%s' from dict." % node_type)
			continue
		node._from_dict(node_data)
		_register_node(node)
