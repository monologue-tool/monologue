## A temporary notification ribbon with fade-out animation.
##
## Displays a temporary message that automatically disappears after a timeout
## and plays a fade-out animation before being freed.
extends Control

## Reference to the animation player for fade effects.
@onready var animation_player = $AnimationPlayer


## Frees the ribbon after the animation finishes.
func _on_animation_finished(_animation_name):
	queue_free()


## Starts the disappear animation when the timeout occurs.
func _on_timeout():
	animation_player.play("disappear")
