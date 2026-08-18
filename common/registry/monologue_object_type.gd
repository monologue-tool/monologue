## The three kinds of thing a plugin can register with [MonologueRegistry].
##
## Names are unique within an object type, not across them. "text" and "option" each name
## both a field and a node, so the registry keys on (object_type, name).
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
