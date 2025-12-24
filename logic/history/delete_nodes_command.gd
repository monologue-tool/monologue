class_name DeleteNodesCommand extends AddNodesCommand


func execute() -> void:
	super.undo()


func undo() -> void:
	super.execute()


func get_description() -> String:
	return "Delete %s nodes" % nodes.size()
