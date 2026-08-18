extends PanelContainer


func _ready() -> void:
	EventBus.show_status_bar.connect(_on_show_status_bar)
	visible = ConfigManager.get_config("show_status_bar")


func _on_show_status_bar(_visible: bool) -> void:
	visible = ConfigManager.get_config("show_status_bar")
