class_name ListItemReorderRow extends HBoxContainer

var owner_field: BaseListField
var item_index: int = -1
var external: bool = false
var drag_handle: ListItemDragHandle


func init_drag() -> void:
	drag_handle.grabbed.connect(_on_drag_handle_grabbed)
	drag_handle.released.connect(_on_drag_handle_released)


func _on_drag_handle_grabbed() -> void:
	if external:
		return

	get_parent().offset_transform_enabled = true
	get_parent().z_index = 10


func _on_drag_handle_released() -> void:
	var drag_position_y: float = (
		get_parent().global_position.y + get_parent().offset_transform_position.y
	)
	var new_index: int = item_index
	var rows: Array[Node] = owner_field.get_list_item_controls(true)
	for row: Control in rows:
		var row_index: int = rows.find(row)
		if row == get_parent():
			continue

		# Higher row
		if row_index < item_index and row.global_position.y > drag_position_y:
			new_index = min(new_index, row_index)
		elif row_index > item_index and row.global_position.y < drag_position_y:
			new_index = max(new_index, row_index)

	owner_field.reorder_item(item_index, new_index)

	get_parent().offset_transform_enabled = false
	get_parent().z_index = 0


func _process(_delta: float) -> void:
	if external:
		return

	var mouse_position: Vector2 = get_global_mouse_position()
	var difference: Vector2 = mouse_position - drag_handle.grabbed_position

	get_parent().offset_transform_position.y = difference.y
