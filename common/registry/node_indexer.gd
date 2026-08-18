## Describes one graph node type. The script declaring its properties, and everything the
## graph needs to draw it.
@abstract
class_name NodeIndexer extends MonologueIndexer

## Safe to preload. Node scripts are model code.
var node_script: GDScript
## A node the storyline creates and keeps. Not offered by the add menus, and cannot be
## deleted, cut or pasted.
var is_singleton: bool = false
## Whether the story can arrive at this node. False for the types that are read instead of
## entered, like a value fed into another node's port or an option a choice offers.
var enterable: bool = true
## "res://" or "uid://" of the MonologueBehaviour running this type. Never resolved here:
## naming a behaviour must not pull runtime code into the editor.
var runtime_uid: String = ""


func get_object_type() -> StringName:
	return MonologueObjectType.NODE


func validate_registration() -> String:
	var error: String = super.validate_registration()
	if not error.is_empty():
		return error
	if node_script == null:
		return "Node '%s' has no node_script." % name
	return ""


static func is_permanent(node: InspectableNode) -> bool:
	if node == null:
		return false
	var indexer: NodeIndexer = MonologueRegistry.get_instance().get_node(node.get_type())
	return indexer != null and indexer.is_singleton


func instantiate(history: CommandManager = null) -> Object:
	if node_script == null:
		return null
	var instance: Variant = node_script.new(history)
	if instance is InspectableNode:
		return instance
	push_error("Node '%s': node_script does not extend InspectableNode." % name)
	return null
