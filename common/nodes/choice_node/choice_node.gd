class_name ChoiceNode extends InspectableNode

const MAX_CHOICES: int = 8

var _external_options: Array[Dictionary] = []


func initialize_properties() -> void:
	define_main_property("choice", "context", false, null, {"export": false, "exposed": true})
	define_property(
		"choices",
		[],
		"list",
		{
			"collection": "option",
			"exposed": false,
			"visible_in_graph": true,
		},
	)
	# Listen for connection changes on the choices property
	var choices_prop: Property = get_property("choices")
	if choices_prop:
		choices_prop.connection_changed.connect(_on_choices_connection_changed)


func get_type() -> String:
	return "choice"


func get_color() -> Color:
	return Color("e89145")


func _on_property_changed(pname: String, _old_value: Variant, _new_value: Variant) -> void:
	if pname == "choices":
		rebuild_preview()


func _on_choices_connection_changed() -> void:
	_sync_external_options()
	rebuild_preview()


func get_external_list_items(property_name: String) -> Array[Dictionary]:
	if property_name == "choices":
		_sync_external_options()
		return _external_options
	return []


## Synchronize external (read-only) option items from connected OptionNodes.
func _sync_external_options() -> void:
	_external_options.clear()
	var choices_prop: Property = get_property("choices")
	if not choices_prop:
		return

	for conn: Dictionary in choices_prop.connected_from:
		var source_node_id: String = conn.get("node_id", "")
		if source_node_id.is_empty():
			continue
		# Find the source node in the storyline
		var source_node: InspectableNode = _find_node_by_id(source_node_id)
		if not source_node or not (source_node is OptionNode):
			continue
		var ext_option: Dictionary = {
			"external": true,
			"source_node_id": source_node_id,
			"name": _get_option_node_name(source_node),
			"text": source_node.get_property_value("text"),
			"enabled": source_node.get_property_value("enabled"),
			"one_shot": source_node.get_property_value("one_shot"),
			"condition": source_node.get_property_value("condition"),
		}
		_external_options.append(ext_option)


func _find_node_by_id(node_id: String) -> InspectableNode:
	if storyline_id.is_empty():
		return null
	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)
	if not storyline:
		return null
	return storyline.get_node(node_id)


func _get_option_node_name(node: InspectableNode) -> String:
	var text_val: Variant = node.get_property_value("text")
	if text_val is Dictionary:
		var text_dict: Dictionary = text_val
		if text_dict.has("value"):
			var t: Variant = text_dict.get("value", "")
			if not str(t).is_empty():
				return str(t)
	return str(node.get_property_value("id"))


## Returns the total number of choices (internal + external).
func get_total_choice_count() -> int:
	var internal_count: int = 0
	var choices_val: Variant = get_property_value("choices")
	if choices_val is Array:
		var choices_arr: Array = choices_val
		internal_count = choices_arr.size()
	return internal_count + _external_options.size()


## Returns the combined list of internal choice data + external option data.
func get_all_choices() -> Array:
	var result: Array = []
	var choices_val: Variant = get_property_value("choices")
	if choices_val is Array:
		var choices_arr: Array = choices_val
		result.append_array(choices_arr)
	for ext: Dictionary in _external_options:
		result.append(ext)
	return result
