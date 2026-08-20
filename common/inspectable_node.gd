@abstract
class_name InspectableNode extends InspectableObject

var graph_view: GraphNode
var storyline_id: String = ""
var _main_property_defined: bool = false


func _init(command_manager: CommandManager = null) -> void:
	super._init(command_manager)

	define_property(Property.new("label")
		.set_type("text")
		.plain()
		.default(get_property_value("id"))
		.header()
		.placeholder("label")
		.not_exposable()
		.unique_among_siblings())

	define_property(Property.new("extra/notes")
		.set_type("textarea")
		.hidden_in_graph()
		.not_exposable())

	define_property(Property.new("extra/editor_position")
		.set_type("vector2")
		.hidden_in_graph()
		.hidden_in_inspector()
		.not_exposable())

	if get_main_property() == null:
		push_error(
			"%s has no main property" % get_type() + "or editor_position."
		)


## Tracks the main property as it is declared, so a node cannot end up with two.
func define_property(property: Property) -> Property:
	if property.is_main_property():
		if _main_property_defined:
			push_error("%s declares more than one main property." % get_type())
		_main_property_defined = true
	return super.define_property(property)


func get_id() -> String:
	return get_property_value("id")


## Written as a Vector2 by the editor and as a pair of numbers by a file, so both are read.
func get_editor_position() -> Vector2:
	var stored: Variant = get_property_value("editor_position")
	if stored is Vector2:
		return stored
	if stored is Array and (stored as Array).size() >= 2:
		return Vector2(float(stored[0]), float(stored[1]))
	return Vector2.ZERO


## Top to bottom, then left to right: the order somebody reading the canvas would give them.
static func laid_out_before(first: InspectableNode, second: InspectableNode) -> bool:
	var here: Vector2 = first.get_editor_position()
	var there: Vector2 = second.get_editor_position()
	if is_equal_approx(here.y, there.y):
		return here.x < there.x
	return here.y < there.y


func get_main_property() -> Property:
	if not _main_property_defined:
		return null

	for prop: Property in get_properties():
		if not prop.get_settings_value("is_main_property", false):
			continue
		return prop

	return null


## Properties visible in the graph, main property first.
func get_visible_properties() -> Array[Property]:
	var visible: Array[Property] = []
	for prop: Property in get_properties():
		if not prop.is_visible_in_graph():
			continue
		if prop.get_settings_value("is_main_property"):
			visible.push_front(prop)
		else:
			visible.append(prop)
	return visible


func rebuild_preview() -> void:
	if not is_instance_valid(graph_view):
		return
	var graph_edit: MonologueGraphEdit = graph_view.get_parent()
	if graph_edit and graph_edit is MonologueGraphEdit:
		graph_edit.refresh_node(self)


## What this node shows under its ports. Any [Control]. [NodePreview] holds the pieces most
## of them are built from.
##
## Null means no preview. The view owns what comes back, clips it to the node's width, caps
## its height, and asks again on every change.
func _build_preview(_language: String = "") -> Control:
	return null


## What this property gives back when that differs from what it declares. A reroute hands on
## whatever was plugged into it. Returns {"type_id": int, "label": String}, or empty.
##
## Only the outgoing side. What a node takes in stays what it declares, otherwise a reroute
## could never be rewired without first being unplugged.
##
## [param hops] bounds the walk, so a reroute wired in a circle is given up on.
func carried_port(_property: Property, _hops: int = 0) -> Dictionary:
	return {}


## Redraws the preview alone. Rebuilding the whole view would take the ports and their wires
## with it, on every keystroke.
func refresh_preview() -> void:
	if is_instance_valid(graph_view):
		GraphNodeViewFactory.refresh_preview(graph_view, self)


@abstract func get_type() -> String


@warning_ignore("native_method_override")
func duplicate(deep: bool = false) -> Resource:
	var duplicated: InspectableNode = super.duplicate(deep)
	duplicated.get_property("id").value = IDGen.generate_object_id(get_type())
	duplicated.get_property("editor_position").value += [30, 30]

	return duplicated
