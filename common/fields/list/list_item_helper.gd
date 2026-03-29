class_name ListItemHelper extends RefCounted


static func populate_item_view(owner: ListField, item_view: VBoxContainer, item: ListItem, item_index: int) -> void:
	for prop: Property in item.get_properties():
		if not prop.name in item.get_preview_property_names():
			continue
			
		var field_container: VBoxContainer = VBoxContainer.new()
		var field: Field = FieldBucket.create_field(prop.type)
		var field_title: HBoxContainer = _create_field_title(prop)
		
		field_container.add_child(field_title)
		field_container.add_child(field)
		item_view.add_child(field_container)
		
		prop.bind_field(field, item)
		
	_make_item_header(owner, item_view, item_index, item)


static func _create_field_title(prop: Property) -> HBoxContainer:
	var field_name: String = prop.name
	var field_config: Dictionary = prop.get_settings()
	
	var title_container: HBoxContainer = HBoxContainer.new()
	title_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = Util.to_readable_name(field_name)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if field_config.has("tooltip"):
		label.tooltip_text = field_config["tooltip"]

	title_container.add_child(label)
	return title_container


static func _get_or_create_header_container(content: Control) -> HBoxContainer:
	if content.get_child_count() == 0:
		return HBoxContainer.new()

	var first_child: Node = content.get_child(0)
	if not first_child is BoxContainer or first_child.get_child_count() == 0:
		return HBoxContainer.new()

	var header_candidate: Node = first_child.get_child(0)
	if header_candidate is HBoxContainer:
		return header_candidate

	return HBoxContainer.new()


static func _make_item_header(
	owner: ListField,
	content: Control,
	index: int,
	item: ListItem,
) -> HBoxContainer:
	var header: HBoxContainer = _get_or_create_header_container(content)
	var is_protected: bool = item.get_property_value("protected") == true
	var actions: Array = ["edit", "duplicate", "delete"] if not is_protected else ["edit"]
	var icons: Dictionary = {
		"delete": preload("res://ui/assets/icons/trash.svg"),
		"edit": preload("res://ui/assets/icons/pen.svg"),
		"duplicate": preload("res://ui/assets/icons/copy.png")
	}

	for action: String in actions:
		var icon: Texture2D = icons[action]
		_add_button(
			owner,
			header,
			index,
			action,
			action.capitalize() + " item",
			icon,
		)

	return header

static func _add_button(
	owner: ListField,
	header: HBoxContainer,
	index: int,
	action_name: String,
	tooltip: String,
	icon: Texture2D
) -> void:
	var button: Button = Button.new()
	button.icon = icon
	button.tooltip_text = tooltip
	button.pressed.connect(owner.call.bind("_on_%s_item" % action_name, index))
	header.add_child(button)


static func populate_external_item_view(item_view: PanelContainer, name: String) -> void:
	item_view.theme_type_variation = "ListItemContainer"
	item_view.modulate = Color(1, 1, 1, 0.6)
	
	var main_vbox: VBoxContainer = VBoxContainer.new()
	item_view.add_child(main_vbox)

	var header: HBoxContainer = HBoxContainer.new()
	var ext_label: Label = Label.new()
	ext_label.text = name
	ext_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(ext_label)

	var badge: Label = Label.new()
	badge.text = "(imported)"
	badge.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	header.add_child(badge)

	main_vbox.add_child(header)
