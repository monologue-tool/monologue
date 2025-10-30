## Panel for displaying dialogue choice buttons during playback.
##
## Dynamically creates and manages choice buttons for player selections
## during dialogue execution.
extends VBoxContainer

## Preloaded scene for option buttons.
var option_button_instance = preload("res://scenes/run/common/option_button.tscn")


## Adds a new choice button with the given text and callback.
##
## [param text] The button text to display.
## [br][br]
## [param callback] The callable to invoke when the button is pressed.
func add_button(text, callback: Callable):
	var new_button: Button = option_button_instance.instantiate()
	new_button.text = text
	new_button.tooltip_text = text

	new_button.pressed.connect(callback)

	add_child(new_button)


## Clears all choice buttons from the panel.
func clear():
	for child in get_children():
		child.queue_free()
