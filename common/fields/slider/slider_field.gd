extends Field

@onready var slider: HSlider = %Slider
@onready var spin_box: SpinBox = %SpinBox

var _is_updating: bool = false


func _ready() -> void:
	slider.value_changed.connect(_on_slider_value_changed)
	slider.drag_ended.connect(_on_slider_drag_ended)
	spin_box.value_changed.connect(_on_spin_box_value_changed)

	for control: Range in [slider, spin_box]:
		control.min_value = settings.get("min_value", 0.0)
		control.max_value = settings.get("max_value", 100.0)
		control.step = settings.get("step", 1.0)
		control.page = settings.get("page", 0.0)
		control.exp_edit = settings.get("exp_edit", false)
		control.rounded = settings.get("rounded", false)
		control.allow_greater = settings.get("allow_greater", false)
		control.allow_lesser = settings.get("allow_lesser", false)
	spin_box.prefix = settings.get("prefix", "")
	spin_box.suffix = settings.get("suffix", "")


func set_value(value: Variant) -> void:
	slider.value = value
	spin_box.value = value


func get_value() -> Variant:
	return slider.value


func set_editable(is_editable: bool) -> void:
	slider.editable = is_editable
	spin_box.editable = is_editable


func _on_slider_value_changed(value: float) -> void:
	_is_updating = true
	spin_box.value = value
	_is_updating = false


func _on_slider_drag_ended(value: float) -> void:
	if _is_updating:
		return

	_is_updating = true
	spin_box.value = value
	_is_updating = false
	emit_value_committed(get_value())


func _on_spin_box_value_changed(value: float) -> void:
	if _is_updating:
		return

	_is_updating = true
	slider.value = value
	_is_updating = false
	emit_value_committed(get_value())
