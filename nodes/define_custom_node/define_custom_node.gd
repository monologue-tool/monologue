class_name DefineCustomNode extends MonologueGraphNode


var custom_node_name: Property = Property.new(LINE, {}, "MyCustomNode")


func _ready():
	node_type = "NodeDefineCustom"
	
	custom_node_name.connect("preview", _update)
	
	super._ready()
	_update()


func _update(_value: Variant = null) -> void:
	title = "Define %s" % custom_node_name.value


func get_end_of_chain_slot_count() -> int:
	var end_of_chain_nodes: Array = get_graph_edit().get_end_of_chain_nodes(self)
	var end_of_chain_slot_count: int = 0
	
	for node: MonologueGraphNode in end_of_chain_nodes:
		var port_count: int = node.get_output_port_count()
		var all_connections: Array = []
		for port_idx in range(port_count):
			all_connections.append_array(get_graph_edit().get_all_connections_from_slot(node.name, port_idx))
		
		end_of_chain_slot_count += port_count - all_connections.size()
	
	return end_of_chain_slot_count


func _from_dict(dict: Dictionary):
	super._from_dict(dict)
