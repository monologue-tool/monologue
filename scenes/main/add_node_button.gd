## Button for adding a new node to the dialogue graph.
##
## When pressed, emits a global signal to enable the node picker mode,
## allowing the user to select and add a new node to the graph.
extends Button


## Handles the button press event.
##
## Emits the "enable_picker_mode" global signal with default parameters.
func _on_pressed() -> void:
	GlobalSignal.emit("enable_picker_mode", ["", -1, null, null, null, true])
