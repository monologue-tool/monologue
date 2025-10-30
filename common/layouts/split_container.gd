## A split container that maintains its split ratio when the viewport resizes.
##
## Extends SplitContainer to preserve the relative split position when the
## window or viewport size changes, preventing the split from jumping.
extends SplitContainer

## The ratio of the split offset relative to the container size.
var split_ratio: float = 0

## The last recorded viewport size for calculating resize deltas.
var last_viewport_size: Vector2i


## Initializes the split container and calculates the initial split ratio.
func _ready() -> void:
	if vertical:
		split_ratio = split_offset / size.y
	else:
		split_ratio = split_offset / size.x

	resized.connect(_on_resized)
	visibility_changed.connect(_on_resized)
	last_viewport_size = get_viewport_rect().size


## Handles resize events and maintains the split ratio.
##
## Adjusts the split_offset proportionally based on the viewport size change.
func _on_resized() -> void:
	var new_viewport_size: Vector2i = get_viewport_rect().size
	if vertical:
		split_offset *= new_viewport_size.y / last_viewport_size.y
	else:
		split_offset *= new_viewport_size.x / last_viewport_size.x
	last_viewport_size = new_viewport_size
