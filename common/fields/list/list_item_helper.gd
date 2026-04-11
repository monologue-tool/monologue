class_name ListItemHelper extends RefCounted

enum MenuActions { EDIT, DUPLICATE, DELETE }


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
	var icons: Dictionary = {
		"delete": preload("res://ui/assets/icons/trash.svg"),
		"edit": preload("res://ui/assets/icons/pen.svg"),
		"duplicate": preload("res://ui/assets/icons/copy.png")
	}
	
	var edit_button: Button = Button.new()
	edit_button.icon = icons["edit"]
	edit_button.tooltip_text = "Edit item"
	edit_button.pressed.connect(owner.call.bind("_on_edit_item", index))
	header.add_child(edit_button)
	
	if not is_protected:
		var menu_button: MenuButton = MenuButton.new()
		menu_button.icon = preload("res://ui/assets/icons/vertical_dots.svg")
		var menu_popup: PopupMenu = menu_button.get_popup()
		menu_popup.add_item("Duplicate", MenuActions.DUPLICATE)
		menu_popup.add_separator()
		menu_popup.add_item("Delete", MenuActions.DELETE)
		menu_popup.id_pressed.connect(_on_menu_button_id_pressed.bind(owner, index))

		header.add_child(menu_button)

	return header


static func _on_menu_button_id_pressed(id: MenuActions, owner: ListField, index: int) -> void:
	match id:
		MenuActions.EDIT:
			owner._on_edit_item(index)
		MenuActions.DUPLICATE:
			owner._on_duplicate_item(index)
		MenuActions.DELETE:
			owner._on_delete_item(index)


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
