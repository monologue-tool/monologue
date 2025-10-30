## A dialogue storyline document with nodes and undo/redo history
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

	var root_node: RootNode = RootNode.new(history)
	nodes.append(root_node)

	var sentence_node: SentenceNode = SentenceNode.new(history)
	nodes.append(sentence_node)

	var text_node: TextNode = TextNode.new(history)
	nodes.append(text_node)


func add_node(node: InspectableNode) -> void:
	node.add_observer(on_node_changed)


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


# Called by InspectableNode
func on_node_changed(
	_pnode: InspectableNode, _pname: String, _old_value: Variant, _new_value: Variant
) -> void:
	is_dirty = true
