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
	
	protected.connect("change", func(): character.field.delete_button.visible = protected.value)


func update_character(old_value: Variant, new_value: Variant):
	var old_list = root.characters.value.duplicate(true)
	var new_list = root.characters.value.duplicate(true)
	new_list[idx.value]["Character"] = new_value
	
	graph.undo_redo.create_action("Character %s => %s" % [str(old_value), str(new_value)])
	graph.undo_redo.add_do_property(root.characters, "value", new_list)
	graph.undo_redo.add_do_method(root.characters.propagate.bind(new_list))
	graph.undo_redo.add_undo_property(root.characters, "value", old_list)
	graph.undo_redo.add_undo_method(root.characters.propagate.bind(old_list))
	graph.undo_redo.commit_action()


func get_property_names() -> PackedStringArray:
	return ["character"]


func _from_dict(dict: Dictionary) -> void:
	if dict.get("ID") is String:
		id.value = dict.get("ID")
		character.value = dict.get("Character")


func _to_dict():
	return { "ID": id.value, "Character": character.value, "EditorIndex": idx.value }
