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


func add_node(node: InspectableNode) -> void:
	node.add_observer(self)


# Called by InspectableNode
func on_property_changed(pname: String, _old_value: Variant, _new_value: Variant) -> void:
	print(pname)

	is_dirty = true
