class_name LayerTimeline extends PanelContainer


@onready var hbox := $HBox

var timeline_section: Control
var timeline_cell := preload("res://common/layouts/character_edit/cell.tscn")


func _ready() -> void:
	fill()


func add_cell() -> TimelineCell:
	var new_cell := timeline_cell.instantiate()
	hbox.add_child(new_cell)
	
	return new_cell


func remove_cell(position: int) -> void:
	var cells: Array = hbox.get_children()
	hbox.remove_child(cells[position])
	cells[position].queue_free()


func fill() -> void:
	_clear()
	for _i in range(timeline_section.cell_count):
		add_cell()


func _clear() -> void:
	for cell in hbox.get_children():
		cell.queue_free()


func _to_dict() -> Dictionary:
	return {}
