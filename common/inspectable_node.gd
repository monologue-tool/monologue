@abstract
class_name InspectableNode extends InspectableObject

var graph_view: GraphNode
var storyline_id: String = ""
var _main_property_defined: bool = false


func _init(command_manager: CommandManager = null) -> void:
	define_property(Property.new("color")
		.set_type("color")
		.default("#000000")
		.header()
		.no_expand())

	super._init(command_manager)

	define_property(Property.new("label")
		.set_type("text")
		.default(get_property_value("id"))
		.header()
		.placeholder("label")
		.not_exposable()
		.unique_among_siblings())

	define_property(Property.new("extra/notes")
		.set_type("textarea")
		.hidden_in_graph()
		.not_exposable())

	define_property(Property.new("extra/position")
		.set_type("vector2")
		.hidden_in_graph()
		.hidden_in_inspector()
		.not_exposable())

	if not _main_property_defined:
		push_error("%s does not declare a main property." % get_type())


## Tracks the main property as it is declared, so a node cannot end up with two.
func define_property(property: Property) -> Property:
	if property.is_main_property():
		if _main_property_defined:
			push_error("%s declares more than one main property." % get_type())
		_main_property_defined = true
	return super.define_property(property)


func get_id() -> String:
	return get_property_value("id")


func get_main_property() -> Property:
	if not _main_property_defined:
		return null

	for prop: Property in get_properties():
		if not prop.get_settings_value("is_main_property", false):
			continue
		return prop

	return null


## Returns properties visible in the graph, ordered with main property first.
## Used for port index calculation and graph node display.
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


@abstract func get_type() -> String


@warning_ignore("native_method_override")
func duplicate(deep: bool = false) -> Resource:
	var duplicated: InspectableNode = super.duplicate(deep)
	duplicated.get_property("id").value = IDGen.generate_object_id(get_type())
	duplicated.get_property("position").value += [30, 30]

	return duplicated
