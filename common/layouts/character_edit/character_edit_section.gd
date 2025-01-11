class_name CharacterEditSection extends Control


func _get_all_fields() -> Array:
	var fields := []
	for property in get_property_list():
		if property.class_name != "Property":
			continue
		fields.append(property.name)
		var property_var: Property = get(property.name)
		if property_var.is_connected("change", change):
			property_var.disconnect("change", change)
		property_var.connect("change", change.bind(property.name))
		
		if not property_var.is_connected("display", display):
			property_var.connect("display", display)

	return fields


func change(old_value: Variant, new_value: Variant, property: String) -> void:
	var changes: Array[PropertyChange] = []
	changes.append(PropertyChange.new(property, old_value, new_value))
	
	var graph = get_graph_edit()
	var undo_redo = graph.undo_redo
	undo_redo.create_action("%s: %s => %s" % [property, old_value, new_value])
	var history = PropertyHistory.new(graph, graph.get_path_to(self), changes)
	undo_redo.add_prepared_history(history)
	undo_redo.commit_action()


func display() -> void:
	get_graph_edit().set_selected(self)


func get_graph_edit() -> MonologueGraphEdit:
	return self.graph_edit


func _from_dict(dict: Dictionary) -> void:
	# Delete old fields
	for field in self.field_vbox.get_children():
		field.queue_free()
	
	# Reset property to default
	for field_name in _get_all_fields():
		var property: Property = get(field_name)
		property.value = property.default_value
	
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


func _to_dict() -> Dictionary:
	var dict: Dictionary = {}
	for property in get_property_list():
		if property.class_name != "Property":
			continue
		
		var property_name: String = property.name
		#print(property_name)
		#print(get(property_name).value)
		dict[Util.to_key_name(property_name)] = get(property_name).value
	return dict
