class_name MonologueLine extends MonologueField

@export var copyable: bool
@export var font_size: int = 16
@export var is_sublabel: bool
@export var sublabel_prefix: String = "↳ "
@export var note_text: String

var ribbon_scene = preload("res://common/ui/ribbon/ribbon.tscn")
var revert_text: String
var validator: Callable = func(_text): return true

@onready var copy_button = $HBox/InnerVBox/LineEdit/HBoxContainer/CopyButton
@onready var line_edit = $HBox/InnerVBox/LineEdit
@onready var warning = $HBox/InnerVBox/WarnLabel
@onready var note = $NoteLabel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	copy_button.visible = copyable
	line_edit.add_theme_font_size_override("font_size", font_size)
	warning.add_theme_font_size_override("font_size", font_size)
	warning.hide()
	note.visible = !note_text.is_empty()
	note.text = note_text


func propagate(value: Variant) -> void:
	super.propagate(value)
	line_edit.text = str(value)
	revert_text = line_edit.text


func _on_copy_button_pressed() -> void:
	DisplayServer.clipboard_set(line_edit.text)
	var ribbon = ribbon_scene.instantiate()
	ribbon.position = get_viewport().get_mouse_position()
	get_window().add_child(ribbon)


func _on_focus_exited() -> void:
	_on_text_submitted(line_edit.text)


func _on_text_changed(new_text: String) -> void:
	field_changed.emit(new_text)


func _on_text_submitted(new_text: String) -> void:
	if validator.call(new_text):
		field_updated.emit(new_text)
	else:
		line_edit.text = revert_text
