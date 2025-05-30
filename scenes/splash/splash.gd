extends Control


@export_file var load_scene: String
@export var min_display_time: float = 0.2
@export var after_blink_time: float = 0.5

@onready var timer = $tMinDisplayTime
@onready var title = $CenterContainer/TextureRect
@onready var eye = $CenterContainer/TextureRect/AnimatedSprite2D


func _ready() -> void:
	timer.start(min_display_time)
	ResourceLoader.load_threaded_request(load_scene)
	title.connect("item_rect_changed", _on_item_rect_changed)


func _process(_delta: float) -> void:
	var status := ResourceLoader.load_threaded_get_status(load_scene)
	
	if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED and timer.is_stopped():
		var scene := ResourceLoader.load_threaded_get(load_scene)
		
		eye.play("blink")
		await eye.animation_finished
		await get_tree().create_timer(after_blink_time).timeout
		
		get_window().unresizable = false
		get_tree().change_scene_to_packed(scene)


func _on_item_rect_changed() -> void:
	eye.global_position.x = title.position.x + 143
	eye.global_position.y = title.position.y + 40
