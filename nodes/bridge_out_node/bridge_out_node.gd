@icon("res://ui/assets/icons/link.svg")
class_name BridgeOutNode extends MonologueGraphNode


@onready var number_selector = $HBoxContainer/LinkNumber


func _ready():
	node_type = "NodeBridgeOut"
	super._ready()


func _from_dict(dict):
	number_selector.value = dict.get("NumberSelector")
	super._from_dict(dict)


func _to_fields(dict: Dictionary) -> void:
	super._to_fields(dict)
	dict["NumberSelector"] = number_selector.value
