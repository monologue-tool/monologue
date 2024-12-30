extends HBoxContainer


@onready var line_edit := $VBox/LineEdit
@onready var warn_label := $VBox/WarnLabel


func _ready() -> void:
	_update()


func _update() -> void:
	var show_warn: bool = not line_edit.text.replace(" ", "").is_empty()
	warn_label.visible = show_warn


func _on_line_edit_text_changed(new_text: String) -> void:
	pass # Replace with function body.


func _on_line_edit_text_submitted(new_text: String) -> void:
	pass # Replace with function body.


func _on_line_edit_focus_exited() -> void:
	pass # Replace with function body.


func _on_file_picker_button_pressed() -> void:
	pass # Replace with function body.
