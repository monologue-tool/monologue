## Preview/pre-release warning window shown for development builds.
##
## Displays a warning for pre-release versions with a "do not show again" option.
## Automatically tracks version changes to show the warning for new versions.
extends MonologueWindow

## Reference to the "do not show" checkbox.
@export var dns_checkbox: CheckBox


## Initializes the window and determines if it should be shown.
##
## Checks version and user preferences to decide visibility.
func _ready() -> void:
	var version = ProjectSettings.get("application/config/version")
	var is_pre_release = version.split("-").size() > 1

	var do_not_show = App.preferences.get_value("Preview", "do_not_show", false)
	var last_version = App.preferences.get_value("Preview", "last_version", "")
	var is_new = version != last_version
	visible = is_pre_release and (not do_not_show or is_new)
	grab_focus()

	super._ready()


## Handles the close button press.
##
## Saves user preferences if "do not show" is checked and hides the window.
func _on_button_pressed() -> void:
	if dns_checkbox:
		var checked = dns_checkbox.button_pressed
		var version = ProjectSettings.get("application/config/version")
		App.preferences.set_value("Preview", "do_not_show", checked)
		App.preferences.set_value("Preview", "last_version", version)
		App.preferences.save(Constants.PREFERENCES_PATH)
	hide()


## Handles clicks on hyperlinks in the rich text label.
##
## Opens the clicked URL in the system's default browser.
## [br][br]
## [param meta] The clicked URL metadata.
func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))
