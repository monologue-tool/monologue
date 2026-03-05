extends Field

@onready var spin_box: SpinBox = %SpinBox


func _ready() -> void:
	spin_box.value_changed.connect(_on_value_changed)
	
	spin_box.prefix = settings.get("prefix", "")
	spin_box.suffix = settings.get("suffix", "")
	spin_box.min_value = settings.get("min_value", 0.0)
	spin_box.max_value = settings.get("max_value", 100.0)
	spin_box.step = settings.get("step", 1.0)
	spin_box.page = settings.get("page", 0.0)
	spin_box.exp_edit = settings.get("exp_edit", false)
	spin_box.rounded = settings.get("rounded", true)
	spin_box.allow_greater = settings.get("allow_greater", true)
	spin_box.allow_lesser = settings.get("allow_lesser", true)


func set_value(value: Variant) -> void:
	spin_box.value = value


func get_value() -> Variant:
	return spin_box.value


func set_editable(is_editable: bool) -> void:
	spin_box.editable = is_editable


func _on_value_changed(_value: float) -> void:
	emit_value_committed(get_value())
