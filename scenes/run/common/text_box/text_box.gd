extends VBoxContainer

@onready var scroll_container = %ScrollContainer
@onready var scroll_bar: ScrollBar = scroll_container.get_v_scroll_bar()

@onready var text_box = preload("res://scenes/run/common/text_box/text_box.tscn")

var current_text_box: RichTextLabel

var text = ""
var speaker_display = ""
var text_speed = 5
var complete: bool = false
var _display: bool = false

var tick = 0


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