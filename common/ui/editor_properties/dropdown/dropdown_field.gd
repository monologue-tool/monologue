extends Field

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


func _on_source_changed(_obj: InspectableObject, property_name: String) -> void:
	if not _binding or not _binding.property:
		return
	
	var source: String = _binding.property.settings.get("source", "")
	if property_name == source:
		# Source data changed, repopulate options
		_populate_options()


func _populate_options() -> void:
	option_button.clear()
	
	if not _binding or not _binding.property:
		return
	
	var property: Property = _binding.property
	var options: Array = property.settings.get("options", [])
	var source: String = property.settings.get("source", "")
	
	# If source is specified, get options from storyline
	if not source.is_empty() and _binding.property_owner:
		options = _get_options_from_source(source)
	
	# Add options to dropdown
	for option in options:
		var text: String = str(option)
		option_button.add_item(text)
	
	# Set current value
	if _binding.property.value:
		set_value(_binding.property.value)


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
			var name = item.get("name", item.get("Name", ""))
			if not name.is_empty():
				result.append(name)
		else:
			result.append(str(item))
	
	return result


func _get_storyline() -> InspectableObject:
	if not _binding or not _binding.property_owner:
		return null
	
	var owner = _binding.property_owner
	
	# If owner is a node, get its storyline
	if owner is InspectableNode:
		var node: InspectableNode = owner
		var storyline_id = node.storyline_id
		if storyline_id:
			return StorylineManager.get_storyline(storyline_id)
	
	# If owner is already a storyline, return it
	if owner is StorylineDocument:
		return owner
	
	return null


func _on_item_selected(index: int) -> void:
	var text = option_button.get_item_text(index)
	emit_value_changed(text)
	emit_value_committed(text)
