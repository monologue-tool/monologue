extends Control

@export_file var load_scene: String

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	ResourceLoader.load_threaded_request(load_scene)
	item_rect_changed.connect(_on_item_rect_changed)
	_on_item_rect_changed()


func _process(_delta: float) -> void:
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(load_scene)

	if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
		var scene: PackedScene = ResourceLoader.load_threaded_get(load_scene)

		sprite.play("blink")
		await sprite.animation_finished

		get_tree().change_scene_to_packed(scene)


func _on_item_rect_changed() -> void:
	var vp: Rect2 = get_viewport_rect()
	sprite.global_position = vp.size / 2
