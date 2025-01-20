class_name CharacterEditSection extends Control


## Character index that is being edited in the graph_edit.
@export var character_index: int = -1 : set = set_index
## Container which will house all the fields for this section.
@export var field_vbox: Control
## The graph_edit storing the character.
@export var graph_edit: MonologueGraphEdit : set = set_graph_edit
## List of other sections that are linked to this section.
@export var linked_sections: Array[CharacterEditSection]


func _ready() -> void:
	for entry in get_property_list():
		if Constants.PROPERTY_CLASSES.has(entry.class_name):
			get(entry.name).connect("change", change.bind(entry.name))


func change(old_value: Variant, new_value: Variant, property: String) -> void:
	var changes: Array[PropertyChange] = []
	changes.append(PropertyChange.new(property, old_value, new_value))
	
	var undo_redo = graph_edit.undo_redo
	undo_redo.create_action("%s: %s => %s" % [property, old_value, new_value])
	var history = CharacterHistory.new(character_index,
			graph_edit, graph_edit.get_path_to(self), changes)
	undo_redo.add_prepared_history(history)
	undo_redo.commit_action()


## Deletes all field controls in the field_vbox.
func flush() -> void:
	for field in field_vbox.get_children():
		field.queue_free()


func set_graph_edit(graph: MonologueGraphEdit) -> void:
	graph_edit = graph
	for section in linked_sections:
		section.graph_edit = graph


func set_index(index: int) -> void:
	character_index = index
	for section in linked_sections:
		section.character_index = index


func _from_dict(dict: Dictionary) -> void:
	flush()
	for entry in get_property_list():
		if Constants.PROPERTY_CLASSES.has(entry.class_name):
			var key = Util.to_key_name(entry.name)
			var property = get(entry.name)
			var is_value = property is Property
			var is_raw = property is Localizable
			if property and (is_value or is_raw) and property.visible:
				if is_value:
					property.value = dict.get(key, property.default_value)
				elif is_raw:
					property.raw_data = dict.get(key, {})
				var label = key.capitalize()
				property.callers["set_label_text"] = [label]
				property.show(field_vbox)


func _to_dict() -> Dictionary:
	var dict: Dictionary = {}
	for property in get_property_list():
		if Constants.PROPERTY_CLASSES.has(property.class_name):
			var reference = get(property.name)
			var is_raw = reference is Localizable
			var value = reference.to_raw_value() if is_raw else reference.value
			dict[Util.to_key_name(property.name)] = value
	return dict
