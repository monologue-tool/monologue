## Splash screen displayed while loading the main application scene.
##
## Shows an animated sprite and loads the next scene in a background thread
## to prevent blocking. Transitions to the loaded scene once ready.
extends Control

## Path to the scene file to load in the background.
@export_file var load_scene: String

## Reference to the animated sprite displayed during loading.
@onready var sprite = $AnimatedSprite2D


## Initializes the splash screen and starts loading the next scene.
func _ready() -> void:
	ResourceLoader.load_threaded_request(load_scene)
	item_rect_changed.connect(_on_item_rect_changed)
	_on_item_rect_changed()


## Checks loading status and transitions when complete.
##
## Monitors the threaded loading progress and changes to the loaded scene
## after playing a blink animation.
func _process(_delta: float) -> void:
	var status := ResourceLoader.load_threaded_get_status(load_scene)

	if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
		var scene := ResourceLoader.load_threaded_get(load_scene)

		sprite.play("blink")
		await sprite.animation_finished

		get_tree().change_scene_to_packed(scene)


## Centers the sprite when the viewport size changes.
func _on_item_rect_changed() -> void:
	var vp: Rect2 = get_viewport_rect()
	sprite.global_position = vp.size / 2
