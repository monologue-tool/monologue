class_name PortraitHistory extends CharacterHistory

## Portrait index.
var portrait_index: int = -1


func _init(
	_character_index: int,
	_portrait_index: int,
	graph: MonologueGraphEdit,
	path: NodePath,
	change_list: Array[PropertyChange]
) -> void:
	super(_character_index, graph, path, change_list)
	portrait_index = _portrait_index


func change_properties() -> void:
	super.change_properties()
	_display_portrait()


func revert_properties() -> void:
	super.revert_properties()
	_display_portrait()


func set_property(node: Variant, property: String, value: Variant) -> void:
	super.set_property(node, property, value)
	var character_dict = graph_edit.characters.value[character_index]["Character"]
	var key = Util.to_key_name(property)
	character_dict["Portraits"][portrait_index]["Portrait"][key] = value


func _display_portrait() -> void:
	GlobalSignal.emit("select_portrait_option", [portrait_index])


func _update_character(_property: String, _value: Variant) -> void:
	pass  # intentionally overriden to do nothing, do not remove!
