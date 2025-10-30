## Container for the search bar with keyboard shortcut handling.
##
## Manages the visibility and focus of the search bar, toggling it with
## a keyboard shortcut and preventing graph tab switching while active.
extends CenterContainer

## Reference to the search bar control.
@onready var searchbar = $SearchBar

## Reference to the graph edit switcher control.
@onready var graph_edit_switcher = %GraphEditSwitcher


## Handles input events for showing/hiding the search bar.
##
## Toggles search bar visibility with the "Show searchbar" action,
## and hides it when Escape is pressed.
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Show searchbar"):
		searchbar.visible = !searchbar.visible
		if searchbar.visible:
			searchbar.focus()
		graph_edit_switcher.prevent_switching = true

	if Input.is_key_pressed(KEY_ESCAPE):
		searchbar.hide()
		graph_edit_switcher.prevent_switching = false
