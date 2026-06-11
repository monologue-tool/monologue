class_name StorylineDocument extends InspectableDocument

signal node_added
signal node_removed

var id: String : get = _get_id
var name: String = ""
var nodes: Array[InspectableNode] = []
var _node_index: Dictionary = {}


func _init(sname: String, command_manager: CommandManager) -> void:
	name = sname
	super._init(command_manager)

	_create_default_nodes()


func add_node(node: InspectableNode) -> void:
	_register_node(node)


func remove_node(node: InspectableNode) -> void:
	if not node in nodes:
		push_warning("Can't remove node %s " % str(node.get_property_value("id")))
		return

	var node_id: String = node.get_property_value("id")
	_node_index.erase(node_id)
	nodes.erase(node)
	node_removed.emit()


func create_node(node_type: String) -> InspectableNode:
	var node: InspectableNode = NodeBucket.create_node(node_type, history)
	_register_node(node)
	return node


func get_node(node_id: String) -> InspectableNode:
	return _node_index.get(node_id)

func initialize_properties() -> void:
	pass


func get_type() -> String:
	return "storyline"


func get_settings() -> Dictionary:
	return {}


func build_graph_preview() -> Array[Control]:
	return []


func _get_id() -> String:
	return get_property_value("id")


func _create_default_nodes() -> void:
	var root_node: InspectableNode = NodeBucket.create_node("root", history)
	var root_mp: Property = root_node.get_main_property()
	
	var sent_node: InspectableNode = NodeBucket.create_node("sentence", history)
	var sent_mp: Property = sent_node.get_main_property()
	
	var option_node: InspectableNode = NodeBucket.create_node("option", history)
	var option_mp: Property = option_node.get_main_property()
	
	var choice_node: InspectableNode = NodeBucket.create_node("choice", history)
	var choice_mp: Property = choice_node.get_main_property()
	var choice_opt: Array[Dictionary] = []
	for _i: int in range(2):
		choice_opt.append(CollectionBucket.create_item("option", history)._to_dict())
	
	sent_node.get_property("position").set_value([240.0, 0])
	option_node.get_property("position").set_value([240.0, 120.0])
	choice_node.get_property("position").set_value([480.0, 0])
	choice_node.get_property("choices").set_value(choice_opt)
	choice_node.get_property("choices").set_settings_value("exposed", true)
	
	_register_node(root_node)
	_register_node(sent_node)
	_register_node(option_node)
	_register_node(choice_node)
	
	root_mp.add_connection_to(sent_node.get_id(), sent_mp.name)
	sent_mp.add_connection_from(root_node.get_id(), root_mp.name)

	sent_mp.add_connection_to(choice_node.get_id(), choice_mp.name)
	choice_mp.add_connection_from(sent_node.get_id(), sent_mp.name)

	option_mp.add_connection_to(choice_node.get_id(), "choices")
	choice_node.get_property("choices").add_connection_from(option_node.get_id(), option_mp.name)


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
