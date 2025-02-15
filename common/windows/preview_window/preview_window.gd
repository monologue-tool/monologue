extends MonologueWindow


func _ready() -> void:
	var version = ProjectSettings.get("application/config/version")
	var is_pre_release = version.split("-").size() > 1
	
	visible = is_pre_release
	grab_focus()
	
	super._ready()


func _on_button_pressed() -> void:
	hide()


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
