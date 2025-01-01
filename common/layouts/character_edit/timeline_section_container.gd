extends VBoxContainer


@onready var timeline := $TimelineContainer/Timeline
@onready var layer_vbox := %LayerVBox
@onready var layer_timeline_vbox := %LayerTimelineVBox
@onready var cell_number_hbox := %CellNumberHBox

@onready var layer := preload("res://common/layouts/character_edit/layer.tscn")
@onready var layer_timeline := preload("res://common/layouts/character_edit/layer_timeline.tscn")
@onready var cell_number := preload("res://common/layouts/character_edit/cell_number.tscn")

var cell_count: int = 1


func _ready() -> void:
	add_timeline()
	_update_cell_number()


func _from_dict(dict: Dictionary) -> void:
	pass


func add_timeline() -> void:
	var new_layer := layer.instantiate()
	var new_layer_timeline: LayerTimeline = layer_timeline.instantiate()
	
	new_layer_timeline.timeline_section = self
	
	layer_vbox.add_child(new_layer)
	layer_timeline_vbox.add_child(new_layer_timeline)


func _update_cell_number() -> void:
	for cell in cell_number_hbox.get_children():
		cell.queue_free()
	
	for i in range(cell_count):
		var new_cell := cell_number.instantiate()
		new_cell.cell_number = i+1
		cell_number_hbox.add_child(new_cell)


func add_cell() -> void:
	cell_count += 1
	_update_cell_number()
	for t in layer_timeline_vbox.get_children():
		t.add_cell()


func _to_dict() -> Dictionary:
	return {}


func _on_btn_add_cell_pressed() -> void:
	add_cell()


func _on_btn_add_layer_pressed() -> void:
	add_timeline()
