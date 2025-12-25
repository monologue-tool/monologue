class_name AddNodesCommand extends Command

var storyline_id: String
var nodes: Array = []


func _init(
	p_storyline_id: String,
	p_nodes: Array,
) -> void:
	storyline_id = p_storyline_id
	nodes = p_nodes


func execute() -> void:
	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)
	if not storyline:
		return

	for node in nodes:
		storyline.add_node(node)


func undo() -> void:
	var storyline: StorylineDocument = StorylineManager.get_storyline(storyline_id)
	if not storyline:
		return

	for node in nodes:
		storyline.remove_node(node)


func get_description() -> String:
	return "Add %s nodes" % nodes.size()
