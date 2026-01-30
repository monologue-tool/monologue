extends VBoxContainer

@onready var preview_texture: Sprite2D = %ViewportSprite
@onready var preview_anim: Node2D = %ASContainer
@onready var preview_camera: Camera2D = %ViewportCamera
@onready
var zoom_slider: HSlider = $MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/HSlider


func update_preview(texture: Texture2D = Texture2D.new()) -> void:
	if preview_texture:
		preview_texture.texture = texture

		preview_anim.hide()
		preview_texture.show()


func update_animation(sprites: Array) -> void:
	_clear_anim()
	for sprite in sprites:
		var animated_sprite := AnimatedSprite2D.new()
		animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		animated_sprite.sprite_frames = sprite
		preview_anim.add_child(animated_sprite)

	preview_texture.hide()
	preview_anim.show()


func _clear_anim() -> void:
	for child in preview_anim.get_children():
		child.queue_free()


func update_offset(offset: Array) -> void:
	preview_camera.offset.x = -offset[0]
	preview_camera.offset.y = -offset[1]


func update_mirror(mirror: bool) -> void:
	preview_texture.flip_h = mirror
	for child_anim in preview_anim.get_children():
		child_anim.flip_h = mirror


func _on_h_slider_value_changed(value: float) -> void:
	preview_camera.zoom = Vector2(value, value)


func play_backwards() -> void:
	for animated_sprite: AnimatedSprite2D in preview_anim.get_children():
		animated_sprite.play_backwards("default")


func stop() -> void:
	for animated_sprite: AnimatedSprite2D in preview_anim.get_children():
		animated_sprite.stop()


func play() -> void:
	for animated_sprite: AnimatedSprite2D in preview_anim.get_children():
		animated_sprite.play("default")
