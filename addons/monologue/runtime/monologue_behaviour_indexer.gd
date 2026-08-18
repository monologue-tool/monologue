## Says which behaviour runs a given node type.
##
## Adding a node type is dropping a file in a folder. Nothing here, and nothing in the
## session, is edited for it.
class_name MonologueBehaviourIndexer extends MonologueIndex

const BUILT_IN_FOLDER: String = "res://addons/monologue/behaviours/"
const FOLDERS_SETTING: String = "monologue/behaviour_folders"

## Everything indexed, claimed types or not: a behaviour claiming none is an observer, and
## still hears about every node.
var _all: Array[MonologueBehaviour] = []
var _fallback: MonologueBehaviour = MonologuePathThroughBehaviour.new()


func _init(problems: Array[MonologueProblem] = []) -> void:
	add_child(_fallback)
	super(BUILT_IN_FOLDER, FOLDERS_SETTING, problems)


func wanted() -> Script:
	return MonologueBehaviour


func names_of(thing: Node) -> PackedStringArray:
	return (thing as MonologueBehaviour).handles()


## Never null: a type nobody claimed is walked past, which is what lets a story built in a
## newer editor still play.
func for_type(node_type: String) -> MonologueBehaviour:
	return _by_name.get(node_type, _fallback)


func all() -> Array[MonologueBehaviour]:
	return _all


## The index builds its own fallback, so the copy sitting in the folder is refused.
func adopt(thing: Node, problems: Array[MonologueProblem] = []) -> bool:
	if thing.get_script() == _fallback.get_script():
		return false

	_all.append(thing)
	return super(thing, problems)
