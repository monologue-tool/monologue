class_name SentenceNode extends InspectableNode


func initialize_properties() -> void:
	define_main_property("sentence", "context", false, null, {"export": true})
	define_property("line", {}, "translatable", { PropertySettings.KEY_MULTILINE: true })
	define_property("speaker", "", "dropdown", {"source": "characters"}, "Speaker")
	define_property("display_name", {}, "translatable", {"visible_in_graph": false}, "Speaker")
	define_property("voiceline", "", "file", {"visible_in_graph": false}, "Speaker")


func get_type() -> String:
	return "sentence"
