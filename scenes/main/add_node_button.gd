extends Button


func _on_pressed() -> void:
	EventBus.enable_picker_mode.emit("", -1, null, null, null, true)
