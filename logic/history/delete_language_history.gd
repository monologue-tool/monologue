class_name DeleteLanguageHistory extends AddLanguageHistory


var restoration: Dictionary = {}
var choices: Dictionary = {}


func _init(graph: MonologueGraphEdit, locale: String, path: String) -> void:
	super(graph, locale)
	node_name = path


func undo():
	var redo_result = super.redo()
	for localizable in restoration:
		if is_instance_valid(localizable):
			localizable.raw_data = restoration.get(localizable).duplicate(true)
	
	for choice in choices:
		choice.restore_options(choices.get(choice))
	
	return redo_result


func redo():
	for localizable in restoration:
		var language_node = GlobalVariables.language_switcher.get_by_node_name(node_name)
		if is_instance_valid(localizable) and language_node.language_name == language_name:
			localizable.raw_data.erase(node_name)
	return super.undo()
