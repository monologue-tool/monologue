## A section node's preview graph thumbnail.
class_name SectionMap extends Control

const HEIGHT: float = 56.0
const MARK_SIZE: Vector2 = Vector2(9.0, 5.0)
const PADDING: float = 4.0
const MAX_MARKS: int = 60

## One per node: {"at": Vector2 in 0..1, "tint": Color}.
var _marks: Array[Dictionary] = []
## One per wire, as the two normalised points it runs between.
var _wires: Array[PackedVector2Array] = []


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
	return map


func _read(section: StorylineDocument) -> void:
	var placed: Dictionary[String, Vector2] = {}
	var bounds: Rect2 = Rect2()

	for node: InspectableNode in section.nodes:
		if placed.size() >= MAX_MARKS:
			break
		var at: Vector2 = _position_of(node)
		bounds = Rect2(at, Vector2.ZERO) if placed.is_empty() else bounds.expand(at)
		placed[node.get_id()] = at

	for node_id: String in placed:
		var at: Vector2 = placed[node_id] - bounds.position
		placed[node_id] = Vector2(
			at.x / bounds.size.x if bounds.size.x > 0.0 else 0.5,
			at.y / bounds.size.y if bounds.size.y > 0.0 else 0.5
		)

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

	var middle: Vector2 = MARK_SIZE / 2.0
	for wire: PackedVector2Array in _wires:
		draw_line(
			_spot(area, wire[0]) + middle,
			_spot(area, wire[1]) + middle,
			Color(MonologuePalette.FLOW, 0.25),
			1.0
		)

	for mark: Dictionary in _marks:
		draw_rect(Rect2(_spot(area, mark["at"]), MARK_SIZE), mark["tint"])


static func _spot(area: Rect2, at: Vector2) -> Vector2:
	return area.position + at * area.size
