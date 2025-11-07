class_name StorylineDocument extends InspectableStorylineObject

signal content_changed
signal undo_redo_changed

var id: String = IDGen.generate()
var name: String = ""
var nodes: Array[InspectableNode] = []
var file_path: String = ""
var is_dirty: bool = false


func _init(sname: String, sfile_path: String = "") -> void:
	name = sname
	file_path = sfile_path

	var command_manager = CommandManager.new()
	command_manager.command_executed.connect(_on_command_executed)
	command_manager.undone.connect(_on_undo)
	command_manager.redone.connect(_on_redo)
	
	super._init(command_manager)

	_create_default_nodes()


func add_node(node: InspectableNode) -> void:
	_register_node(node)


func create_node(node_type: String) -> InspectableNode:
	var node = NodeBucket.create_node(node_type, history)
	_register_node(node)
	return node


func initialize_properties() -> void:
	# Define characters list
	define_property(
		"characters",
		[],
		"list",
		{
			"visible_in_graph": false,
			"visible_in_inspector": true,
			"editable": true,
			"hide_add_button": true,
			"supports_edit_button": true,  # Enable edit button for detailed editing
			"item_template": {
				"name": {"type": "text", "default": ""}
			}
		},
		"Storyline"
	)
	
	# Define variables list
	define_property(
		"variables",
		[],
		"list",
		{
			"visible_in_graph": false,
			"visible_in_inspector": true,
			"editable": true,
			"hide_add_button": true,
			"item_template": {
				"name": {"type": "text", "default": ""},
				"type": {"type": "dropdown", "default": "String", "options": ["String", "Int", "Float", "Bool"]},
				"value": {"type": "text", "default": ""}
			}
		},
		"Storyline"
	)


func get_type() -> String:
	return "storyline"


func get_settings() -> Dictionary:
	return {}


func _on_property_changed(_pname: String, _old_value: Variant, _new_value: Variant) -> void:
	is_dirty = true
	content_changed.emit()


func build_graph_preview() -> Array[Control]:
	return []


func _on_command_executed():
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()


func _on_undo():
	content_changed.emit()
	undo_redo_changed.emit()


func _on_redo():
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()


func save():
	# TODO: Save logic
	is_dirty = false


func _create_default_nodes() -> void:
	var defaults := ["root", "sentence", "text"]
	for node_type: String in defaults:
		var node = NodeBucket.create_node(node_type, history)
		_register_node(node)


func _register_node(node: InspectableNode) -> void:
	if node == null:
		return
	if node not in nodes:
		nodes.append(node)
	node.storyline_id = id
	node.add_observer(_on_node_property_changed)
	is_dirty = true


func _on_node_property_changed(_node: InspectableNode, _property: String) -> void:
	is_dirty = true
