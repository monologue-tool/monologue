class_name StorylineDocument extends RefCounted

signal content_changed
signal undo_redo_changed

var id: String = IDGen.generate()
var name: String = ""
var nodes: Array[InspectableNode] = []
var file_path: String = ""
var is_dirty: bool = false
var history: CommandManager


func _init(sname: String, sfile_path: String = "") -> void:
	name = sname
	file_path = sfile_path

	history = CommandManager.new()

	history.command_executed.connect(_on_command_executed)
	history.undone.connect(_on_undo)
	history.redone.connect(_on_redo)

	_create_default_nodes()


func add_node(node: InspectableNode) -> void:
	_register_node(node)


func create_node(node_type: String) -> InspectableNode:
	var node = NodeBucket.create_node(node_type, history)
	_register_node(node)
	return node


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
