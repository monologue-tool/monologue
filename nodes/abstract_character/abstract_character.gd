## Character data builder.
class_name MonologueCharacter extends RefCounted


const CHARACTER_FIELD := preload("res://common/ui/fields/character_field/monologue_character_field.tscn")

var character := Property.new(CHARACTER_FIELD, {}, {})
var id := Property.new(MonologueGraphNode.LINE, {}, IDGen.generate())
var idx := Property.new(MonologueGraphNode.SPINBOX, {}, 0)
var protected := Property.new(MonologueGraphNode.TOGGLE, {}, false)

var custom_delete_button :
	get: return character.field.delete_button

var graph: MonologueGraphEdit
var root: RootNode


func _init(node: RootNode):
	root = node
	graph = node.get_parent()
	character.connect("change", update_character)
	character.connect("display", graph.set_selected.bind(root))
	character.connect("shown", _on_character_field_shown)
	character.setters["graph_edit"] = graph


func _on_character_field_shown() -> void:
	character.field.delete_button.visible = !protected.value
	character.field.name_edit.editable = !protected.value


func update_character(old_value: Variant, new_value: Variant):
	var old_list = root.characters.value.duplicate(true)
	var new_list = root.characters.value.duplicate(true)
	new_list[idx.value]["Character"] = new_value
	
	graph.undo_redo.create_action("Character %s => %s" % [str(old_value), str(new_value)])
	graph.undo_redo.add_do_property(root.characters, "value", new_list)
	graph.undo_redo.add_do_method(root.characters.propagate.bind(new_list))
	graph.undo_redo.add_do_method(graph.set_selected.bind(root))
	graph.undo_redo.add_do_method(GlobalSignal.emit.bind("close_character_edit"))
	graph.undo_redo.add_undo_property(root.characters, "value", old_list)
	graph.undo_redo.add_undo_method(root.characters.propagate.bind(old_list))
	graph.undo_redo.add_undo_method(graph.set_selected.bind(root))
	graph.undo_redo.add_undo_method(GlobalSignal.emit.bind("close_character_edit"))
	graph.undo_redo.commit_action()


func get_property_names() -> PackedStringArray:
	return ["character"]


func _from_dict(dict: Dictionary) -> void:
	if dict.get("ID") is String:
		id.value = dict.get("ID")
		character.value = dict.get("Character")
		protected.value = dict.get("Protected")
		idx.value = dict.get("EditorIndex")
		character.setters["character_index"] = idx.value


func _to_dict():
	return { "ID": id.value, "Protected": protected.value, "Character": character.value, "EditorIndex": idx.value }
