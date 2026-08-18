class_name TooltipLabel extends Label


func _ready() -> void:
	Tooltip.tooltip_update.connect(_on_tooltip_update)


func _on_tooltip_update() -> void:
	if not Tooltip.text:
		await get_tree().create_timer(0.1).timeout

	text = Tooltip.text.replace("\n", " ")
