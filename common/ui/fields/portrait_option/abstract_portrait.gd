class_name AbstractPortraitOption extends RefCounted


const PORTRAIT_FIELD := preload("res://common/ui/fields/portrait_option/portrait_option.tscn")

var portrait := Property.new(PORTRAIT_FIELD, {}, {})
var id := Property.new(MonologueGraphNode.LINE, {}, IDGen.generate())
var idx := Property.new(MonologueGraphNode.SPINBOX, {}, 0)

#var custom_delete_button :
	#get: return portrait.field.delete_button

var graph: MonologueGraphEdit
var root: PortraitListSection


func _init(node: PortraitListSection):
	root = node
	portrait.connect("change", update_portrait)
	portrait.setters["graph_edit"] = graph


func update_portrait(old_value: Variant, new_value: Variant):
	var old_list = root.portraits.value.duplicate(true)
	var new_list = root.portraits.value.duplicate(true)
	new_list[idx.value] = new_value
	
	graph.undo_redo.create_action("Portrait %s => %s" % [str(old_value), str(new_value)])
	graph.undo_redo.add_do_property(root.portraits, "value", new_list)
	graph.undo_redo.add_do_method(root.portraits.propagate.bind(new_list))
	graph.undo_redo.add_undo_property(root.portraits, "value", old_list)
	graph.undo_redo.add_undo_method(root.portraits.propagate.bind(old_list))
	graph.undo_redo.commit_action()


func get_property_names() -> PackedStringArray:
	return ["portrait"]


func _from_dict(dict: Dictionary) -> void:
	if dict.get("ID") is String:
		id.value = dict.get("ID")
		portrait.value = dict.get("Portrait")
		idx.value = dict.get("EditorIndex")
		portrait.setters["portrait_index"] = idx.value


func _to_dict():
	return { "ID": id.value, "Portrait": portrait.value, "EditorIndex": idx.value }
