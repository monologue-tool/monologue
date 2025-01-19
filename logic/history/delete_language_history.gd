class_name DeleteLanguageHistory extends AddLanguageHistory


var restoration: Dictionary = {}
var choices: Dictionary = {}


func _init(graph: MonologueGraphEdit, locale: String, path: String) -> void:
	super(graph, locale)
	node_name = path


func undo():
	var redo_result = super.redo()
	for property in restoration:
		if is_instance_valid(property):
			property.raw_data = restoration.get(property)
	
	for choice in choices:
		choice.restore_options(choices.get(choice))
	
	return redo_result


func redo():
	return super.undo()
