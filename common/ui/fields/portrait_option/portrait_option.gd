class_name PortraitOption extends MonologueField

signal pressed(this_option: PortraitOption)
signal set_to_default(this_option: PortraitOption)
signal name_submitted(this_option: PortraitOption)

@onready var line_edit: LineEdit = %LineEdit
@onready var btn_star := $MarginContainer/HBoxContainer/HBoxContainer/btnStar
@onready var button := %Button

@onready var active_stylebox: StyleBoxFlat = StyleBoxFlat.new()
@onready var star_icon := preload("res://ui/assets/icons/star.svg")
@onready var star_full_icon := preload("res://ui/assets/icons/star_full.svg")

@export var is_default: bool = false

var is_active: bool = false
var line_edit_unfocus_stylebox := StyleBoxEmpty.new()
var custom_delete_button: Button = Button.new()


func _ready() -> void:
	line_edit_unfocus()

	active_stylebox.bg_color = Color("d55160")
	active_stylebox.set_corner_radius_all(5)


func propagate(value: Variant) -> void:
	super.propagate(value)


func set_option_name(new_name: String) -> void:
	line_edit.text = new_name


func line_edit_unfocus() -> void:
	line_edit.editable = false
	line_edit.selecting_enabled = false
	line_edit.flat = true
	line_edit.mouse_filter = Control.MOUSE_FILTER_PASS

	button.show()
	add_theme_stylebox_override("focus", line_edit_unfocus_stylebox)
	name_submitted.emit(self)


func _on_btn_edit_pressed() -> void:
	line_edit.editable = true
	line_edit.selecting_enabled = true
	line_edit.flat = false
	line_edit.mouse_filter = Control.MOUSE_FILTER_STOP
	line_edit.grab_focus()

	button.hide()


func _on_line_edit_focus_exited() -> void:
	line_edit_unfocus()


func _on_btn_star_pressed() -> void:
	set_default()


func set_default() -> void:
	is_default = true
	btn_star.texture_normal = star_full_icon
	set_to_default.emit(self)


func release_default() -> void:
	is_default = false
	btn_star.texture_normal = star_icon


func set_active() -> void:
	is_active = true
	add_theme_stylebox_override("panel", active_stylebox)


func release_active() -> void:
	is_active = false
	remove_theme_stylebox_override("panel")
	line_edit_unfocus()


func _on_button_pressed() -> void:
	pressed.emit(self)


func _on_button_gui_input(event: InputEvent) -> void:
	if is_active and event is InputEventMouseButton and event.is_pressed() and event.double_click:
		_on_btn_edit_pressed()


func _on_line_edit_text_submitted(_new_text: String) -> void:
	line_edit_unfocus()


func use_custom_field_label() -> bool:
	return true
