extends MarginContainer

@onready var text_edit: TextEdit = %TextEdit
var little_text_edit: TextEdit


func _ready() -> void:
	hide()
	EventBus.expand_text_edit.connect(_on_expand_text_edit)


func _on_expand_text_edit(little_te: TextEdit) -> void:
	little_text_edit = little_te
	text_edit.text = little_text_edit.text

	show()


func _on_button_pressed() -> void:
	hide()
	little_text_edit.focus_exited.emit()


func _on_text_edit_text_changed() -> void:
	little_text_edit.text = text_edit.text
	little_text_edit.text_changed.emit(text_edit.text)


func _on_visibility_changed() -> void:
	if visible:
		EventBus.show_dimmer.emit()
		return
	EventBus.hide_dimmer.emit()
