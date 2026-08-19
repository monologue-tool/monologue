## Continues the story inside a section, and does not come back.
##
## A section node is a detour, this is a departure. What is waiting to be returned to is left
## alone either way, so a jump made inside a section still unwinds to whatever ran it once
## the chain it landed on runs out.
class_name JumpNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("jump")
		.set_type("context")
		.main_property()
		.exposed()
		.exported(false))

	define_property(Property.new("target")
		.set_type("reference")
		.reference_scope("sections")
		.required()
		.tooltip("Section to continue in."))


func get_type() -> String:
	return "jump"


## Where the story carries on.
func _build_preview(_language: String = "") -> Control:
	var target: String = NodePreview.named(self, "target")
	if target.is_empty():
		return null
	return NodePreview.line("\u2192 %s" % NodePreview.plain(target))


func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	if str(get_property_value("target")).is_empty():
		result.add(
			ValidationIssue.warning(
				"This jump names no section, so the story stops here.", &"empty_jump"
			).at(self, "target")
		)
