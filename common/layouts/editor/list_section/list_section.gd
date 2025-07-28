extends VBoxContainer

@export var section_icon: Texture2D

@onready var vbox := $ScrollContainer/VBox
@onready var search_bar: LineEdit = $ToolBar/LineEdit

var add_func: Callable


func _ready() -> void:
	search_bar.placeholder_text = "Filter %s" % name


func clear() -> void:
	for child in vbox.get_children():
		child.queue_free()


func load_items(property: Property) -> void:
	clear()
	property.setters["is_section"] = true
	var field := property.show(vbox)
	add_func = field._on_add_button_pressed


func _on_add_button_pressed() -> void:
	if add_func and add_func.is_valid():
		add_func.call()
