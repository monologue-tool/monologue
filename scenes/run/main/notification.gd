extends PanelContainer

const DEFAULT_TIME: float = 7.5

var tween: Tween

@onready var timeleft: PanelContainer = $VBoxContainer/TimeLeft
@onready var label: RichTextLabel = $VBoxContainer/MarginContainer/RichTextLabel


func _ready() -> void:
	hide()


func notify(text: String, tag: String, color: Color, time: float) -> void:
	var bb_parser: RichTextLabel = RichTextLabel.new()
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


func info(text: String, time: float = DEFAULT_TIME) -> void:
	notify(text, "INFO", Color("579144"), time)


func debug(text: String, time: float = DEFAULT_TIME) -> void:
	notify(text, "DEBUG", Color("5e8de6"), time)


func warn(text: String, time: float = DEFAULT_TIME) -> void:
	notify(text, "WARN", Color("e5b65e"), time)


func error(text: String, time: float = DEFAULT_TIME) -> void:
	notify(text, "ERROR", Color("d19c9d"), time)


func critical(text: String, time: float = DEFAULT_TIME) -> void:
	notify(text, "CRITICAL", Color("d19c9d"), time)
