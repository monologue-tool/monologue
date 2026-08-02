## Edits a number. Shared by the `int` and `float` field types, which differ only by
## their declared step and by rounding.
extends Field

@onready var spin_slider: SpinSlider = %SpinSlider


func _ready() -> void:
	super._ready()
	spin_slider.value_changing.connect(_on_value_changing)
	spin_slider.value_submitted.connect(_on_value_submitted)


# Settings are read here, not in _ready(): binding is deferred, so per-property
# min/max/step only exist by the time _on_initialize() runs.
func _on_initialize() -> void:
	spin_slider.configure(settings)


func set_value(value: Variant) -> void:
	if not is_node_ready():
		await ready

	if value is String:
		spin_slider.set_value((value as String).to_float())
		return
	if value is bool:
		spin_slider.set_value(1.0 if value else 0.0)
		return
	if value is int or value is float:
		spin_slider.set_value(float(value))


func get_value() -> Variant:
	if settings.get(PropertySettings.KEY_ROUNDED, false) == true:
		return int(round(spin_slider.value))
	return spin_slider.value


func set_editable(is_editable: bool) -> void:
	spin_slider.set_editable(is_editable)


func _on_value_changing(_new_value: float) -> void:
	emit_value_changed(get_value())


func _on_value_submitted(_new_value: float) -> void:
	emit_value_committed(get_value())
