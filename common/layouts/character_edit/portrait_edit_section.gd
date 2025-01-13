class_name PortraitEditSection extends CharacterEditSection


## Portrait index.
var portrait_index: int = -1


func change(old_value: Variant, new_value: Variant, property: String) -> void:
	var changes: Array[PropertyChange] = []
	changes.append(PropertyChange.new(property, old_value, new_value))
	
	var undo_redo = graph_edit.undo_redo
	undo_redo.create_action("%s: %s => %s" % [property, old_value, new_value])
	var history = PortraitHistory.new(character_index, portrait_index,
			graph_edit, graph_edit.get_path_to(self), changes)
	undo_redo.add_prepared_history(history)
	undo_redo.commit_action()


func _from_dict(dict: Dictionary) -> void:
	flush()
	
	# Load values
	for key in dict.keys():
		var property = get(key.to_snake_case())
		if property is Property:
			property.value = dict.get(key)
	
	# Create fields
	for field_name in _get_all_fields():
		var property: Property = get(field_name)
		var field_label: String = field_name.replace("_", " ").capitalize()
		
		property.callers["set_label_text"] = [field_label]
		property.show(self.field_vbox)
