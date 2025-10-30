## Base class for modal windows in Monologue.
##
## Provides automatic centering, size management, and dimmer integration.
## Windows automatically show/hide the dimmer overlay when opened/closed.
class_name MonologueWindow extends Window


## Initializes the window and connects signals.
func _ready() -> void:
	get_parent().connect("resized", _on_resized)
	update_size.call_deferred()
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()


## Updates the window size and centers it on screen.
func update_size() -> void:
	move_to_center()
	size.x = size.x


## Handles parent resize events by updating window size.
func _on_resized():
	update_size()


## Handles visibility changes by showing/hiding the dimmer.
##
## Shows the dimmer when the window becomes visible, hides it when invisible.
func _on_visibility_changed():
	if visible:
		GlobalSignal.emit("show_dimmer", [self])
		return
	GlobalSignal.emit("hide_dimmer", [self])
