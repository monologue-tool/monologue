class_name LanguageOption extends Button


signal language_name_changed(old_name: String, new_name: String, option: LanguageOption)
signal language_removed(option: LanguageOption)

var language_name: String : set = set_language_name
var line_edit_unfocus_stylebox := StyleBoxEmpty.new()

@onready var del_button: TextureButton = $MarginContainer/HBoxContainer/ControlsContainer/btnDelete
@onready var line_edit: LineEdit = $MarginContainer/HBoxContainer/LineEdit
@onready var line_edit_focus_stylebox: StyleBoxFlat = preload("res://ui/theme_default/line_edit_focus.tres")


func _ready() -> void:
	line_edit_unfocus_stylebox.set_content_margin_all(line_edit_focus_stylebox.content_margin_top)
	line_edit_unfocus()


func _to_string() -> String:
	return line_edit.text


func line_edit_unfocus() -> void:
	line_edit.editable = false
	line_edit.selecting_enabled = false
	line_edit.flat = true
	line_edit.mouse_filter = Control.MOUSE_FILTER_PASS
	
	add_theme_stylebox_override("focus", line_edit_unfocus_stylebox)


func set_language_name(new_name: String) -> void:
	language_name = new_name
	line_edit.text = new_name


func show_delete_button(can_see: bool = true) -> void:
	del_button.visible = can_see


func _on_btn_edit_pressed() -> void:
	line_edit.editable = true
	line_edit.selecting_enabled = true
	line_edit.flat = false
	line_edit.mouse_filter = Control.MOUSE_FILTER_STOP
	
	add_theme_stylebox_override("focus", line_edit_focus_stylebox)


func _on_btn_delete_pressed() -> void:
	language_removed.emit(self)
	queue_free()


func _on_line_edit_focus_exited() -> void:
	_on_line_edit_text_submitted(line_edit.text)


func _on_line_edit_text_submitted(new_text: String) -> void:
	if language_name != new_text:
		language_name_changed.emit(language_name, new_text, self)
		language_name = new_text
	line_edit_unfocus()
