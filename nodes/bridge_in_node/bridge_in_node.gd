## Continues the dialogue from BridgeIn node to its counterpart BridgeOut node.
@icon("res://ui/assets/icons/link.svg")
class_name BridgeInNode extends MonologueGraphNode


var bridge_out_scene = preload("res://nodes/bridge_out_node/bridge_out_node.tscn")

## Spinner control which selects what number to bridge to.
@onready var number_selector: SpinBox = $HBoxContainer/LinkNumber


func _ready():
	node_type = "NodeBridgeIn"
	title = node_type
	super._ready()


func add_to(graph):
	var created = super.add_to(graph)
	var number = graph.get_free_bridge_number()
	number_selector.value = number
	
	var bridge_out = bridge_out_scene.instantiate()
	bridge_out.add_to(graph)
	bridge_out.number_selector.value = number
	created.append(bridge_out)
	
	return created


func _from_dict(dict):
	number_selector.value = dict.get("NumberSelector")
	super._from_dict(dict)


func _load_connections(_data: Dictionary, _key: String = "") -> void:
	return  # BridgeIn uses NextID covertly, not as a graph connection


func _to_fields(dict: Dictionary) -> void:
	super._to_fields(dict)
	dict["NumberSelector"] = number_selector.value


func _to_next(dict: Dictionary, key: String = "NextID") -> void:
	var next_node = get_parent().get_linked_bridge_node(number_selector.value)
	dict[key] = next_node.id.value if next_node else -1
