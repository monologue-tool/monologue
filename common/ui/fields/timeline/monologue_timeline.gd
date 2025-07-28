class_name MonologueAnimationTimeline extends MonologueField

const IMAGE = ["*.bmp,*.jpg,*.jpeg,*.png,*.svg,*.webp;Image Files"]
const DEFAULT_LAYER_NAME: String = "Layer %s"

var filters: Array = ["*.bmp", "*.jpg", "*.jpeg", "*.png", "*.svg", "*.webp"]

@onready var layer_vbox := %LayerVBox
@onready var layer_timeline_vbox := %LayerTimelineVBox
@onready var cell_number_hbox := %CellNumberHBox
@onready var fps_spinbox := %FpsSpinBox
@onready var layer_container := %LayerContainer
@onready var import_frame_button := %ImportFrameButton

@onready var layer := preload("res://common/ui/fields/timeline/timeline_layer.tscn")
@onready var layer_timeline := preload("res://common/ui/fields/timeline/timeline_cell_layer.tscn")
@onready var cell_number := preload("res://common/ui/fields/timeline/timeline_cell_number.tscn")
@onready var placement_indicator := preload("res://common/ui/horizontal_placement_indicator.tscn")

var cell_count: int = 1
var base_path: String
var selected_cell_idx: int = -1
var selected_cell_layer_idx: int = -1
var current_indicator: Control
var selected_layer: Layer
var preview_section

var fps: float = 12.0


func _process(_delta: float) -> void:
	if current_indicator == null:
		return
	var indicator_dist: float = current_indicator.global_position.y - get_global_mouse_position().y
	var layer_height: float = get_layer_height()
	var layer_dist: float = (
		get_global_mouse_position().y - (selected_layer.global_position.y + layer_height / 2.0)
	)
	var indicator_index: int = current_indicator.get_index()

	current_indicator.show()
	if indicator_dist >= layer_height / 2.0:
		layer_vbox.move_child(current_indicator, indicator_index - 1)
	elif indicator_dist <= -layer_height / 2.0:
		layer_vbox.move_child(current_indicator, indicator_index + 1)
	elif abs(layer_dist) < layer_height:
		current_indicator.hide()


func _clear() -> void:
	cell_count = 1
	for child in layer_vbox.get_children():
		child.queue_free()
	for child in layer_timeline_vbox.get_children():
		child.queue_free()


func propagate(value: Variant) -> void:
	super.propagate(value)
	_from_dict(value)


func use_custom_field_label() -> bool:
	return true


func _from_dict(dict: Dictionary) -> void:
	_clear()
	cell_count = dict.get("FrameCount", 1)
	fps_spinbox.value = dict.get("Fps", 12)
	selected_cell_idx = -1
	selected_cell_layer_idx = -1

	var default_layer_data := [
		{"LayerName": DEFAULT_LAYER_NAME % 1, "Frames": {0: {"ImagePath": "", "Exposure": 1}}}
	]

	for layer_data in dict.get("Layers", default_layer_data):
		var new_layer: Layer = add_timeline()
		new_layer.timeline_label.text = layer_data.get("LayerName", "Layer")
		layer_timeline_vbox.get_children().back()._from_dict(layer_data)

	_update_cell_number()
	_update_preview.call_deferred()


func _to_dict() -> Dictionary:
	var dict: Dictionary = {"Fps": fps, "FrameCount": cell_count, "Layers": []}
	var layers: Array = get_all_layers()

	for l: Layer in layers:
		var layer_idx: int = layers.find(l)
		var l_timeline: LayerTimeline = layer_timeline_vbox.get_child(layer_idx)
		dict["Layers"].append({"LayerName": l.timeline_label.text, "Frames": l_timeline._to_dict()})
	return dict


func get_all_layers() -> Array:
	var layers: Array = []
	for child in layer_vbox.get_children():
		if child is not Layer or child.is_queued_for_deletion():
			continue
		layers.append(child)

	return layers


func get_cell_width() -> int:
	return layer_container.cell_width


func get_layer_height() -> int:
	return get_all_layers()[0].size.y


func add_cell() -> void:
	cell_count += 1
	_update_cell_number()


func add_timeline() -> Layer:
	var new_layer: Layer = layer.instantiate()
	var new_layer_timeline: LayerTimeline = layer_timeline.instantiate()
	new_layer_timeline.timeline = self

	layer_vbox.add_child(new_layer)
	layer_timeline_vbox.add_child(new_layer_timeline)

	new_layer.timeline_label.text = DEFAULT_LAYER_NAME % layer_vbox.get_child_count()
	new_layer.hover_button.connect("button_down", _on_layer_button_down.bind(new_layer))
	new_layer.hover_button.connect("button_up", _on_layer_button_up.bind(new_layer))
	new_layer.delete_button_pressed.connect(_on_layer_delete_button_pressed.bind(new_layer))
	new_layer_timeline.connect("timeline_updated", _on_timeline_updated.bind(new_layer_timeline))

	_update_preview()

	return new_layer


func _update_cell_number() -> void:
	for cell in cell_number_hbox.get_children():
		cell.queue_free()
	for i in range(cell_count):
		var new_cell := cell_number.instantiate()
		new_cell.cell_number = i + 1
		new_cell.custom_minimum_size.x = get_cell_width()
		cell_number_hbox.add_child(new_cell)


func _update_preview() -> void:
	if layer_timeline_vbox == null:
		return
	var sprites: Array = []
	var layers: Array[Node] = layer_timeline_vbox.get_children()
	layers.reverse()
	for child_timeline: LayerTimeline in layers:
		sprites.append(child_timeline._to_sprite_frames())
	preview_section.update_animation(sprites)


func _on_timeline_updated(_layer_timeline: LayerTimeline) -> void:
	_update_field.call_deferred()


func _update_field() -> void:
	_update_preview()
	field_updated.emit(_to_dict())


func _on_btn_add_cell_pressed() -> void:
	add_cell()
	_update_field.call_deferred()


func _on_btn_add_layer_pressed() -> void:
	add_timeline()
	_update_field.call_deferred()


func _on_import_frame_button_pressed() -> void:
	if selected_cell_idx <= -1 and selected_cell_layer_idx <= -1:
		return
	GlobalSignal.emit("open_files_request", [_on_files_selected, IMAGE, base_path.get_base_dir()])


func get_selected_cell() -> Variant:
	if selected_cell_idx <= -1 and selected_cell_layer_idx <= -1:
		return null

	var s_layer_timeline: LayerTimeline = (
		layer_timeline_vbox.get_children()[selected_cell_layer_idx]
	)
	return s_layer_timeline.get_all_cells()[selected_cell_idx]


func _on_files_selected(paths: Array) -> void:
	if selected_cell_idx <= -1 and selected_cell_layer_idx <= -1:
		return

	var first_path: String = paths.pop_front()
	get_selected_cell().image_path = Path.absolute_to_relative(first_path, base_path)
	get_selected_cell()._update()

	var selected_cell_layer: LayerTimeline = layer_timeline_vbox.get_child(selected_cell_layer_idx)
	var first_frame_duration: int = int(selected_cell_layer.get_frame_duration(selected_cell_idx))
	var idx: int = 0
	for path in paths:
		idx += 1
		var cell: TimelineCell = selected_cell_layer.add_cell(
			Path.absolute_to_relative(path, base_path)
		)
		selected_cell_layer.hbox.move_child(cell, selected_cell_idx + idx * first_frame_duration)

		for i in range(first_frame_duration - 1):
			var exp_cell: TimelineCell = selected_cell_layer.add_cell()
			exp_cell.is_exposure = true
			selected_cell_layer.hbox.move_child(
				exp_cell, selected_cell_idx + idx * first_frame_duration + i + 1
			)
			exp_cell._update()

	_update_field.call_deferred()


func cell_selected(s_cell: TimelineCell, s_timeline: LayerTimeline) -> void:
	var cell_idx: int = s_timeline.get_all_cells().find(s_cell)
	var timeline_idx: int = layer_timeline_vbox.get_children().find(s_timeline)
	selected_cell_idx = cell_idx
	selected_cell_layer_idx = timeline_idx
	sub_select(cell_idx, timeline_idx)
	if not s_cell.is_exposure:
		import_frame_button.disabled = false


func cell_deselected() -> void:
	var disable_func: Callable = func() -> void:
		if import_frame_button.has_focus():
			return
		import_frame_button.disabled = true
		selected_cell_idx = -1
		selected_cell_layer_idx = -1
		sub_select(-1, -1)
	disable_func.call_deferred()


func sub_select(col_idx: int, row_idx: int) -> void:
	var deselect: bool = col_idx <= -1 and row_idx <= -1
	for cell in cell_number_hbox.get_children():
		cell.reset_style()
	var timeline_idx: int = 0
	for t: LayerTimeline in layer_timeline_vbox.get_children():
		var cell_idx: int = 0
		for cell in t.get_all_cells():
			if cell_idx == col_idx and not deselect:
				cell.sub_select()
				if row_idx != timeline_idx:
					cell.lose_focus()
			else:
				cell.reset_style()
				cell.lose_focus()
			cell_idx += 1
		timeline_idx += 1
	if not deselect:
		cell_number_hbox.get_child(col_idx).sub_select()


func _on_layer_scroll_container_gui_input(_event: InputEvent) -> void:
	%LayerTimelineScrollContainer.scroll_vertical = %LayerScrollContainer.scroll_vertical


func _on_layer_timeline_scroll_container_gui_input(_event: InputEvent) -> void:
	%LayerScrollContainer.scroll_vertical = %LayerTimelineScrollContainer.scroll_vertical


func _on_layer_button_down(target_layer: Layer) -> void:
	var layer_idx: int = get_all_layers().find(target_layer)
	current_indicator = placement_indicator.instantiate()
	layer_vbox.add_child(current_indicator)
	layer_vbox.move_child(current_indicator, layer_idx + 1)
	selected_layer = target_layer


func _on_layer_button_up(target_layer: Layer) -> void:
	selected_layer = null
	if not current_indicator.visible:
		current_indicator.free()
		current_indicator = null
		return

	var new_placement_idx: int = current_indicator.get_index()
	var layer_idx: int = get_all_layers().find(target_layer)
	var t_layer_timeline: LayerTimeline = layer_timeline_vbox.get_child(layer_idx)
	layer_vbox.move_child(target_layer, new_placement_idx)
	current_indicator.free()
	current_indicator = null
	layer_timeline_vbox.move_child(t_layer_timeline, get_all_layers().find(target_layer))
	_update_field.call_deferred()


func _on_layer_delete_button_pressed(target_layer: Layer) -> void:
	var layer_idx: int = get_all_layers().find(target_layer)
	var t_layer_timeline: LayerTimeline = layer_timeline_vbox.get_child(layer_idx - 1)
	t_layer_timeline.queue_free()
	target_layer.queue_free()
	_update_field.call_deferred()


func _on_fps_spin_box_value_changed(value: float) -> void:
	if value != fps:
		fps = value
		_update_field.call_deferred()


func _on_play_backwards_button_pressed() -> void:
	preview_section.play_backwards()


func _on_skip_backward_button_pressed() -> void:
	pass  # Replace with function body.


func _on_stop_button_pressed() -> void:
	preview_section.stop()


func _on_skip_forward_button_pressed() -> void:
	pass  # Replace with function body.


func _on_play_button_pressed() -> void:
	preview_section.play()
