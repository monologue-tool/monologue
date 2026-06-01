class_name ListItemHelper
enum MenuActions { EDIT, DUPLICATE, DELETE }

static func populate_item_view(owner: ListField, item_view: PanelContainer, item: ListItem, item_index: int) -> void:
	_make_item_row(owner, item_view, item_index, item)


static func _make_item_row(
	owner: ListField,
	content: PanelContainer,
	index: int,
	item: ListItem,
) -> void:
	var is_protected: bool = item.get_property_value("protected") == true

	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(row)

	var drag_handle: Button = Button.new()
	drag_handle.icon = preload("res://ui/assets/icons/drag_handle.svg")
	drag_handle.theme_type_variation = "ListItemIconButton"
	drag_handle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(drag_handle)

	var preview_prop_name: String = item.get_preview_property_names()[0]
	var preview_prop: Property = item.get_property(preview_prop_name)
	var preview_field: Field = FieldBucket.create_field(preview_prop.type)
	preview_field.set_preview()
	preview_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_prop.bind_field(preview_field, item, true)
	row.add_child(preview_field)

	var edit_button: Button = Button.new()
	edit_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	edit_button.icon = preload("res://ui/assets/icons/pen.svg")
	edit_button.tooltip_text = "Edit item"
	edit_button.theme_type_variation = "ListItemIconButton"
	edit_button.pressed.connect(owner.call.bind("_on_edit_item", index))
	row.add_child(edit_button)

	if not is_protected:
		var delete_button: Button = Button.new()
		delete_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		delete_button.icon = preload("res://ui/assets/icons/cross.svg")
		delete_button.tooltip_text = "Delete item"
		delete_button.theme_type_variation = "ListItemIconButton"
		delete_button.pressed.connect(owner.call.bind("_on_delete_item", index))
		row.add_child(delete_button)


static func _on_menu_button_id_pressed(id: MenuActions, owner: ListField, index: int) -> void:
	match id:
		MenuActions.DUPLICATE:
			owner._on_duplicate_item(index)
		MenuActions.DELETE:
			owner._on_delete_item(index)


static func populate_external_item_view(item_view: PanelContainer, name: String) -> void:
	item_view.theme_type_variation = "ListItemContainer"
	item_view.modulate = Color(1, 1, 1, 0.6)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	item_view.add_child(main_vbox)

	var row: HBoxContainer = HBoxContainer.new()
	main_vbox.add_child(row)

	var ext_label: Label = Label.new()
	ext_label.text = name
	ext_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ext_label)

	var badge: Label = Label.new()
	badge.text = "(imported)"
	badge.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	row.add_child(badge)
