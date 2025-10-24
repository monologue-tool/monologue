class_name StorylineDocument extends RefCounted

var id: String = IDGen.generate()
var name: String = ""
var nodes: Array[InspectableNode] = []
var is_dirty: bool = false
var file_path: String = ""
var history: UndoRedo = UndoRedo.new()


func _init(sname: String, sfile_path: String = "") -> void:
	name = sname
	file_path = sfile_path

	var root_node: RootNode = RootNode.new()
	nodes.append(root_node)

	var sentence_node: SentenceNode = SentenceNode.new()
	nodes.append(sentence_node)


func add_node(node: InspectableNode) -> void:
	node.add_observer(self)


# Called by InspectableNode
func on_property_changed(
	pnode: InspectableNode, pname: String, _old_value: Variant, _new_value: Variant
) -> void:
	var node_id: String = pnode.get_property_value("id")
	print("Property %s of node %s changed." % [pname, node_id])
	#var action = history.create_action("Property %s changed of node %s" % [pname, pnode.get_property_value("id")], UndoRedo.MERGE_ENDS, )

	is_dirty = true
