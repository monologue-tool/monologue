@icon("res://ui/assets/icons/Condition.svg")
class_name ConditionNode extends EventNode


func _ready():
	super._ready()
	node_type = "NodeCondition"
	title = node_type


func _load_connections(data: Dictionary, key: String = "IfNextID") -> void:
	super._load_connections(data, key)
	var else_next_id = data.get("ElseNextID")
	if else_next_id is String:
		var else_next_node = get_graph_edit().get_node_by_id(else_next_id)
		if else_next_node:
			get_graph_edit().connect_node(name, 1, else_next_node.name, 0)


func _to_next(dict: Dictionary, key: String = "IfNextID") -> void:
	var next_id_node = get_graph_edit().get_all_connections_from_slot(name, 0)
	dict[key] = next_id_node[0].id.value if next_id_node else -1
	
	var else_id_node = get_graph_edit().get_all_connections_from_slot(name, 1)
	dict["ElseNextID"] = else_id_node[0].id.value if else_id_node else -1
