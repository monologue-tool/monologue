extends TextureRect

@onready var init_pos: Vector2 = position


func undisplay() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	(
		tween
		. tween_property(self, "position:x", -init_pos.x, .5)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_EXPO)
		. set_ease(Tween.EASE_OUT)
	)


func display() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", init_pos.x, .5).set_trans(Tween.TRANS_EXPO).set_ease(
		Tween.EASE_OUT
	)
