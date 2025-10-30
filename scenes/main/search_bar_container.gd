extends CenterContainer

@onready var searchbar = $SearchBar
@onready var graph_edit_switcher = %GraphEditSwitcher


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Show searchbar"):
		searchbar.visible = !searchbar.visible
		if searchbar.visible:
			searchbar.focus()
		graph_edit_switcher.prevent_switching = true

	if Input.is_key_pressed(KEY_ESCAPE):
		searchbar.hide()
		graph_edit_switcher.prevent_switching = false
