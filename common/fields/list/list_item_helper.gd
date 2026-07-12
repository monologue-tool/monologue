class_name ListItemHelper
enum MenuActions { EDIT, DUPLICATE, DELETE }


static func populate_item_view(owner: BaseListField, item_view: PanelContainer, item: CollectionItem, item_index: int) -> void:
	_make_item_row(owner, item_view, item_index, item)


static func _create_drag_handle(external: bool = false) -> ListItemDragHandle:
	var drag_handle: ListItemDragHandle = ListItemDragHandle.new()
	drag_handle.custom_minimum_size = Vector2(24, 24)
	drag_handle.theme_type_variation = "ListItemIconButton"
	
	if not external:
		drag_handle.icon = preload("res://ui/assets/icons/drag_handle.svg")
		drag_handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	
	return drag_handle


static func _make_item_row(
	owner: BaseListField,
	content: PanelContainer,
	index: int,
	item: CollectionItem,
) -> void:
	var is_protected: bool = item.get_property_value("protected") == true

	var row: ListItemReorderRow = ListItemReorderRow.new()
	row.owner_field = owner
	row.item_index = index
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(row)

	var drag_handle: ListItemDragHandle = _create_drag_handle()
	row.drag_handle = drag_handle
	row.add_child(drag_handle)
	row.init_drag()

	var preview_prop_name: String = item.get_preview_property_names()[0]
	var preview_prop: Property = item.get_property(preview_prop_name)
	var preview_field: Field = FieldBucket.create_field(preview_prop.type)
	preview_field.set_preview()
	preview_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_prop.bind_field(preview_field, item, true)
	row.add_child(preview_field)

	var edit_button: Button = Button.new()
	edit_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	edit_button.icon = preload("res://ui/assets/icons/pen.svg")
	edit_button.tooltip_text = "Edit item"
	edit_button.theme_type_variation = "ListItemIconButton"
	edit_button.pressed.connect(owner._on_edit_item.bind(index))
	row.add_child(edit_button)

	if not is_protected:
		var delete_button: Button = Button.new()
		delete_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		delete_button.icon = preload("res://ui/assets/icons/cross.svg")
		delete_button.tooltip_text = "Delete item"
		delete_button.theme_type_variation = "ListItemIconButton"
		delete_button.pressed.connect(owner._on_delete_item.bind(index))
		row.add_child(delete_button)


static func _on_menu_button_id_pressed(id: MenuActions, owner: BaseListField, index: int) -> void:
	match id:
		MenuActions.DUPLICATE:
			owner._on_duplicate_item(index)
		MenuActions.DELETE:
			owner._on_delete_item(index)


static func populate_external_item_view(content: PanelContainer, name: String) -> void:
	var row: ListItemReorderRow = ListItemReorderRow.new()
	row.external = true
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(row)
	
	var drag_handle: ListItemDragHandle = _create_drag_handle(true)
	row.drag_handle = drag_handle
	row.add_child(drag_handle)
	
	var ext_label: Label = Label.new()
	ext_label.text = name
	ext_label.theme_type_variation = "NoteLabel"
	ext_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ext_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(ext_label)
