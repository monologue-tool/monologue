class_name SentenceNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("sentence")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())

	define_property(Property.new("line")
		.set_type("text")
		.multiline())

	define_property(Property.new("speaker/speaker")
		.set_type("reference")
		.reference_scope("characters")
		.label_property("name"))

	define_property(Property.new("speaker/display_name")
		.set_type("text")
		.hidden_in_graph())

	define_property(Property.new("speaker/voiceline")
		.set_type("file")
		.hidden_in_graph())


func get_type() -> String:
	return "sentence"


## The line as it will be read, behind whoever says it.
func _build_preview(language: String = "") -> Control:
	var line: String = NodePreview.said(self, "line", language)
	var speaker: String = NodePreview.tinted(self, "speaker")
	if line.is_empty() and speaker.is_empty():
		return null
	if speaker.is_empty():
		return NodePreview.line(NodePreview.plain(line))
	return NodePreview.line("%s  %s" % [speaker, NodePreview.plain(line)])
