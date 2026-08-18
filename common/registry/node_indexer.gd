## Describes one graph node type.
##
## A node type is little more than a script declaring properties; everything the graph
## needs to draw it (title, colour, icon, category) lives here.
@abstract
class_name NodeIndexer extends MonologueIndexer

## Script extending [InspectableNode]. Safe to preload: node scripts are model code.
var node_script: GDScript
## True for a node every storyline has exactly one of, and which the storyline itself
## creates: it is not offered by the add menus and cannot be deleted, cut or pasted.
var is_singleton: bool = false
## Whether the story can arrive at this node. False for the types that are read rather
## than entered -- a value fed into another node's port, or an option a choice offers.
## Those carry no runtime behaviour, and a wire into one is a mistake worth reporting.
var enterable: bool = true
## Where the runtime addon keeps this type's behaviour: a "res://" or "uid://" path to a
## script extending MonologueBehaviour.
##
## A path rather than a preload, and never resolved here: naming the behaviour must not
## pull runtime code into the editor. It exists so that every type says in one place
## where it is run, and so a test can tell an unimplemented type from a forgotten one.
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


## True when [param node] is one the storyline owns rather than the user.
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
