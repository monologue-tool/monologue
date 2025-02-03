class_name CollapsibleField extends VBoxContainer


signal add_pressed

@export var show_add_button: bool = false
@export var separate_items: bool = false

@onready var button := $Button
@onready var collapsible_container := $CollapsibleContainer
@onready var vbox := %FieldContainer
@onready var add_button := %AddButton

@onready var icon_close := preload("res://ui/assets/icons/arrow_right.svg")
@onready var icon_open := preload("res://ui/assets/icons/arrow_down.svg")


func _ready() -> void:
	button.icon = icon_close
	add_button.visible = show_add_button
	close()


func add_item(item: Control, force_readable_name: bool = false) -> void:
	if separate_items and vbox.get_children().size() > 0:
		vbox.add_child(HSeparator.new())
	
	vbox.add_child(item, force_readable_name)


func set_title(text: String) -> void:
	button.text = text


func get_items() -> Array[Node]:
	return vbox.get_children().filter(func(c): return c is not HSeparator)


func clear() -> void:
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.queue_free()


func _on_button_pressed() -> void:
	if collapsible_container.visible:
		close()
	else:
		open()


func open() -> void:
	button.icon = icon_open
	collapsible_container.show()
	button.release_focus()


func close() -> void:
	button.icon = icon_close
	collapsible_container.hide()
	button.release_focus()


func _on_add_button_pressed() -> void:
	add_pressed.emit()
