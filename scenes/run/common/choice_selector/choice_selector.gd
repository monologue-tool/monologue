## Choice selector for displaying dialogue options during playback.
##
## Presents dialogue choices as buttons and emits signals when selected.
## Manages dynamic creation and cleanup of choice buttons.
class_name ChoiceSelector extends Control

## Emitted when a choice is made.
signal choice_made(option)

## Reference to the vertical box container for choice buttons.
@onready var vbox := %VBox

## The last selected option dictionary.
var last_option: Dictionary


## Displays a dialogue option as a button.
##
## Creates a button for the option and shows the selector.
## [br][br]
## [param option] Dictionary containing the option data.
## [br][br]
## [param language] Language to use for option text. Default is "English".
func display_option(option: Dictionary, language: String = "English") -> void:
	show()
	var button := Button.new()
	button.text = option.get("Option", {}).get(language, "")
	if button.text == "":
		button.text = " "
	button.connect("pressed", _on_button_pressed.bind(option))
	vbox.add_child(button)
	(vbox.get_child(0) as Button).grab_focus()


## Clears all choice buttons and hides the selector.
func _clear() -> void:
	hide()
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.queue_free()


## Handles choice button press.
##
## Stores the option, emits the choice_made signal, and clears the selector.
## [br][br]
## [param option] The option dictionary for the selected choice.
func _on_button_pressed(option: Dictionary) -> void:
	last_option = option
	choice_made.emit(option)
	_clear()
