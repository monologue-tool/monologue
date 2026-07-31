class_name Dimmer extends ColorRect


func _ready() -> void:
	release_focus()
	color = Color.TRANSPARENT
	EventBus.show_dimmer.connect(show)
	EventBus.hide_dimmer.connect(hide)
	#focus_entered.connect(_on_focus_entered)


func _process(_delta: float) -> void:
	var parent: Control = get_parent()
	var index: int = get_index()

	for child: Node in parent.get_children().slice(index + 1):
		if not child.visible:
			continue

		show()
		return
	hide()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		EventBus.window_out.emit()
