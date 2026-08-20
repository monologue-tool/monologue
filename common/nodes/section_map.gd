## A section node's preview graph thumbnail.
class_name SectionMap extends Control

const HEIGHT: float = 56.0
const MARK_SIZE: Vector2 = Vector2(9.0, 5.0)
const MARK_GAP: float = 1.0
const MIN_MARK: float = 1.0
const PADDING: float = 4.0
const MAX_MARKS: int = 60
const MIN_SCALE: float = 0.02
const MAX_SCALE: float = 0.10

var _marks: Array[Dictionary] = []
var _wires: Array[PackedVector2Array] = []
var _bounds: Rect2


static func of(section: StorylineDocument) -> SectionMap:
	if section == null:
		return null

	var map: SectionMap = SectionMap.new()
	map._read(section)
	if map._marks.is_empty():
		map.free()
		return null

	map.custom_minimum_size.y = HEIGHT
	map.mouse_filter = Control.MOUSE_FILTER_PASS
	map.clip_contents = true
	return map


func _read(section: StorylineDocument) -> void:
	var placed: Dictionary[String, Vector2] = {}

	for node: InspectableNode in section.nodes:
		if placed.size() >= MAX_MARKS:
			break
		var at: Vector2 = _position_of(node)
		_bounds = Rect2(at, Vector2.ZERO) if placed.is_empty() else _bounds.expand(at)
		placed[node.get_id()] = at

	var registry: MonologueRegistry = MonologueRegistry.get_instance()
	for node: InspectableNode in section.nodes:
		if not placed.has(node.get_id()):
			continue
		var indexer: NodeIndexer = registry.get_node(node.get_type())
		_marks.append({
			"at": placed[node.get_id()],
			"tint": (
				MonologuePalette.for_category(indexer.category)
				if indexer
				else MonologuePalette.FLOW
			),
		})

	for wire: NodeConnection in section.connections:
		if placed.has(wire.from_node_id) and placed.has(wire.to_node_id):
			_wires.append(
				PackedVector2Array([placed[wire.from_node_id], placed[wire.to_node_id]])
			)


static func _position_of(node: InspectableNode) -> Vector2:
	var stored: Variant = node.get_property_value("editor_position")
	if stored is Vector2:
		return stored
	if stored is Array and (stored as Array).size() >= 2:
		return Vector2(float(stored[0]), float(stored[1]))
	return Vector2.ZERO


func _draw() -> void:
	var area: Rect2 = Rect2(
		Vector2(PADDING, PADDING), size - Vector2(PADDING, PADDING) * 2.0 - MARK_SIZE
	)
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return

	# One scale for both axes, so a chain laid out wide and flat is drawn wide and flat. An axis
	# with no extent has nothing to fit, which is what a single node and a straight row are.
	var fitted: float = MAX_SCALE
	if _bounds.size.x > 0.0:
		fitted = minf(fitted, area.size.x / _bounds.size.x)
	if _bounds.size.y > 0.0:
		fitted = minf(fitted, area.size.y / _bounds.size.y)

	var zoom: float = maxf(fitted, MIN_SCALE)
	var origin: Vector2 = area.position + (area.size - _bounds.size * zoom) / 2.0

	var spots: PackedVector2Array = []
	for mark: Dictionary in _marks:
		spots.append(_spot(origin, zoom, mark["at"]))

	var drawn: Vector2 = _fitted_mark(spots)
	var middle: Vector2 = drawn / 2.0

	for wire: PackedVector2Array in _wires:
		draw_line(
			_spot(origin, zoom, wire[0]) + middle,
			_spot(origin, zoom, wire[1]) + middle,
			Color(MonologuePalette.FLOW, 0.25),
			1.0
		)

	for index: int in _marks.size():
		draw_rect(Rect2(spots[index], drawn), _marks[index]["tint"])


func _fitted_mark(spots: PackedVector2Array) -> Vector2:
	var room: float = 1.0
	for first: int in spots.size():
		for second: int in range(first + 1, spots.size()):
			var apart: Vector2 = (spots[first] - spots[second]).abs()
			room = minf(
				room,
				maxf(
					(apart.x - MARK_GAP) / MARK_SIZE.x,
					(apart.y - MARK_GAP) / MARK_SIZE.y
				)
			)

	return Vector2(maxf(MARK_SIZE.x * room, MIN_MARK), maxf(MARK_SIZE.y * room, MIN_MARK))


func _spot(origin: Vector2, zoom: float, at: Vector2) -> Vector2:
	return origin + (at - _bounds.position) * zoom
