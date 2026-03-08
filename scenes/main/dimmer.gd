class_name Dimmer extends ColorRect


func _ready() -> void:
	color = Color.TRANSPARENT
	focus_entered.connect(_on_focus_entered)


func _process(_delta: float) -> void:
	var parent: Control = get_parent()
	var index: int = get_index()
	
	for child: Node in parent.get_children().slice(index+1):
		if not child.visible:
			continue
		
		show()
		return
	hide()


func _on_focus_entered() -> void:
	EventBus.window_out.emit()
