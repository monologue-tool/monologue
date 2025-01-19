## Like AddNodeHistory but doesn't use [method MonologueGraphEdit.add_node]
## to restore nodes. It uses the graph edit's add_child() method directly.
## It also reverses the undo() and redo() functions.
class_name DeleteNodeHistory
extends AddNodeHistory


func _init(graph: MonologueGraphEdit, nodes: Array[MonologueGraphNode]):
	super(graph, nodes)
	# difference in this history is that the restoration directly calls
	# graph edit's add_child() for each individual node
	_redo_callback = func() -> Array[MonologueGraphNode]:
			var created_nodes: Array[MonologueGraphNode] = []
			for name in restoration_data.keys():
				var type = restoration_data[name].get("$type").trim_prefix("Node")
				var node = Constants.NODE_SCENES.get(type)
				var inst = node.instantiate()
				graph_edit.add_child(inst)
				created_nodes.append(inst)
			return created_nodes


func undo():
	return super.redo()


func redo():
	return super.undo()
