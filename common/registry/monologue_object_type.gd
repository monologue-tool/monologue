## The three kinds of thing a plugin can register with [MonologueRegistry].
##
## Names are only unique *within* an object type: "text" is both a field type and a
## node type, and "option" is both a field type and a node type. The registry keys
## on (object_type, name) for exactly that reason.
class_name MonologueObjectType

## An editable value type shown in the inspector and as a graph port.
const FIELD: StringName = &"field"
## A node type that can be placed in a storyline graph.
const NODE: StringName = &"node"
## A project-wide list of reusable items (characters, variables, ...).
const COLLECTION: StringName = &"collection"

const ALL: Array[StringName] = [FIELD, NODE, COLLECTION]


static func is_valid(object_type: StringName) -> bool:
	return object_type in ALL
