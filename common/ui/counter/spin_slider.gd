## A number that is both a slider and an input.
##
## Drag across it to change the value, click without dragging to type one. A bounded
## number fills proportionally behind the text. An unbounded one just drags.
class_name SpinSlider extends Control

signal value_changing(new_value: float)
## Emitted once the user is done: drag released, Enter pressed, or focus lost.
signal value_submitted(new_value: float)

## How far the pointer may travel before a click counts as a drag instead.
const DRAG_THRESHOLD: float = 4.0
## Value steps crossed per pixel of travel.
const STEPS_PER_PIXEL: float = 0.25
## Multiplier applied while Shift is held, for placing a value exactly.
const FINE_FACTOR: float = 0.1
const MIN_HEIGHT: int = 26

var value: float = 0.0

var _minimum: float = 0.0
var _maximum: float = 0.0
var _step: float = 1.0
var _rounded: bool = false
var _bounded: bool = false
var _prefix: String = ""
var _suffix: String = ""
var _editable: bool = true

const ARROW_WIDTH: float = 16.0

var _is_dragging: bool = false
var _drag_position: Vector2 = Vector2.ZERO
var _travelled: float = 0.0
var _line_edit: LineEdit
var _is_hovered: bool = false


func _ready() -> void:
	custom_minimum_size.y = MIN_HEIGHT
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_CLICK
	mouse_entered.connect(_on_hover_changed.bind(true))
	mouse_exited.connect(_on_hover_changed.bind(false))
	_build_line_edit()


func _on_hover_changed(is_hovered: bool) -> void:
	_is_hovered = is_hovered
	queue_redraw()


## Bounded only when both ends were given. A number with no declared range drags freely.
func configure(settings: Dictionary) -> void:
	_minimum = float(settings.get(PropertySettings.KEY_MIN_VALUE, 0.0))
	_maximum = float(settings.get(PropertySettings.KEY_MAX_VALUE, 0.0))
	_bounded = (
		settings.has(PropertySettings.KEY_MIN_VALUE)
		and settings.has(PropertySettings.KEY_MAX_VALUE)
		and _maximum > _minimum
	)
	_step = maxf(float(settings.get(PropertySettings.KEY_STEP, 1.0)), 0.0001)
	_rounded = settings.get(PropertySettings.KEY_ROUNDED, false) == true
	_prefix = str(settings.get(PropertySettings.KEY_PREFIX, ""))
	_suffix = str(settings.get(PropertySettings.KEY_SUFFIX, ""))
	set_value(value)


func is_bounded() -> bool:
	return _bounded


func set_editable(is_editable: bool) -> void:
	_editable = is_editable
	mouse_default_cursor_shape = (
		Control.CURSOR_HSIZE if is_editable else Control.CURSOR_ARROW
	)
	if not is_editable and _line_edit.visible:
		_close_editor(false)
	queue_redraw()


func get_display_text() -> String:
	var body: String = str(int(round(value))) if _rounded else String.num(value, _decimals())
	return "%s%s%s" % [_prefix, body, _suffix]


## Clamps to the declared range and step, then redraws. Announces nothing.
func set_value(new_value: float) -> void:
	value = _clamp(new_value)
	queue_redraw()


func _clamp(raw: float) -> float:
	var result: float = snappedf(raw, _step)
	if _bounded:
		result = clampf(result, _minimum, _maximum)
	return round(result) if _rounded else result


func _decimals() -> int:
	if _step >= 1.0:
		return 0
	return clampi(int(ceil(-log(_step) / log(10.0))), 1, 4)


func _gui_input(event: InputEvent) -> void:
	if not _editable or _line_edit.visible:
		return

	if event is InputEventMouseButton:
		_handle_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _is_dragging:
		_handle_motion(event as InputEventMouseMotion)


func _handle_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		var step: int = _arrow_at(event.position)
		if step != 0:
			set_value(value + _step * step)
			value_submitted.emit(value)
			accept_event()
			return

		_is_dragging = true
		_drag_position = get_viewport().get_mouse_position()
		_travelled = 0.0
		accept_event()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	_is_dragging = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().warp_mouse(_drag_position)
	if _travelled < DRAG_THRESHOLD:
		_open_editor()
	else:
		value_submitted.emit(value)
	accept_event()


## -1 for the left arrow, 1 for the right, 0 for the body between them. The arrows only
## answer while they are drawn, which is on hover.
func _arrow_at(position: Vector2) -> int:
	if not _is_hovered or size.x < ARROW_WIDTH * 3.0:
		return 0
	if position.x <= ARROW_WIDTH:
		return -1
	if position.x >= size.x - ARROW_WIDTH:
		return 1
	return 0


func _handle_motion(event: InputEventMouseMotion) -> void:
	_travelled += absf(event.relative.x)
	if _travelled < DRAG_THRESHOLD:
		return

	var factor: float = FINE_FACTOR if event.shift_pressed else 1.0
	set_value(value + event.relative.x * STEPS_PER_PIXEL * _step * factor)
	value_changing.emit(value)
	accept_event()


func _build_line_edit() -> void:
	_line_edit = LineEdit.new()
	_line_edit.set_anchors_preset(Control.PRESET_FULL_RECT)
	_line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line_edit.select_all_on_focus = true
	_line_edit.hide()
	_line_edit.text_submitted.connect(_on_text_submitted)
	_line_edit.focus_exited.connect(_on_editor_focus_exited)
	# Escape is caught here rather than in _unhandled_key_input: the focused LineEdit
	# sees the key first and never lets it through.
	_line_edit.gui_input.connect(_on_editor_gui_input)
	add_child(_line_edit)


func _open_editor() -> void:
	_line_edit.text = String.num(value, _decimals()) if not _rounded else str(int(value))
	_line_edit.show()
	_line_edit.grab_focus()
	queue_redraw()


func _close_editor(commit: bool) -> void:
	if commit and _line_edit.text.is_valid_float():
		set_value(_line_edit.text.to_float())
	_line_edit.hide()
	queue_redraw()
	if commit:
		value_submitted.emit(value)


func _on_text_submitted(_text: String) -> void:
	_close_editor(true)


func _on_editor_focus_exited() -> void:
	if _line_edit.visible:
		_close_editor(true)


func _on_editor_gui_input(event: InputEvent) -> void:
	if _line_edit.visible and event.is_action_pressed("ui_cancel"):
		_close_editor(false)
		_line_edit.accept_event()


func _current_state() -> String:
	if not _editable:
		return "disabled"
	return "hover" if _is_hovered or _is_dragging else "normal"


func _draw() -> void:
	if _line_edit.visible:
		return

	var box: Rect2 = Rect2(Vector2.ZERO, size)
	draw_style_box(get_theme_stylebox(_current_state(), "SpinSlider"), box)

	if _bounded:
		_draw_fill(box)

	if _editable and _is_hovered and not _is_dragging:
		_draw_arrows(box)

	_draw_value(box)


## Clipped to the widget, so the box's rounded corners cut the fill.
func _draw_fill(box: Rect2) -> void:
	var filled: float = clampf(inverse_lerp(_minimum, _maximum, value), 0.0, 1.0)
	if is_zero_approx(filled):
		return

	var fill_box: Rect2 = Rect2(box.position, Vector2(box.size.x * filled, box.size.y))
	draw_style_box(get_theme_stylebox("fill", "SpinSlider"), fill_box)


## Shown only under the pointer, so a row of numbers stays quiet.
func _draw_arrows(box: Rect2) -> void:
	var color: Color = Color(get_theme_color("font_color", "SpinSlider"), 0.6)
	var decrease: Texture2D = get_theme_icon("decrease", "SpinSlider")
	var increase: Texture2D = get_theme_icon("increase", "SpinSlider")

	for icon: Texture2D in [decrease, increase]:
		if icon == null:
			continue
		var offset_x: float = (
			(ARROW_WIDTH - icon.get_width()) * 0.5
			if icon == decrease
			else box.size.x - ARROW_WIDTH + (ARROW_WIDTH - icon.get_width()) * 0.5
		)
		draw_texture(
			icon, Vector2(offset_x, (box.size.y - icon.get_height()) * 0.5), color
		)


func _draw_value(box: Rect2) -> void:
	var font: Font = get_theme_font("font", "SpinSlider")
	var font_size: int = get_theme_font_size("font_size", "SpinSlider")
	var text: String = get_display_text()
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var color: Color = get_theme_color(
		"font_color" if _editable else "font_disabled_color", "SpinSlider"
	)

	draw_string(
		font,
		Vector2(
			(box.size.x - text_size.x) * 0.5,
			(box.size.y + text_size.y) * 0.5 - font.get_descent(font_size)
		),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		color
	)
