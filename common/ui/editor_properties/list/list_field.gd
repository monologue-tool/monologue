extends Field

@onready var items_container: VBoxContainer = %ItemsContainer

var _list_items: Array = []
var _item_template: Dictionary = {}


func _ready() -> void:
	super._ready()


func set_value(value: Variant) -> void:
	if value is Array:
		_list_items = value.duplicate()
	else:
		_list_items = []
	_rebuild_ui()


func get_value() -> Variant:
	return _list_items


func set_editable(is_editable: bool) -> void:
	# Update editability of existing items
	if is_instance_valid(items_container):
		for child in items_container.get_children():
			if child.has_method("set_editable"):
				child.set_editable(is_editable)


func _on_initialize() -> void:
	super._on_initialize()
	if _binding and _binding.property:
		var property: Property = _binding.property
		_item_template = property.settings.get("item_template", {})
	
	# Ensure nodes are ready before rebuilding UI
	if not is_node_ready():
		await ready
	_rebuild_ui()


func _supports_edit_button() -> bool:
	return false  # No longer using edit button approach


func _rebuild_ui() -> void:
	# Ensure items_container is valid before proceeding
	if not is_instance_valid(items_container):
		return
	
	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()
	
	# Create UI for each list item
	for i in range(_list_items.size()):
		var item_ui = _create_item_ui(i)
		items_container.add_child(item_ui)


func _create_item_ui(index: int) -> Control:
	var item_panel = PanelContainer.new()
	item_panel.theme_type_variation = "ListItemContainer"
	
	var vbox = VBoxContainer.new()
	item_panel.add_child(vbox)
	
	# Header with delete button
	var header_hbox = HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var label = Label.new()
	label.text = "Item " + str(index + 1)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(label)
	
	var delete_button = Button.new()
	delete_button.text = "✕"
	delete_button.tooltip_text = "Remove item"
	delete_button.pressed.connect(_on_delete_item.bind(index))
	header_hbox.add_child(delete_button)
	
	# Create fields for item properties based on template
	var item_data = _list_items[index]
	if not item_data is Dictionary:
		item_data = {}
		_list_items[index] = item_data
	
	# Show all fields for inline editing
	for prop_name in _item_template.keys():
		var prop_config = _item_template[prop_name]
		var field_container = _create_property_field(prop_name, prop_config, item_data, index)
		if field_container:
			vbox.add_child(field_container)
	
	return item_panel


func _create_property_field(prop_name: String, prop_config: Dictionary, item_data: Dictionary, item_index: int) -> Control:
	var field_type = prop_config.get("type", "text")
	
	# Handle editor_only fields (like buttons)
	if prop_config.get("editor_only", false):
		if field_type == "button":
			var button = Button.new()
			button.text = prop_config.get("button_text", "Edit")
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if prop_config.get("expand", false) else 0
			button.pressed.connect(func():
				# Emit signal for editor-only button clicks
				GlobalSignal.emit("edit_list_item", [_binding.property.name, item_index, item_data])
			)
			return button
		return null
	
	var container = HBoxContainer.new()
	
	var prop_label = Label.new()
	prop_label.text = Util.to_readable_name(prop_name)
	prop_label.custom_minimum_size.x = 100
	container.add_child(prop_label)
	
	# For dropdown fields, we need to create a temporary property with options
	if field_type == "dropdown":
		var temp_property = Property.new(prop_name, item_data.get(prop_name, prop_config.get("default", "")), field_type, prop_config)
		var field = FieldBucket.create_field(field_type)
		
		if not field:
			var warn_label = Label.new()
			warn_label.text = "Unknown field type: " + field_type
			warn_label.theme_type_variation = "WarnLabel"
			container.add_child(warn_label)
			return container
		
		field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(field)
		
		# Bind the field to the temporary property
		temp_property.bind_field(field, null)
		
		# Connect to value changes
		field.value_committed.connect(func(new_value):
			_on_item_property_changed(item_index, prop_name, new_value)
		)
	else:
		var field = FieldBucket.create_field(field_type)
		
		if not field:
			var warn_label = Label.new()
			warn_label.text = "Unknown field type: " + field_type
			warn_label.theme_type_variation = "WarnLabel"
			container.add_child(warn_label)
			return container
		
		field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_child(field)
		
		# Set initial value
		var current_value = item_data.get(prop_name, prop_config.get("default", ""))
		field.set_value.call_deferred(current_value)
		
		# Connect to value changes
		field.value_committed.connect(func(new_value):
			_on_item_property_changed(item_index, prop_name, new_value)
		)
	
	return container


func _on_item_property_changed(item_index: int, prop_name: String, new_value: Variant) -> void:
	if item_index >= 0 and item_index < _list_items.size():
		var item_data = _list_items[item_index]
		if item_data is Dictionary:
			item_data[prop_name] = new_value
			emit_value_changed(_list_items)
			emit_value_committed(_list_items)


func _on_delete_item(index: int) -> void:
	if index >= 0 and index < _list_items.size():
		_list_items.remove_at(index)
		_rebuild_ui()
		emit_value_changed(_list_items)
		emit_value_committed(_list_items)
