class_name Notification extends PanelContainer

const MINIMUM_TIME: float = .75
const NOTIFICATION_TIME: float = 3.0

const _color_dict: Dictionary = {
	Log.Levels.DEBUG: Color("2F7AEA"),
	Log.Levels.INFO: Color("77e97b"),
	Log.Levels.WARN: Color("EC9344"),
	Log.Levels.ERROR: Color("af4041"),
	Log.Levels.FATAL: Color("af4041"),
}

@onready var label: Label = %Label
@onready var icon: TextureRect = %Icon
@onready var timer: Timer = %Timer

func _ready() -> void:
	Log.broadcast_message.connect(_on_broadcast_message)
	
	timer.wait_time = NOTIFICATION_TIME
	timer.timeout.connect(_on_timer_timeout)
	hide()


func _on_broadcast_message(message: String, level: Log.Levels) -> void:
	if not timer.is_stopped() and NOTIFICATION_TIME - timer.time_left > MINIMUM_TIME:
		return
	
	var new_icon: DPITexture = icon.texture.duplicate()
	new_icon.color_map[Color.WHITE] = _color_dict[level]
	icon.texture = new_icon
	
	label.text = " ".join(message.split(" ").slice(1))
	
	remove_theme_stylebox_override(&"panel")
	var sb: StyleBoxFlat = get_theme_stylebox(&"panel").duplicate()
	sb.bg_color = sb.bg_color.blend(Color(_color_dict[level], 0.1))
	add_theme_stylebox_override(&"panel", sb)
	
	show()
	timer.start()


func _on_timer_timeout() -> void:
	hide()
