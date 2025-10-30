## Text box display for dialogue playback.
##
## Manages dialogue text display with auto-scrolling and typing effects.
## Displays speaker names and dialogue text progressively.
extends VBoxContainer

## Reference to the scroll container holding text boxes.
@onready var scroll_container = %ScrollContainer

## Reference to the vertical scrollbar for auto-scroll.
@onready var scroll_bar: ScrollBar = scroll_container.get_v_scroll_bar()

## Preloaded text box scene for dialogue lines.
@onready var text_box = preload("res://scenes/run/common/text_box/text_box.tscn")

## Currently active text box for displaying text.
var current_text_box: RichTextLabel

## Current dialogue text being displayed.
var text = ""

## Speaker name to display.
var speaker_display = ""

## Speed of text typing effect.
var text_speed = 5

## Whether text display is complete.
var complete: bool = false

## Whether to display text.
var _display: bool = false

## Tick counter for text typing animation.
var tick = 0


## Initializes the text box and connects signals.
func _ready():
	scroll_bar.connect("changed", handle_scrollbar_changed)
	reset()
	update()


func handle_scrollbar_changed():
	scroll_container.scroll_vertical = scroll_bar.max_value


func _process(delta):
	if complete:
		pass

	if not _display:
		return

	tick += 1

	if text_speed < 0 or current_text_box.visible_ratio >= 1:
		current_text_box.visible_characters = -1
		_display = false
		complete = true
		return

	current_text_box.visible_characters += text_speed * delta * 60


func reset():
	append_text_box()
	current_text_box.visible_characters = 0
	current_text_box.visible_ratio = 0
	_display = false
	complete = false
	tick = 0


func update():
	current_text_box.text = text


func display():
	_display = true


func append_text_box():
	if current_text_box:
		current_text_box.remove_theme_color_override("default_color")
		current_text_box.add_theme_color_override("default_color", Color("656565"))

	var new_text_box = text_box.instantiate()
	add_child(new_text_box)
	current_text_box = new_text_box

	current_text_box.grab_click_focus()