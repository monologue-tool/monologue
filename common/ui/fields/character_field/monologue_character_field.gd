class_name MonologueCharacterField extends MonologueField


@onready var name_edit := %NameEdit
@onready var delete_button := $HBoxContainer/VBoxContainer/VBoxContainer/HBoxContainer/DeleteButton

var character_index: int
var default_portrait: String = ""
var graph_edit: MonologueGraphEdit


func propagate(value: Variant) -> void:
	super.propagate(value)
	name_edit.text = value.get("Name", "")


func _on_name_edit_focus_exited() -> void:
	_on_name_edit_text_submitted(name_edit.text)


func _on_name_edit_text_submitted(new_text: String) -> void:
	field_updated.emit({"Name" = new_text})


func _on_edit_button_pressed() -> void:
	GlobalSignal.emit("open_character_edit", [graph_edit, character_index])
