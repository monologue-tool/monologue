extends Node

signal tooltip_update

var text: String = ""


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	
	var control: Control = get_viewport().gui_get_hovered_control()
	
	text = ""
	if control and control.tooltip_text:
		text = control.tooltip_text
	tooltip_update.emit()


func _process(_delta: float) -> void:
	var control: Control = get_viewport().gui_get_hovered_control()
	if not control or not control.tooltip_text:
		return
	
	# Hack to disable tooltip on hovered control
	var ttp_text: String = control.tooltip_text
	control.tooltip_text = ""
	control.tooltip_text = ttp_text
