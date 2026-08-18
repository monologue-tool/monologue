## One button per option. Goes on the container the buttons should be laid out by, so the
## scene decides whether they stack, sit in a row, or anything else.
class_name MonologueDefaultChoices extends MonologueChoicePart


func _ready() -> void:
	clear()


func show_options(options: Array[Dictionary]) -> void:
	clear()
	show()
	for option: Dictionary in options:
		var button: Button = Button.new()
		button.text = str(option.get("text", option.get("key", "")))
		button.pressed.connect(_on_option_pressed.bind(str(option.get("key", ""))))
		add_child(button)


func clear() -> void:
	hide()
	for button: Node in get_children():
		remove_child(button)
		button.queue_free()


func _on_option_pressed(key: String) -> void:
	picked = key
	option_picked.emit()
