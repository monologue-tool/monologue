extends PanelContainer

@export_range(0, 20) var line_count: int = 3

@onready var path: Path2D = %Path2D
@onready var cp1: BezierControlPoint = %CP1
@onready var cp2: BezierControlPoint = %CP2


func _ready() -> void:
	item_rect_changed.connect(_on_item_rect_changed)


func _draw() -> void:
	for i: int in range(line_count):
		var line_x: float = (size.x/(line_count+1)) * (i+1)
		draw_line(Vector2(line_x, 0), Vector2(line_x, size.y), Color("ffffff3f"), 1.0)
		var line_y: float = (size.y/(line_count+1)) * (i+1)
		draw_line(Vector2(0, line_y), Vector2(size.x, line_y), Color("ffffff3f"), 1.0)
	
	var curve: Curve2D = path.curve
	var points: PackedVector2Array = curve.tessellate()
	draw_polyline(points, Color.WHITE, 1.0, true)
	
	draw_dashed_line(cp1.position + cp1.size/2, Vector2(0, size.y), Color("ffffff3f"), 1.0, 5.0)
	draw_dashed_line(cp2.position + cp2.size/2, Vector2(size.x, 0), Color("ffffff3f"), 1.0, 5.0)
	draw_dashed_line(Vector2(0, size.y), Vector2(size.x, 0), Color("ffffff3f"), 1.0, 5.0)


func _on_item_rect_changed() -> void:
	path.position = Vector2.ZERO
	path.curve.set_point_position(0, Vector2(0, size.y))
	path.curve.set_point_position(1, Vector2(size.x, 0))
