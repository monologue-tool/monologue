class_name CharacterEdit extends CharacterEditSection


var nicknames := Property.new(MonologueGraphNode.LINE)
var display_name := Property.new(MonologueGraphNode.LINE)
var description := Property.new(MonologueGraphNode.TEXT)


func _ready() -> void:
	close()
	GlobalSignal.add_listener("open_character_edit", open)
	GlobalSignal.add_listener("close_character_edit", close)
	GlobalSignal.add_listener("reload_character_edit", reload)
	super._ready()


func open(graph: MonologueGraphEdit, index: int) -> void:
	if index >= 0:
		graph_edit = graph
		character_index = index
		_from_dict(graph.speakers[index])
		show()
	else:
		close()


func close() -> void:
	# also triggered when 'Done' button is pressed
	if graph_edit:
		graph_edit.speakers[character_index]["Character"].merge(_to_dict(), true)
	hide()
	graph_edit = null
	character_index = -1


func reload(index: int) -> void:
	# triggered if character edit is opened but character index is different
	if character_index != index:
		open(graph_edit, index)


func _from_dict(dict: Dictionary = {}) -> void:
	var character_dict: Dictionary = dict.get("Character", {})
	super._from_dict(character_dict)
	_from_recursive(character_dict, linked_sections)


func _from_recursive(dict: Dictionary, subsections: Array[CharacterEditSection]) -> void:
	for subsection in subsections:
		subsection._from_dict(dict)
		_from_recursive(dict, subsection.linked_sections)


func _to_dict() -> Dictionary:
	var flat_map = super._to_dict()
	for section in linked_sections:
		flat_map.merge(section._to_dict(), true)
	return flat_map
