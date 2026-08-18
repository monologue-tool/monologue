class_name OptionNode extends InspectableNode


func initialize_properties() -> void:
	for property: Property in OptionCollectionItem.get_option_properties():
		define_property(property)


func get_type() -> String:
	return "option"


## The option as it will be offered, behind whoever offers it.
func _build_preview(language: String = "") -> Control:
	var text: String = NodePreview.said(self, "text", language)
	var speaker: String = NodePreview.tinted(self, "speaker")
	if text.is_empty() and speaker.is_empty():
		return null
	if speaker.is_empty():
		return NodePreview.line(NodePreview.plain(text))
	return NodePreview.line("%s  %s" % [speaker, NodePreview.plain(text)])


## Cross-property check: no single property can see that the condition switch is on
## while the condition itself is blank.
func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
	if not get_property_value("enable_condition"):
		return

	var condition: Variant = get_property_value("condition")
	var variable: String = str(condition.get("variable", "")) if condition is Dictionary else ""
	if variable.is_empty():
		result.add(
			ValidationIssue.warning(
				"This option's condition is enabled but empty, so it always shows.",
				&"empty_condition"
			).at(self, "condition")
		)
