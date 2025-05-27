class_name DefineCustomNode extends MonologueGraphNode


var custom_node_name: Property = Property.new(LINE, {}, "MyCustomNode")


func _ready():
	node_type = "NodeDefineCustom"
	
	custom_node_name.connect("preview", _update)
	
	super._ready()
	_update()


func _update(_value: Variant = null) -> void:
	title = "Define %s" % custom_node_name.value


func _from_dict(dict: Dictionary):
	super._from_dict(dict)
