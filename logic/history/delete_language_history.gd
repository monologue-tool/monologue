class_name DeleteLanguageHistory extends AddLanguageHistory


func _init(graph: MonologueGraphEdit, locale: String, path: String) -> void:
	super(graph, locale)
	node_name = path


func undo():
	return super.redo()


func redo():
	return super.undo()
