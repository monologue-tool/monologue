## Represents a storyline document containing dialogue nodes and history.
##
## A StorylineDocument manages a collection of dialogue nodes, tracks the
## document's state (dirty/clean), and provides undo/redo functionality
## through a CommandManager.
class_name StorylineDocument extends RefCounted

## Emitted when the document content changes.
signal content_changed

## Emitted when the undo/redo state changes.
signal undo_redo_changed

## Unique identifier for this document.
var id: String = IDGen.generate()

## Display name of the storyline.
var name: String = ""

## Array of all nodes in this storyline.
var nodes: Array[InspectableNode] = []

## File system path where this storyline is saved.
var file_path: String = ""

## Whether the document has unsaved changes.
var is_dirty: bool = false

## Command manager for undo/redo operations.
var history: CommandManager


## Initializes a new storyline document.
##
## Creates default nodes (root, sentence, and text) and sets up the command history.
## [br][br]
## [param sname] The display name for this storyline.
## [br][br]
## [param sfile_path] Optional file path where this storyline is saved.
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


## Adds a node to this storyline and registers it as an observer.
##
## [param node] The InspectableNode to add to this storyline.
func add_node(node: InspectableNode) -> void:
	node.add_observer(on_node_changed)


## Internal callback when a command is executed.
##
## Marks the document as dirty and emits change signals.
func _on_command_executed():
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()


## Internal callback when an undo operation occurs.
##
## Emits change signals without marking as dirty (undoing to saved state).
func _on_undo():
	content_changed.emit()
	undo_redo_changed.emit()


## Internal callback when a redo operation occurs.
##
## Marks the document as dirty and emits change signals.
func _on_redo():
	is_dirty = true
	content_changed.emit()
	undo_redo_changed.emit()


## Saves the storyline to disk.
##
## TODO: Implement save logic. Currently only marks the document as clean.
func save():
	# TODO: Save logic
	is_dirty = false


## Observer callback invoked when a node's property changes.
##
## Marks the document as dirty when any node property changes.
## [br][br]
## [param _pnode] The node that changed (unused).
## [br][br]
## [param _pname] The property name that changed (unused).
## [br][br]
## [param _old_value] The old property value (unused).
## [br][br]
## [param _new_value] The new property value (unused).
func on_node_changed(
	_pnode: InspectableNode, _pname: String, _old_value: Variant, _new_value: Variant
) -> void:
	is_dirty = true
