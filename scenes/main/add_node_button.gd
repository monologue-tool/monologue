extends Button


func _on_pressed() -> void:
	GlobalSignal.emit("enable_picker_mode", ["", -1, null, null, null, true])
