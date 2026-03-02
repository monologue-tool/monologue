extends SplitContainer

var split_ratio: float = 0
var last_viewport_size: Vector2i


func _ready() -> void:
	if vertical:
		split_ratio = split_offset / size.y
	else:
		split_ratio = split_offset / size.x

	resized.connect(_on_resized)
	visibility_changed.connect(_on_resized)
	last_viewport_size = get_viewport_rect().size


func _on_resized() -> void:
	var new_viewport_size: Vector2i = get_viewport_rect().size
	if vertical:
		split_offset *= new_viewport_size.y / last_viewport_size.y
	else:
		split_offset *= new_viewport_size.x / last_viewport_size.x
	last_viewport_size = new_viewport_size
