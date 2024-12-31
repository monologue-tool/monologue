class_name MonologueCharacterField extends MonologueField


@onready var name_edit := %NameEdit
@onready var delete_button := $HBoxContainer/VBoxContainer/VBoxContainer/HBoxContainer/DeleteButton

var nicknames: String = ""
var display_name: String = ""
var description: String = ""


func propagate(value: Variant) -> void:
	super.propagate(value)
	name_edit.text = value.get("Name", "")


func _to_dict():
	return {
		"Name": name_edit.text,
		"Nicknames": nicknames,
		"DefaultDisplayName": display_name,
		"EditorDescription": description
	}


func _on_line_edit_text_changed(_new_text: String) -> void:
	field_changed.emit(_to_dict())


func _on_name_edit_focus_exited() -> void:
	_on_name_edit_text_submitted(name_edit.text)


func _on_name_edit_text_submitted(new_text: String) -> void:
	field_updated.emit(_to_dict())


func _on_edit_button_pressed() -> void:
	GlobalSignal.emit("open_character_edit", [self])
