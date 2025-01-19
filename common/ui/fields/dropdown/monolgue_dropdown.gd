class_name MonologueDropdown extends MonologueField


@export var store_index: bool

@onready var label: Label = $Label
@onready var option_button: OptionButton = $OptionButton


func disable_items(index_list: PackedInt32Array):
	for index in range(1, option_button.item_count):
		var is_disabled = index_list.has(index)
		option_button.set_item_disabled(index, is_disabled)
	validate()


func get_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for idx in range(option_button.item_count):
		result.append({
			"id": option_button.get_item_id(idx),
			"text": option_button.get_item_text(idx),
			"metadata": option_button.get_item_metadata(idx)
		})
	return result


func get_item_idx_from_text(text: String) -> int:
	var items = get_items()
	for item in items:
		if item.text == text:
			return items.find(item)
	return -1


func propagate(value: Variant) -> void:
	super.propagate(value)
	var index = get_item_idx_from_text(value) if value is String else value
	if index < 0 or index >= option_button.item_count:  # avoid falsy check
		option_button.selected = 0
	else:
		option_button.selected = index
	validate()


func set_icons(index_to_texture: Dictionary):
	for index in index_to_texture.keys():
		option_button.set_item_icon(index, index_to_texture.get(index))


func set_items(data: Array, key_text: String = "text", key_id: String = "id",
			key_meta: String = "metadata") -> void:
	option_button.clear()
	for idx in range(data.size()):
		var item_id = data[idx].get(key_id, -1)
		option_button.add_item(data[idx].get(key_text, "undefined"), item_id)
		option_button.set_item_metadata(idx, data[idx].get(key_meta, ""))


func set_label_text(text: String) -> void:
	label.text = text


# TODO: properly switch Themes when working on #37 interface redesign
func validate():
	var is_out = option_button.selected >= option_button.item_count
	var is_negative = option_button.selected < 0
	if is_negative or is_out or option_button.is_item_disabled(option_button.selected):
		var stylebox = load("res://ui/theme_default/dropdown_error.stylebox")
		option_button.add_theme_color_override("font_hover_color", Color("c42e40"))
		option_button.add_theme_color_override("font_focus_color", Color("8b0000"))
		option_button.add_theme_color_override("font_color", Color("8b0000"))
		option_button.add_theme_stylebox_override("hover", stylebox)
		option_button.add_theme_stylebox_override("focus", stylebox)
		option_button.add_theme_stylebox_override("normal", stylebox)
	else:
		option_button.remove_theme_color_override("font_hover_color")
		option_button.remove_theme_color_override("font_focus_color")
		option_button.remove_theme_color_override("font_color")
		option_button.remove_theme_stylebox_override("hover")
		option_button.remove_theme_stylebox_override("focus")
		option_button.remove_theme_stylebox_override("normal")


func _on_item_selected(index: int) -> void:
	var value = index
	if not store_index:
		value = option_button.get_item_text(index)
	validate()
	field_updated.emit(value)
