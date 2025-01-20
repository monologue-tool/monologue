class_name PortraitEditSection extends CharacterEditSection


## Selected portrait index.
@export var portrait_index: int = -1


func change(old_value: Variant, new_value: Variant, property: String) -> void:
	var changes: Array[PropertyChange] = []
	changes.append(PropertyChange.new(property, old_value, new_value))
	
	var undo_redo = graph_edit.undo_redo
	undo_redo.create_action("%s: %s => %s" % [property, old_value, new_value])
	var history = PortraitHistory.new(character_index, portrait_index,
			graph_edit, graph_edit.get_path_to(self), changes)
	undo_redo.add_prepared_history(history)
	undo_redo.commit_action()
