extends ColorRect

@export var square_scale: float = 1.0


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var square_size: float = 5.0 * square_scale

	for x in range(0, size.x, square_size):
		for y in range(0, size.y, square_size):
			var rect_color: Color = Color("c0c0c0")
			if (x % 2 and y % 2) or (not (x % 2) and not (y % 2)):
				rect_color = Color("808080")
			var rect := Rect2(x, y, square_size, square_size)
			draw_rect(rect, rect_color)
