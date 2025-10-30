class_name ChoiceSelector extends Control

signal choice_made(option)

@onready var vbox := %VBox

var last_option: Dictionary


func display_option(option: Dictionary, language: String = "English") -> void:
	show()
	var button := Button.new()
	button.text = option.get("Option", {}).get(language, "")
	if button.text == "":
		button.text = " "
	button.connect("pressed", _on_button_pressed.bind(option))
	vbox.add_child(button)
	(vbox.get_child(0) as Button).grab_focus()


func _clear() -> void:
	hide()
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.queue_free()


func _on_button_pressed(option: Dictionary) -> void:
	last_option = option
	choice_made.emit(option)
	_clear()
