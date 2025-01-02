class_name LayerTimeline extends PanelContainer


@onready var hbox := $HBox

var timeline_section: Control
var timeline_cell := preload("res://common/layouts/character_edit/cell.tscn")
var placement_indicator := preload("res://common/layouts/character_edit/placement_indicator.tscn")

var current_indicator: Control


func _ready() -> void:
	fill()


func add_cell() -> TimelineCell:
	var new_cell := timeline_cell.instantiate()
	hbox.add_child(new_cell)
	new_cell.connect("button_down", _on_cell_button_down.bind(new_cell))
	new_cell.connect("button_up", _on_cell_button_up.bind(new_cell))
	
	return new_cell


func _on_cell_button_down(cell: TimelineCell) -> void:
	current_indicator = placement_indicator.instantiate()
	hbox.add_child(current_indicator)
	hbox.move_child(current_indicator, cell.get_index()+1)


func _on_cell_button_up(cell: TimelineCell) -> void:
	hbox.move_child(cell, current_indicator.get_index())
	
	current_indicator.queue_free()
	current_indicator = null


func _process(_delta: float) -> void:
	if current_indicator == null:
		return
	
	var indicator_dist: float = current_indicator.global_position.x - get_global_mouse_position().x
	var indicator_index: int = current_indicator.get_index()
	if indicator_dist > 13:
		hbox.move_child(current_indicator, indicator_index-1)
	elif indicator_dist <= -13:
		hbox.move_child(current_indicator, indicator_index+1)


func remove_cell(pos: int) -> void:
	var cells: Array = hbox.get_children()
	hbox.remove_child(cells[pos])
	cells[pos].queue_free()


func fill() -> void:
	_clear()
	for _i in range(timeline_section.cell_count):
		add_cell()


func _clear() -> void:
	for cell in hbox.get_children():
		cell.queue_free()


func _from_dict(dict: Dictionary) -> void:
	pass


func _to_dict() -> Dictionary:
	var dict: Dictionary = {}
	for cell: TimelineCell in hbox.get_children():
		var cell_idx: int = cell.get_index()
		dict[cell_idx] = {
			"ImagePath": cell.image_path,
			"Exposure": 1
		}
	
	return dict
