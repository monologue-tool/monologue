extends Node

signal tooltip_update

var text: String = ""


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	
	var control: Control = get_viewport().gui_get_hovered_control()
	
	text = ""
	if control and control.tooltip_text or control.has_meta("tooltip"):
		text = control.tooltip_text if control.tooltip_text else control.get_meta("tooltip", "")

	tooltip_update.emit()


func _process(_delta: float) -> void:
	var control: Control = get_viewport().gui_get_hovered_control()
	if not control or not control.tooltip_text:
		return
	
	control.set_meta("tooltip", control.tooltip_text)
	control.tooltip_text = ""
