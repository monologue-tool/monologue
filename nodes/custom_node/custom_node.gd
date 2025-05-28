class_name CustomNode extends MonologueGraphNode


var define_node_id: String = ""


func _ready():
	node_type = "NodeCustom"
	
	get_graph_edit().connection_made.connect(_update)
	get_graph_edit().connection_broken.connect(_update)
	
	super._ready()
	_update()


func _get_define_node() -> MonologueGraphNode:
	return get_graph_edit().get_node_by_id(define_node_id)


func _update(_old_value: Variant = null, _new_value: Variant = null) -> void:
	await get_tree().process_frame # Ensure all nodes are loaded
	var define_node: MonologueGraphNode = _get_define_node()
	if define_node:
		if not define_node.custom_node_name.is_connected("preview", _update_title):
			define_node.custom_node_name.connect("preview", _update_title)
		_update_title()
	
		var slot_count: int = max(1, define_node.get_end_of_chain_slot_count())
		var diff_slot_count: int = get_child_count() - slot_count
		
		if sign(diff_slot_count) >= 0:
			var child_idx: int = get_child_count() - 1
			for child in get_children().slice(get_child_count() - abs(diff_slot_count), get_child_count()):
				var connections: Array = get_graph_edit().get_all_connections_from_slot(name, child_idx)
				for connected in connections:
					get_graph_edit().disconnect_node(name, child_idx, connected.name, 0)
				
				child.queue_free()
		else:
			for i in range(abs(diff_slot_count)):
				var new_child: HBoxContainer = HBoxContainer.new()
				new_child.custom_minimum_size.y = 32.0
				add_child(new_child)
				set_slot(get_child_count()-1, false, 0, Color.WHITE, true, 0, Color.WHITE)
	_update_slot_icons()
	await get_tree().process_frame
	size.x = 0
	super._update()
	


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
	dict["Outputs"] = []
	
	for port in range(get_output_port_count()):
		var next_node: MonologueGraphNode = get_graph_edit().get_all_connections_from_slot(name, port)[0]
		dict["Outputs"].append(next_node.id.value)


func _load_connections(data: Dictionary, _key: String = "NextID") -> void:
	var outputs: Array = data.get("Outputs", [])
	
	for i in range(outputs.size()-1):
		var new_child: HBoxContainer = HBoxContainer.new()
		new_child.custom_minimum_size.y = 32.0
		add_child(new_child)
		set_slot(i+1, false, 0, Color.WHITE, true, 0, Color.WHITE)
	
	var port_idx: int = 0
	for output_id in outputs:
		if output_id is String:
			var next_node = get_parent().get_node_by_id(output_id)
			if next_node:
				get_parent().connect_node(name, port_idx, next_node.name, 0)
		port_idx += 1


func _to_next(_dict: Dictionary, _key: String = "NextID") -> void:
	pass
