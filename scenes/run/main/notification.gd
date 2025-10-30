## Notification panel for displaying timed messages during playback.
##
## Shows categorized notifications (info, debug, warn, error, critical) with
## color-coded tags and an animated countdown bar.
extends PanelContainer

## Default duration for notifications in seconds.
const DEFAULT_TIME = 7.5

## Current tween animation for the notification timer.
var tween: Tween

## Reference to the time remaining indicator panel.
@onready var timeleft = $VBoxContainer/TimeLeft

## Reference to the notification message label.
@onready var label = $VBoxContainer/MarginContainer/RichTextLabel


## Initializes the notification panel in hidden state.
func _ready():
	hide()


## Shows a notification with custom styling.
##
## [param text] The notification message text.
## [br][br]
## [param tag] The category tag (e.g., "INFO", "ERROR").
## [br][br]
## [param color] The color for the tag and timer bar.
## [br][br]
## [param time] Duration to display the notification.
func notify(text, tag, color, time):
	var bb_parser = RichTextLabel.new()
	bb_parser.parse_bbcode(text)
	bb_parser.get_parsed_text()
	print("[%s] %s" % [tag, bb_parser.get_parsed_text()])
	bb_parser.free()

	label.text = "[color=%s][%s][/color] %s" % [color.to_html(false), tag, text]
	timeleft.custom_minimum_size.x = size.x
	timeleft.get_theme_stylebox("panel").bg_color = color

	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(timeleft, "custom_minimum_size:x", 0, time)
	tween.tween_callback(hide)
	show()


## Shows an info-level notification in green.
func info(text: String, time = DEFAULT_TIME):
	notify(text, "INFO", Color("579144"), time)


## Shows a debug-level notification in blue.
func debug(text: String, time = DEFAULT_TIME):
	notify(text, "DEBUG", Color("5e8de6"), time)


## Shows a warning-level notification in yellow.
func warn(text: String, time = DEFAULT_TIME):
	notify(text, "WARN", Color("e5b65e"), time)


## Shows an error-level notification in red.
func error(text: String, time = DEFAULT_TIME):
	notify(text, "ERROR", Color("d19c9d"), time)


## Shows a critical-level notification in red.
func critical(text: String, time = DEFAULT_TIME):
	notify(text, "CRITICAL", Color("d19c9d"), time)
