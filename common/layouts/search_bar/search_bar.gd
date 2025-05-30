extends PanelContainer


@onready var line_edit: LineEdit = $HBoxContainer/LineEdit


func focus() -> void:
	line_edit.grab_focus()
	line_edit.select_all()
