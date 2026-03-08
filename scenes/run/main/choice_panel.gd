extends VBoxContainer

var option_button_instance: PackedScene = preload("res://scenes/run/common/option_button.tscn")


func add_button(text: String, callback: Callable) -> void:
	var new_button: Button = option_button_instance.instantiate()
	new_button.text = text
	new_button.tooltip_text = text

	new_button.pressed.connect(callback)

	add_child(new_button)


func clear() -> void:
	for child: Node in get_children():
		child.queue_free()
