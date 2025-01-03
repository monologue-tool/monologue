extends VBoxContainer


const IMAGE = ["*.bmp,*.jpg,*.jpeg,*.png,*.svg,*.webp;Image Files"]

var filters: Array = ["*.bmp", "*.jpg", "*.jpeg", "*.png", "*.svg", "*.webp"]

@onready var timeline := $TimelineContainer/Timeline
@onready var layer_vbox := %LayerVBox
@onready var layer_timeline_vbox := %LayerTimelineVBox
@onready var cell_number_hbox := %CellNumberHBox
@onready var preview_section := %PreviewSection
@onready var fps_spinbox := %FpsSpinBox

@onready var layer := preload("res://common/layouts/character_edit/layer.tscn")
@onready var layer_timeline := preload("res://common/layouts/character_edit/layer_timeline.tscn")
@onready var cell_number := preload("res://common/layouts/character_edit/cell_number.tscn")

var cell_count: int = 1
var base_path: String
var selected_cell: TimelineCell
var fps: int : get = _get_fps


func _get_fps() -> int:
	return fps_spinbox.value


func _ready() -> void:
	add_timeline()
	_update_cell_number()


func _from_dict(dict: Dictionary) -> void:
	_clear()
	cell_count = dict.get("FrameCount", 1)
	fps_spinbox.value = dict.get("Fps", 12)
	selected_cell = null
	
	var default_layer_data := [
		{
			"LayerName": "Layer 1", "Visible": true, "EditorLock": false,
			"Frames": { 0: { "ImagePath": "", "Exposure": 1 }}
		}
	]
	
	for layer_data in dict.get("Layers", default_layer_data):
		add_timeline()
		layer_vbox.get_children().back().timeline_label.text = layer_data.get("LayerName", "undefined")
		layer_timeline_vbox.get_children().back()._from_dict(layer_data)
	_update_cell_number()
	
	#preview_section.update_preview()
	_update_preview()
	


func _clear() -> void:
	cell_count = 1
	for child in layer_vbox.get_children():
		child.queue_free()
	for child in layer_timeline_vbox.get_children():
		child.queue_free()


func add_timeline() -> void:
	var new_layer := layer.instantiate()
	var new_layer_timeline: LayerTimeline = layer_timeline.instantiate()
	
	new_layer_timeline.timeline_section = self
	
	layer_vbox.add_child(new_layer)
	layer_timeline_vbox.add_child(new_layer_timeline)
	
	_update_preview()


func _update_cell_number() -> void:
	for cell in cell_number_hbox.get_children():
		cell.queue_free()
	
	for i in range(cell_count):
		var new_cell := cell_number.instantiate()
		new_cell.cell_number = i+1
		cell_number_hbox.add_child(new_cell)


func _update_preview() -> void:
	# Don't update if this function is called too early.
	if layer_timeline_vbox == null:
		return
	
	var sprites: Array = []
	for timeline in layer_timeline_vbox.get_children():
		sprites.append(timeline._to_sprite_frames())
	
	preview_section.update_animation(sprites)


func add_cell() -> void:
	cell_count += 1
	_update_cell_number()
	for t in layer_timeline_vbox.get_children():
		t.add_cell()

	_update_preview()

func _to_dict() -> Dictionary:
	var dict: Dictionary = {
		"Fps": fps,
		"FrameCount": cell_count,
		"Layers": []
	}
	
	for l: Layer in layer_vbox.get_children():
		var layer_idx: int = l.get_index()
		var l_timeline: LayerTimeline= layer_timeline_vbox.get_child(layer_idx)
		dict["Layers"].append({
			"LayerName": l.timeline_label.text,
			"Visible": true,
			"EditorLock": false,
			"Frames": l_timeline._to_dict()
		})
		
	return dict


func _on_btn_add_cell_pressed() -> void:
	add_cell()


func _on_btn_add_layer_pressed() -> void:
	add_timeline()


func _on_button_pressed() -> void:
	if selected_cell == null:
		return
	
	GlobalSignal.emit("open_file_request",
			[_on_file_selected, IMAGE, base_path.get_base_dir()])


func _on_file_selected(path: String) -> void:
	if selected_cell == null:
		return
	
	selected_cell.image_path = Path.absolute_to_relative(path, base_path)
	_update_preview()
