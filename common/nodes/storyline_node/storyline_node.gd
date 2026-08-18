## Leaves this storyline for another one. Terminal: the story continues over there, so
## the node has no output.
class_name StorylineNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("storyline")
		.set_type("context")
		.main_property()
		.exposed()
		.exported(false))

	define_property(Property.new("target")
		.set_type("reference")
		.reference_scope("storylines")
		.required()
		.tooltip("Storyline to continue into."))


func get_type() -> String:
	return "storyline"


## Which storyline the reader leaves for.
func _build_preview(_language: String = "") -> Control:
	var target: String = NodePreview.named(self, "target")
	if target.is_empty():
		return null
	return NodePreview.line("\u2192 %s" % NodePreview.plain(target))


## Pointing at the storyline this node already lives in restarts it. Legitimate for a
## loop, surprising by accident, so it is said rather than refused.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	if str(get_property_value("target")) == storyline_id:
		result.add(
			ValidationIssue.warning(
				"This switches to the storyline it is already in, restarting it.",
				&"self_storyline_switch"
			).at(self, "target")
		)
