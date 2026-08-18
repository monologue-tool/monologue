## Says which behaviour runs a given node type.
##
## Adding a node type is dropping a file in a folder. Nothing here is edited for it.
class_name MonologueBehaviourIndexer extends MonologueIndex

const BUILT_IN_FOLDER: String = "res://addons/monologue/behaviours/"
const FOLDERS_SETTING: String = "monologue/behaviour_folders"

## Everything indexed. A behaviour claiming no type is an observer and still hears about
## every node.
var _all: Array[MonologueBehaviour] = []
var _fallback: MonologueBehaviour = MonologuePathThroughBehaviour.new()


func _init(problems: Array[MonologueProblem] = []) -> void:
	add_child(_fallback)
	super(BUILT_IN_FOLDER, FOLDERS_SETTING, problems)


func wanted() -> Script:
	return MonologueBehaviour


func names_of(thing: Node) -> PackedStringArray:
	return (thing as MonologueBehaviour).handles()


## Never null. A type nobody claimed is walked past, so a story from a newer editor plays.
func for_type(node_type: String) -> MonologueBehaviour:
	return _by_name.get(node_type, _fallback)


func all() -> Array[MonologueBehaviour]:
	return _all


func adopt(thing: Node, problems: Array[MonologueProblem] = []) -> bool:
	if thing.get_script() == _fallback.get_script():
		return false

	_all.append(thing)
	return super(thing, problems)
