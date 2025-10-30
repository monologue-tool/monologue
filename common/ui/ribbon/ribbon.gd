extends Control

@onready var animation_player = $AnimationPlayer


func _on_animation_finished(_animation_name):
	queue_free()


func _on_timeout():
	animation_player.play("disappear")
