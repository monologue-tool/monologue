## A list section in the editor with filtering and add functionality.
##
## Displays a filterable list of items with an icon and search bar.
## Items can be added through a callable function.
extends PanelContainer

## Icon displayed for this section.
@export var section_icon: Texture2D

## Reference to the vertical box containing list items.
@onready var vbox := %VBox

## Reference to the search/filter line edit.
@onready var search_bar: LineEdit = %SearchLine

## Callable function for adding new items.
var add_func: Callable


## Initializes the section with filter placeholder text.
func _ready() -> void:
	search_bar.placeholder_text = "Filter %s" % name.to_lower()


## Clears all items from the list.
func clear() -> void:
	for child in vbox.get_children():
		child.queue_free()


## Loads items from a property into the list.
##
## Currently commented out/incomplete implementation.
## [br][br]
## [param property] The property containing items to load.
func load_items(property: Property) -> void:
	clear()
	#property.setters["is_section"] = true
	#var field := property.show(vbox)
	#add_func = field._on_add_button_pressed


## Handles add button press by calling the registered add function.
func _on_add_button_pressed() -> void:
	if add_func and add_func.is_valid():
		add_func.call()
