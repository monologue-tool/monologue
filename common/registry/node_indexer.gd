## Describes one graph node type.
##
## A node type is little more than a script declaring properties; everything the graph
## needs to draw it (title, colour, icon, category) lives here.
@abstract
class_name NodeIndexer extends MonologueIndexer

## Script extending [InspectableNode]. Safe to preload: node scripts are model code.
var node_script: GDScript


func get_object_type() -> StringName:
	return MonologueObjectType.NODE


func validate_registration() -> String:
	var error: String = super.validate_registration()
	if not error.is_empty():
		return error
	if node_script == null:
		return "Node '%s' has no node_script." % name
	return ""


func instantiate(history: CommandManager = null) -> Object:
	if node_script == null:
		return null
	var instance: Variant = node_script.new(history)
	if instance is InspectableNode:
		return instance
	push_error("Node '%s': node_script does not extend InspectableNode." % name)
	return null
