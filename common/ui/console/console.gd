class_name Console extends PanelContainer

@onready var rtl: RichTextLabel = %Log


func _ready() -> void:
	Log.log_message.connect(_on_log_message)


func _on_log_message(_message: String, bbcode_message: String) -> void:
	rtl.append_text(bbcode_message)
	rtl.newline()


func _on_close_button_pressed() -> void:
	hide()
