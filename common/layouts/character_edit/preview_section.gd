extends VBoxContainer


@onready var preview_texture: Sprite2D = %ViewportSprite
@onready var preview_anim: AnimatedSprite2D = %ViewportAnimatedSprite
@onready var preview_camera: Camera2D = %ViewportCamera
@onready var zoom_slider: HSlider = $MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/HSlider


func update_preview(texture: Texture2D = PlaceholderTexture2D.new()) -> void:
	if preview_texture:
		preview_texture.texture = texture
		
		preview_anim.hide()
		preview_texture.show()


func update_animation(sprite_frames: SpriteFrames) -> void:
	print(sprite_frames.get_frame_count("default"))
	preview_anim.sprite_frames = sprite_frames
	preview_anim.play("default")
	
	preview_texture.hide()
	preview_anim.show()


func update_offset(offset: Array) -> void:
	preview_camera.offset.x = -offset[0]
	preview_camera.offset.y = -offset[1]


func update_mirror(mirror: bool) -> void:
	preview_texture.flip_h = mirror
	preview_anim.flip_h = mirror


func _on_h_slider_value_changed(value: float) -> void:
	preview_camera.zoom = Vector2(value, value)
