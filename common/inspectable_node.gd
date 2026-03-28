@abstract
class_name InspectableNode extends InspectableObject

var graph_view: GraphNode
var storyline_id: String = ""
var _main_property_defined: bool = false


func _init(command_manager: CommandManager = null) -> void:
	define_property(
		"color",
		"#000000",
		"color",
		{
			"visible_in_graph": false,
			"visible_in_inspector": true,
			"flat": true,
			"expand": false,
		},
		"Special:Header"
	)
	# Keep all connection references in sync when the id changes
	var _id_prop: Property = get_property("id")
	if _id_prop and not _id_prop.value_changed.is_connected(_on_id_value_changed):
		_id_prop.value_changed.connect(_on_id_value_changed)
	super._init(command_manager)
	define_property(
		"notes",
		"",
		"textarea",
		{
			"visible_in_graph": false,
			"visible_in_inspector": true,
			"exposable": false,
		},
		"Extra"
	)
	define_property(
		"position",
		[0.0, 0.0],
		"vector2",
		{
			"visible_in_graph": false,
			"visible_in_inspector": false,
			"read_only": false,
			"exposable": false,
		},
		"Extra"
	)

	if not _main_property_defined:
		push_error("Main property not defined")


func define_main_property(
	pname: String,
	type: String,
	editable: bool = false,
	default_value: Variant = null,
	psettings: Dictionary = {},
	category: String = "General"
) -> void:
	if _main_property_defined:
		push_error("Main property already defined")
		return

	var default_settings: Dictionary = {}
	default_settings["visible_in_graph"] = true
	default_settings["visible_in_inspector"] = editable
	default_settings["editable"] = editable
	default_settings["exposable"] = true
	default_settings["exposed"] = true
	default_settings["export"] = true
	default_settings["is_main_property"] = true

	var merged_settings: Dictionary = default_settings.duplicate()
	merged_settings.merge(psettings, true)

	define_property(pname, default_value, type, merged_settings, category)
	_main_property_defined = true


func define_property(
	pname: String,
	default_value: Variant,
	ptype: String,
	psettings: Dictionary = {},
	category: String = "General"
) -> void:
	super.define_property(pname, default_value, ptype, psettings, category)


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


func _on_id_value_changed(old_value: Variant, new_value: Variant) -> void:
	var old_id: String = str(old_value)
	var new_id: String = str(new_value)
	if old_id == new_id:
		return

	# Update all connection references via connection manager
	if is_instance_valid(graph_view):
		var graph_edit: MonologueGraphEdit = graph_view.get_parent()
		if graph_edit and graph_edit is MonologueGraphEdit and graph_edit.connection_manager:
			graph_edit.connection_manager.rename_node_id(old_id, new_id)

	# Ensure the GraphNode uses the new id as its name and reconnect
	if is_instance_valid(graph_view):
		graph_view.name = new_id
		var gv_parent: MonologueGraphEdit = graph_view.get_parent()
		if gv_parent and gv_parent is MonologueGraphEdit:
			gv_parent.clear_connections()
			gv_parent._reconnect_all_slots()


@warning_ignore("native_method_override")
func duplicate(deep: bool = false) -> Resource:
	var duplicated: InspectableNode = super.duplicate(deep)
	duplicated.get_property("id").value = IDGen.generate(ID_LENGTH)
	duplicated.get_property("position").value += [30, 30]

	return duplicated
