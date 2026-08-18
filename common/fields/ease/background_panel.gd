## The grid, the curve, and a ball that shows what the curve does to time.
extends PanelContainer

@export_range(0, 20) var line_count: int = 3
@export var ball_speed: float = 1.0

var _ball_progress: float = 0.0
var _ball_direction: int = 1

@onready var path: Path2D = %Path2D
@onready var cp1: EaseControlPoint = %CP1
@onready var cp2: EaseControlPoint = %CP2


func _ready() -> void:
	item_rect_changed.connect(_on_item_rect_changed)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return

	_ball_progress += ball_speed * delta * _ball_direction
	if _ball_progress > 1.0 or _ball_progress < 0.0:
		_ball_direction *= -1
		_ball_progress = clampf(_ball_progress, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	for i: int in range(line_count):
		var line_x: float = (size.x / (line_count + 1)) * (i + 1)
		draw_line(Vector2(line_x, 0), Vector2(line_x, size.y), Color("ffffff3f"), 1.0)
		var line_y: float = (size.y / (line_count + 1)) * (i + 1)
		draw_line(Vector2(0, line_y), Vector2(size.x, line_y), Color("ffffff3f"), 1.0)

	var points: PackedVector2Array = path.curve.tessellate()
	draw_polyline(points, Color.WHITE, 1.0, true)

	draw_dashed_line(cp1.position + cp1.size / 2, Vector2(0, size.y), Color("ffffff3f"), 1.0, 5.0)
	draw_dashed_line(cp2.position + cp2.size / 2, Vector2(size.x, 0), Color("ffffff3f"), 1.0, 5.0)
	draw_dashed_line(Vector2(0, size.y), Vector2(size.x, 0), Color("ffffff3f"), 1.0, 5.0)

	# Time runs along the bar at a constant rate; the ball sits at what the curve makes of it.
	draw_circle(
		Vector2(_eased_at(points, _ball_progress) * size.x, size.y * 0.5),
		12.0,
		Color("ffffff3f")
	)


## What the curve makes of [param t], both in 0..1.
##
## Looked up by x, not walked along the curve: on an easing curve x is time and y is the
## value it produces, and sampling by distance travelled matches neither. Read off the
## polyline just drawn, which is monotonic in x for any curve the handles can make.
func _eased_at(points: PackedVector2Array, t: float) -> float:
	if points.size() < 2 or size.x <= 0.0 or size.y <= 0.0:
		return t

	var target: float = t * size.x
	for i: int in range(1, points.size()):
		var before: Vector2 = points[i - 1]
		var after: Vector2 = points[i]
		if after.x < target:
			continue

		var span: float = after.x - before.x
		var along: float = 0.0 if span <= 0.0 else (target - before.x) / span
		# The curve runs bottom-left to top-right, so y counts down as the value goes up.
		return 1.0 - (lerpf(before.y, after.y, along) / size.y)

	return 1.0 - (points[points.size() - 1].y / size.y)


func _on_item_rect_changed() -> void:
	path.position = Vector2.ZERO
	path.curve.set_point_position(0, Vector2(0, size.y))
	path.curve.set_point_position(1, Vector2(size.x, 0))
