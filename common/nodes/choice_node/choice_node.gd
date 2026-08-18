class_name ChoiceNode extends InspectableNode

const MAX_CHOICES: int = 8
## Properties of a connected option node this choice copies. A change to one redraws this
## node. Anything else, position included, does not.
const MIRRORED_PROPERTIES: Array[String] = [
	"text", "label", "enabled", "one_shot", "condition"
]

var _external_options: Array[Dictionary] = []
## Kept so they can be unsubscribed from when the wiring changes.
var _watched_sources: Array[InspectableNode] = []


func initialize_properties() -> void:
	define_property(Property.new("choice")
		.set_type("context")
		.main_property()
		.exposed()
		.exported(false))

	var choices: Property = define_property(Property.new("choices")
		.set_type("collection")
		.collection("options")
		.exposed())

	choices.connection_changed.connect(_on_choices_connection_changed)


func get_type() -> String:
	return "choice"


func get_color() -> Color:
	return Color("e89145")


func get_external_list_items(property_name: String) -> Array[Dictionary]:
	if property_name == "choices":
		_sync_external_options()
		return _external_options
	return []


func get_total_choice_count() -> int:
	var internal_count: int = 0
	var choices_val: Variant = get_property_value("choices")
	if choices_val is Array:
		var choices_arr: Array = choices_val
		internal_count = choices_arr.size()
	return internal_count + _external_options.size()


func get_all_choices() -> Array:
	var result: Array = []
	var choices_val: Variant = get_property_value("choices")
	if choices_val is Array:
		var choices_arr: Array = choices_val
		result.append_array(choices_arr)
	for ext: Dictionary in _external_options:
		result.append(ext)
	return result


func _on_choices_connection_changed() -> void:
	_sync_external_options()
	rebuild_preview()


func _sync_external_options() -> void:
	_external_options.clear()
	var choices_prop: Property = get_property("choices")
	if not choices_prop:
		return

	var sources: Array[InspectableNode] = []
	for conn: Dictionary in choices_prop.connected_from:
		var source_node_id: String = conn.get("node_id", "")
		if source_node_id.is_empty():
			continue
		var source_node: InspectableNode = _find_node_by_id(source_node_id)
		if not source_node or not (source_node is OptionNode):
			continue
		sources.append(source_node)
		var ext_option: Dictionary = {
			"external": true,
			"source_node_id": source_node_id,
			"name": _get_option_node_name(source_node),
			"text": source_node.get_property_value("text"),
			"enabled": source_node.get_property_value("enabled"),
			"one_shot": source_node.get_property_value("one_shot"),
			"condition": source_node.get_property_value("condition"),
		}
		_external_options.append(ext_option)

	_watch_sources(sources)


## The copy shown here is built when the node is drawn, so nothing else would notice the
## original changing.
func _watch_sources(sources: Array[InspectableNode]) -> void:
	for watched: InspectableNode in _watched_sources:
		if watched in sources or not is_instance_valid(watched):
			continue
		if watched.property_changed.is_connected(_on_source_property_changed):
			watched.property_changed.disconnect(_on_source_property_changed)

	for source: InspectableNode in sources:
		if not source.property_changed.is_connected(_on_source_property_changed):
			source.property_changed.connect(_on_source_property_changed)

	_watched_sources = sources


func _on_source_property_changed(property_name: String) -> void:
	if property_name in MIRRORED_PROPERTIES:
		rebuild_preview()


## Null while the project is still being built, which is when the default nodes get wired.
func _find_node_by_id(node_id: String) -> InspectableNode:
	if storyline_id.is_empty() or ProjectManager.current_project == null:
		return null
	var storyline: StorylineDocument = ProjectManager.current_project.get_storyline(storyline_id)
	if not storyline:
		return null
	return storyline.get_node(node_id)


## The line it offers, or its label when it has none. Never its id.
func _get_option_node_name(node: InspectableNode) -> String:
	var project: MonologueProject = ProjectManager.current_project
	var language: String = project.active_language_code if project else ""

	var text: String = Util.to_label(node.get_property_value("text"), language)
	if not text.is_empty():
		return text

	return Util.to_label(node.get_property_value("label"), language)
