extends TextureRect

@onready var init_pos = position


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


func display():
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", init_pos.x, .5).set_trans(Tween.TRANS_EXPO).set_ease(
		Tween.EASE_OUT
	)
