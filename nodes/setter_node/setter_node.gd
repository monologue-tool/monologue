class_name SetterNode extends AbstractVariableNode


var set_type  := Property.new(DROPDOWN, {}, "Option")
var option_id := Property.new(LINE)
var enable    := Property.new(TOGGLE)

var _control_groups = {
	"Option": [option_id, enable],
	"Variable": [variable, operator, value]
}

@onready var _option_container = $OptionContainer
@onready var _option_id_label = $OptionContainer/OptionIdLabel
@onready var _bool_label = $OptionContainer/BoolLabel
@onready var _variable_container = $VariableContainer


func _ready() -> void:
	node_type = "NodeSetter"
	set_type.callers["set_items"] = [[
		{ "id": 0, "text": "Option"     },
		{ "id": 1, "text": "Variable"   },
	]]
	set_type.connect("preview", _show_group)
	set_type.connect("preview", _update)
	option_id.connect("preview", _option_id_label.set_text)
	enable.connect("preview", func(e): _bool_label.text = str(e))
	
	super._ready()
	_show_group(set_type.value)
	_update(set_type.value)


func get_variable_label() -> Label:
	return $VariableContainer/VariableLabel


func get_operator_label() -> Label:
	return $VariableContainer/OperatorLabel


func get_value_label() -> Label:
	return $VariableContainer/ValueLabel


func _from_dict(dict: Dictionary) -> void:
	record_morph(dict.get("Value"))
	super._from_dict(dict)
	_show_group(set_type.value)


func _show_group(setter_type: Variant) -> void:
	for key in _control_groups.keys():
		for property in _control_groups.get(key):
			property.visible = key == setter_type


func _update(setter_type: Variant = set_type.value) -> void:
	_option_container.visible = setter_type == "Option"
	_option_id_label.text = get_default_text(option_id.value, "option id")
	_bool_label.text = get_default_text(enable.value, "false")
	
	_variable_container.visible = setter_type == "Variable"
	super._update()
