class_name InputNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("input")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())

	define_property(Property.new("text")
		.set_type("text")
		.default({"en": "Enter something here:"})
		.hidden_in_graph())

	define_property(Property.new("variable")
		.set_type("reference")
		.reference_scope("variables")
		.label_property("name")
		.hidden_in_graph())

	define_property(Property.new("placeholder")
		.set_type("text")
		.hidden_in_graph())

	define_property(Property.new("allow_empty")
		.set_type("bool")
		.default(false)
		.hidden_in_graph())


func get_type() -> String:
	return "input"


## What is asked, and where the answer lands.
func _build_preview(language: String = "") -> Control:
	var into: String = NodePreview.named(self, "variable")
	var prompt: String = NodePreview.said(self, "text", language)
	if into.is_empty() and prompt.is_empty():
		return null
	if into.is_empty():
		return NodePreview.line(NodePreview.plain(prompt))
	return NodePreview.line(NodePreview.plain("%s \u2192 %s" % [prompt, into]).strip_edges())
