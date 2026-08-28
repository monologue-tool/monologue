class_name Notification extends PanelContainer

const MINIMUM_TIME: float = .75
const NOTIFICATION_TIME: float = 3.0

const _color_dict: Dictionary[Log.Levels, Color] = {
	Log.Levels.DEBUG: Color("2F7AEA"),
	Log.Levels.INFO: Color("77e97b"),
	Log.Levels.WARN: Color("EC9344"),
	Log.Levels.ERROR: Color("af4041"),
	Log.Levels.FATAL: Color("af4041"),
}

@onready var label: Label = %Label
@onready var icon_rect: TextureRect = %Icon
@onready var timer: Timer = %Timer

func _ready() -> void:
	Log.broadcast_message.connect(_on_broadcast_message)
	
	timer.wait_time = NOTIFICATION_TIME
	timer.timeout.connect(_on_timer_timeout)
	hide()


func _on_broadcast_message(message: String, level: Log.Levels) -> void:
	if not timer.is_stopped() and NOTIFICATION_TIME - timer.time_left > MINIMUM_TIME:
		return
	
	var icon: DPITexture = DPITexture.create_from_string("""
		<svg width="21" height="18" viewBox="0 0 21 18" fill="none" xmlns="http://www.w3.org/2000/svg">
		<path d="M0 2C0 0.895432 0.89543 0 2 0H19C20.1046 0 21 0.89543 21 2V13.6C21 14.7046 20.1046 15.6 19 15.6H3.96365C3.54251 15.6 3.13213 15.7329 2.79098 15.9799L0 18V11.4L0 2Z" fill="#%s"/>
		<path d="M9.24807 3.98456L9.87597 9.00772C9.94682 9.5746 10.4287 10 11 10C11.5713 10 12.0532 9.5746 12.124 9.00772L12.7519 3.98456C12.8837 2.93077 12.062 2 11 2C9.93802 2 9.11635 2.93077 9.24807 3.98456Z" fill="#161616"/>
		<circle cx="11" cy="12.5" r="1.5" fill="#161616"/>
		</svg>
	""" % _color_dict[level].to_html(false))
	icon_rect.texture = icon
	
	label.text = " ".join(message.split(" ").slice(1))
	
	remove_theme_stylebox_override(&"panel")
	var sb: StyleBoxFlat = get_theme_stylebox(&"panel").duplicate()
	sb.bg_color = sb.bg_color.blend(Color(_color_dict[level], 0.1))
	add_theme_stylebox_override(&"panel", sb)
	
	show()
	timer.start()


func _on_timer_timeout() -> void:
	hide()
