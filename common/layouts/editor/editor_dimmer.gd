## A dimming overlay that can be shown/hidden via global signals.
##
## Provides a dark overlay effect for modal dialogs and popups. Uses a request
## counting system to handle multiple overlapping requests correctly.
extends ColorRect

## Count of active dimmer show requests to handle nesting.
var request_count: int = 0


## Initializes the dimmer and registers signal listeners.
func _ready() -> void:
	hide()
	GlobalSignal.add_listener("show_dimmer", _on_show_dimmer)
	GlobalSignal.add_listener("hide_dimmer", _on_hide_dimmer)


## Handles show dimmer requests.
##
## Increments the request count and shows the dimmer overlay.
## [br][br]
## [param _focus_node] Optional node requesting the dimmer (unused).
func _on_show_dimmer(_focus_node: Node = null) -> void:
	request_count = max(1, request_count + 1)
	show()


## Handles hide dimmer requests.
##
## Decrements the request count and hides the dimmer only when count reaches zero.
## [br][br]
## [param _focus_node] Optional node releasing the dimmer (unused).
func _on_hide_dimmer(_focus_node: Node = null) -> void:
	request_count = max(0, request_count - 1)
	if request_count == 0:
		hide()
