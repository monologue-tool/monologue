class_name Console extends PanelContainer

@onready var rtl: RichTextLabel = %Log


func _ready() -> void:
	EventBus.show_console.connect(_on_event_show_console)
	Log.log_message.connect(_on_log_message)

	visible = ConfigManager.get_config("show_console")


func _on_event_show_console(_visible: bool) -> void:
	visible = ConfigManager.get_config("show_console")


func _on_log_message(_message: String, bbcode_message: String) -> void:
	rtl.append_text(bbcode_message)
	rtl.newline()


func _on_close_button_pressed() -> void:
	ConfigManager.set_config("show_console", false)
	hide()
