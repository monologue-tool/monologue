class_name EaseField extends Field

@onready var spin_box_x1: SpinBox = %SpinBoxX1
@onready var spin_box_y1: SpinBox = %SpinBoxY1
@onready var spin_box_x2: SpinBox = %SpinBoxX2
@onready var spin_box_y2: SpinBox = %SpinBoxY2
@onready var background_panel: PanelContainer = %BackgroundPanel
@onready var ratio: AspectRatioContainer = %AspectRatioContainer
@onready var path: Path2D = %Path2D
@onready var cp1: EaseControlPoint = %CP1
@onready var cp2: EaseControlPoint = %CP2

var _is_updating: bool = false
var _is_moving_cp: bool = false


func _ready() -> void:
	for sb: SpinBox in [spin_box_x1, spin_box_y1, spin_box_x2, spin_box_y2]:
		sb.value_changed.connect(_on_spin_box_value_changed)
	item_rect_changed.connect(_on_item_rect_changed)
	cp1.moved.connect(_on_cp_moved)
	cp1.button_up.connect(_on_cp_up)
	cp2.moved.connect(_on_cp_moved)
	cp2.button_up.connect(_on_cp_up)


func set_value(value: Variant) -> void:
	if not value is Array or value.size() < 4:
		return

	_is_updating = true
	spin_box_x1.value = value[0]
	spin_box_y1.value = value[1]
	spin_box_x2.value = value[2]
	spin_box_y2.value = value[3]
	_is_updating = false
	_update_ui.call_deferred()


func get_value() -> Variant:
	return [spin_box_x1.value, spin_box_y1.value, spin_box_x2.value, spin_box_y2.value]


func set_editable(is_editable: bool) -> void:
	cp1.movable = is_editable
	cp2.movable = is_editable
	for spin_box: SpinBox in [spin_box_x1, spin_box_x2, spin_box_y1, spin_box_y2]:
		spin_box.editable = is_editable


func prefers_vertical_layout(_settings: Dictionary) -> bool:
	return true


func _on_spin_box_value_changed(_value: float) -> void:
	if _is_updating:
		return

	_update_ui()
	emit_value_committed(get_value())


func _update_values() -> void:
	var canvas_size: float = background_panel.size.x
	cp1.position.x = clamp(cp1.position.x, -cp1.size.x / 2, canvas_size - cp1.size.x / 2)
	cp2.position.x = clamp(cp2.position.x, -cp2.size.x / 2, canvas_size - cp2.size.x / 2)

	var cp1_pos: Vector2 = cp1.position + cp1.size / 2
	var cp2_pos: Vector2 = cp2.position + cp2.size / 2
	var p1: Vector2 = (Vector2(cp1_pos.x, -cp1_pos.y) / canvas_size) + Vector2(0.0, 1.0)
	var p2: Vector2 = (Vector2(cp2_pos.x, -cp2_pos.y) / canvas_size) + Vector2(0.0, 1.0)

	spin_box_x1.value = p1.x
	spin_box_y1.value = p1.y
	spin_box_x2.value = p2.x
	spin_box_y2.value = p2.y


func _update_ui() -> void:
	var canvas_size: float = background_panel.size.x
	if canvas_size <= 0.0:
		return
	var handles: Array = get_value()
	var curve: Curve2D = path.curve
	var p1: Vector2 = Vector2(handles[0], -handles[1]) * canvas_size
	var p2: Vector2 = Vector2(handles[2] - 1.0, 1.0 - handles[3]) * canvas_size
	curve.set_point_out(0, p1)
	curve.set_point_in(1, p2)
	if not _is_moving_cp:
		var cp1_pos: Vector2 = Vector2(handles[0], 1.0 - handles[1]) * canvas_size
		var cp2_pos: Vector2 = Vector2(handles[2], -handles[3] + 1.0) * canvas_size
		cp1.position = cp1_pos - cp1.size / 2
		cp2.position = cp2_pos - cp2.size / 2
	background_panel.queue_redraw()


func _on_item_rect_changed() -> void:
	_update_ui()


func _on_cp_moved() -> void:
	_is_moving_cp = true
	_is_updating = true
	_update_values()
	_update_ui()
	_is_updating = false


func _on_cp_up() -> void:
	emit_value_committed(get_value())
