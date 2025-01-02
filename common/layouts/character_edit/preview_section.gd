extends VBoxContainer


@onready var preview_texture: Sprite2D = %ViewportSprite
@onready var preview_camera: Camera2D = %ViewportCamera
@onready var zoom_slider: HSlider = $MarginContainer/PanelContainer/VBoxContainer/HBoxContainer/HSlider


func update_preview(texture: Variant = null, offset: Array = [0, 0]) -> void:
	preview_texture.texture = texture


func update_offset(offset: Array) -> void:
	preview_camera.offset.x = -offset[0]
	preview_camera.offset.y = -offset[1]


func _on_h_slider_value_changed(value: float) -> void:
	preview_camera.zoom = Vector2(value, value)
