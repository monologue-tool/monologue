extends MonologueWindow

@export var dns_checkbox: CheckBox


func _ready() -> void:
	# TODO
	EventBus.window_out.connect(hide)
	return
	#var version: Variant = ProjectSettings.get("application/config/version")
	#var is_pre_release: bool = version.split("-").size() > 1


#
#var do_not_show: Variant = App.preferences.get_value("Preview", "do_not_show", false)
#var last_version: Variant = App.preferences.get_value("Preview", "last_version", "")
#var is_new: bool = version != last_version
#visible = is_pre_release and (not do_not_show or is_new)
#grab_focus()
#
#super._ready()


func _on_button_pressed() -> void:
	# TODO
	if dns_checkbox and false:
		var checked: bool = dns_checkbox.button_pressed
		var version: Variant = ProjectSettings.get("application/config/version")
		App.preferences.set_value("Preview", "do_not_show", checked)
		App.preferences.set_value("Preview", "last_version", version)
		App.preferences.save(Constants.PREFERENCES_PATH)
	hide()


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
