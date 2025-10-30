## Character asset display with animated entrance and exit.
##
## Displays a character sprite that can slide in and out with tween animations.
extends TextureRect

## Initial position of the character asset.
@onready var init_pos = position


## Hides the character with a slide-out animation.
##
## Animates the character sliding out to the left.
func undisplay():
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	(
		tween
		. tween_property(self, "position:x", -init_pos.x, .5)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_EXPO)
		. set_ease(Tween.EASE_OUT)
	)


## Shows the character with a slide-in animation.
##
## Animates the character sliding in from the left to its initial position.
func display():
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", init_pos.x, .5).set_trans(Tween.TRANS_EXPO).set_ease(
		Tween.EASE_OUT
	)
