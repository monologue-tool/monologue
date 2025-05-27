class_name CustomNode extends MonologueGraphNode


var define_node_id: String = ""


func _ready():
	node_type = "NodeCustom"
	
	super._ready()
	_update()


func _get_define_node() -> MonologueGraphNode:
	return get_graph_edit().get_node_by_id(define_node_id)


func _update(_old_value: Variant = null, _new_value: Variant = null) -> void:
	var define_node: MonologueGraphNode = _get_define_node()
	if define_node:
		if not define_node.custom_node_name.is_connected("preview", _update_title):
			define_node.custom_node_name.connect("preview", _update_title)
		_update_title()


func _update_title(_value: Variant = null) -> void:
	var define_node: MonologueGraphNode = _get_define_node()
	if define_node:
		await get_tree().process_frame
		title = define_node.custom_node_name.value


func _from_dict(dict):
	define_node_id = dict.get("DefineNodeID")
	super._from_dict(dict)


func _to_fields(dict: Dictionary) -> void:
	super._to_fields(dict)
	dict["DefineNodeID"] = define_node_id
