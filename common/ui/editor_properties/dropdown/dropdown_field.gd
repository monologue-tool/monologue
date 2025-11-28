extends Field

var _is_listening: bool = false
var _static_options: Array = []

@onready var option_button: OptionButton = %OptionButton


func _ready() -> void:
	super._ready()
	option_button.item_selected.connect(_on_item_selected)


func set_value(value: Variant) -> void:
	# If value is a string, find it in the list
	if value is String:
		for i in range(option_button.item_count):
			if option_button.get_item_text(i) == value:
				option_button.selected = i
				return
		if option_button.item_count > 0:
			option_button.selected = 0
			return
	# If value is an int, use it as index
	elif value is int and value >= 0 and value < option_button.item_count:
		option_button.selected = value


func get_value() -> Variant:
	var selected_idx = option_button.selected
	if selected_idx >= 0:
		return option_button.get_item_text(selected_idx)
	return ""


func set_editable(is_editable: bool) -> void:
	option_button.disabled = not is_editable


func _on_initialize() -> void:
	super._on_initialize()
	_populate_options()
	_setup_source_listener()


func _setup_source_listener() -> void:
	if not _binding or not _binding.property:
		return

	var property: Property = _binding.property
	var source: String = property.settings.get("source", "")

	if not source.is_empty():
		# Listen for changes to the source property
		var storyline = _get_storyline()
		if storyline:
			storyline.add_observer(_on_source_changed)
			if not _is_listening and storyline.history:
				storyline.history.command_executed.connect(_on_storyline_command_executed)
				storyline.history.redone.connect(_on_storyline_command_executed)
				storyline.history.undone.connect(_on_storyline_command_executed)
				_is_listening = true


func _on_source_changed(_obj: InspectableObject, property_name: String) -> void:
	if not _binding or not _binding.property:
		return

	var source: String = _binding.property.settings.get("source", "")
	if property_name == source:
		# Source data changed, repopulate options
		_populate_options()
		_set_value_to_existing()


func _on_storyline_command_executed() -> void:
	_populate_options()
	_set_value_to_existing()


func _populate_options() -> void:
	option_button.clear()

	var options: Array = []
	var property: Property = (_binding.property if _binding else null)
	if property:
		var source: String = property.settings.get("source", "")
		if not source.is_empty() and _binding.owner:
			options = _get_options_from_source(source)
		else:
			options = _normalize_options_array(property.settings.get("options", []))

	if options.is_empty():
		options = _static_options.duplicate()

	for option in options:
		option_button.add_item(str(option))

	_set_value_to_existing()


func _set_value_to_existing() -> void:
	if not _binding or not _binding.property:
		if _static_options.is_empty():
			return
		var default_value: Variant = _static_options[0] if _static_options.size() > 0 else ""
		set_value(default_value)
		return

	var current_value: Variant = _binding.property.get_value()
	if current_value == null:
		return
	set_value(current_value)


func set_static_options(options: Variant) -> void:
	_static_options = _normalize_options_array(options)
	if is_node_ready():
		_populate_options()
	else:
		call_deferred("_populate_options")


func _normalize_options_array(source: Variant) -> Array:
	if source is Array:
		return (source as Array).duplicate()
	if source is PackedStringArray:
		return Array(source)
	if source is PackedInt32Array:
		var arr: Array = []
		for value in source:
			arr.append(value)
		return arr
	if source is String:
		return [source]
	if source == null:
		return []
	return [str(source)]


func _get_options_from_source(source: String) -> Array:
	var result: Array = []

	# Get storyline from property owner
	var storyline = _get_storyline()
	if not storyline:
		return result

	# Get the list property from storyline
	var list_property: Property = storyline.get_property(source)
	if not list_property:
		return result

	var list_value = list_property.get_value()
	if not list_value is Array:
		return result

	# Extract names from list items
	for item in list_value:
		if item is Dictionary:
			# Try to get a name field (supports both lowercase and capitalized for backward compatibility)
			var entry_name = item.get("name", item.get("Name", ""))
			# Also support old format with Character.Name structure
			if entry_name.is_empty() and item.has("Character"):
				var character_dict = item.get("Character", {})
				if character_dict is Dictionary:
					entry_name = character_dict.get("Name", "")
			if not entry_name.is_empty():
				result.append(entry_name)
		else:
			result.append(str(item))

	return result


func _get_storyline() -> InspectableObject:
	if not _binding or not _binding.owner:
		return null

	var story_owner = _binding.owner

	# If owner is a node, get its storyline
	if story_owner is InspectableNode:
		var node: InspectableNode = story_owner
		var storyline_id = node.storyline_id
		if storyline_id:
			return StorylineManager.get_storyline(storyline_id)

	# If owner is already a storyline, return it
	if story_owner is StorylineDocument:
		return story_owner

	return null


func _on_item_selected(index: int) -> void:
	var text = option_button.get_item_text(index)
	emit_value_changed(text)
	emit_value_committed(text)
