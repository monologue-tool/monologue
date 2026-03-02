@abstract
class_name InspectableNode extends InspectableObject

const ID_LENGTH: int = 6

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
	define_property(
		"id",
		IDGen.generate(ID_LENGTH),
		"text",
		{
			"visible_in_graph": false,
			"visible_in_inspector": true,
			"flat": true,
		},
		"Special:Header"
	)
	# Keep all connection references in sync when the id changes
	var _id_prop := get_property("id")
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
		Vector2.ZERO,
		"vector2",
		{
			"visible_in_graph": false,
			"visible_in_inspector": false,
			"editable": false,
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


func rebuild_preview() -> void:
	if not is_instance_valid(graph_view):
		return
	var graph_edit: MonologueGraphEdit = graph_view.get_parent()
	if graph_edit and graph_edit is MonologueGraphEdit:
		graph_edit.refresh_node(self)


@abstract func get_type() -> String


func _on_id_value_changed(old_value: Variant, new_value: Variant) -> void:
	var old_id := String(old_value)
	var new_id := String(new_value)
	if old_id == new_id:
		return

	# Update all connection references via connection manager if available
	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)
	if storyline:
		# Try to find a graph_edit and its connection manager
		var graph_edit := graph_view.get_parent() if is_instance_valid(graph_view) else null
		if graph_edit and graph_edit is MonologueGraphEdit and graph_edit.connection_manager:
			graph_edit.connection_manager.rename_node_id(old_id, new_id)
		else:
			# Fallback: direct update across storyline
			for node: InspectableNode in storyline.nodes:
				for prop: Property in node.get_properties():
					# Update outgoing connections
					for i in range(prop.connected_to.size()):
						var conn: Dictionary = prop.connected_to[i]
						if conn.get("node_id", "") == old_id:
							conn["node_id"] = new_id
							prop.connected_to[i] = conn
					# Update incoming connections
					for i in range(prop.connected_from.size()):
						var conn_in: Dictionary = prop.connected_from[i]
						if conn_in.get("node_id", "") == old_id:
							conn_in["node_id"] = new_id
							prop.connected_from[i] = conn_in

	# Ensure the GraphNode uses the new id as its name and reconnect
	if is_instance_valid(graph_view):
		graph_view.name = new_id
		var gv_parent := graph_view.get_parent()
		if gv_parent and gv_parent is MonologueGraphEdit:
			gv_parent.clear_connections()
			gv_parent._reconnect_all_slots()


@warning_ignore("native_method_override")
func duplicate(deep: bool = false) -> Resource:
	var duplicated: InspectableNode = super.duplicate(deep)
	duplicated.get_property("id").value = IDGen.generate(ID_LENGTH)
	duplicated.get_property("position").value += Vector2(30, 30)

	return duplicated


@abstract func get_color() -> Color
@abstract func get_icon() -> Texture2D
