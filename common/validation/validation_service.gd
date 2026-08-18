## The only place validation is orchestrated.
##
## Validation never blocks. A value the user typed is always written, and what comes back
## from here describes what is wrong with it. That is what lets you rename A to B and then
## B to C without the editor refusing the halfway state.
class_name ValidationService


static func validate_value(context: ValidationContext) -> ValidationResult:
	var result: ValidationResult = ValidationResult.ok()
	if context.property == null:
		return result

	for rule: ValidationRule in rules_for(context.property):
		if rule.applies_to(context):
			result.merge(rule.check(context))
	return result


## Stores the outcome on the property, so the UI renders it without running the rules
## again.
static func validate_property(
	property: Property,
	object: InspectableObject,
	phase: ValidationContext.Phase = ValidationContext.Phase.COMMIT,
	project: MonologueProject = null
) -> ValidationResult:
	var context: ValidationContext = ValidationContext.for_property(
		property, object, property.get_value(), phase
	)
	context.project = project
	var result: ValidationResult = validate_value(context)
	property.issues = result.issues
	return result


## Every property, then the object's own cross-property checks.
static func validate_object(
	object: InspectableObject, project: MonologueProject = null
) -> ValidationResult:
	var result: ValidationResult = ValidationResult.ok()
	if object == null:
		return result

	for property: Property in object.get_properties():
		var context: ValidationContext = ValidationContext.for_property(
			property, object, property.get_value(), ValidationContext.Phase.AUDIT
		)
		context.project = project
		var property_result: ValidationResult = validate_value(context)
		property.issues = property_result.issues
		result.merge(property_result)

	# Cross-property checks no single property can express.
	var object_context: ValidationContext = ValidationContext.new()
	object_context.object = object
	object_context.project = project
	object_context.phase = ValidationContext.Phase.AUDIT
	object.validate_object(result, object_context)

	for children: Array in object.get_all_property_children():
		for child: Variant in children:
			if child is InspectableObject:
				result.merge(validate_object(child, project))

	return result


static func validate_project(project: MonologueProject) -> ValidationResult:
	var result: ValidationResult = ValidationResult.ok()
	if project == null:
		return result

	# Whatever went wrong reading the file is part of the picture too.
	result.merge(project.load_issues)

	for document: InspectableDocument in project.get_all_documents():
		result.merge(validate_document(document, project))
	return result


static func validate_document(
	document: InspectableDocument, project: MonologueProject
) -> ValidationResult:
	var result: ValidationResult = ValidationResult.ok()
	if document == null:
		return result

	var before: int = result.issues.size()
	result.merge(validate_object(document, project))

	if document is StorylineDocument:
		for node: InspectableNode in (document as StorylineDocument).nodes:
			result.merge(validate_object(node, project))

	# Stamp anything the document produced with where it came from.
	for index: int in range(before, result.issues.size()):
		if result.issues[index].document_name.is_empty():
			result.issues[index].in_document(document.get_document_name())

	return result


## Whatever its field type demands of every value, then what the declaration adds.
static func rules_for(property: Property) -> Array[ValidationRule]:
	var rules: Array[ValidationRule] = []

	var indexer: FieldIndexer = MonologueRegistry.get_instance().get_field(property.type)
	if indexer:
		rules.append_array(indexer.get_validation_rules())

	if property.get_settings_value(PropertySettings.KEY_REQUIRED, false):
		rules.append(RequiredRule.new())

	if property.get_settings_value(PropertySettings.KEY_UNIQUE, false):
		rules.append(UniqueRule.new())

	if property.type == "reference":
		rules.append(ReferenceRule.new())

	var bounds: Variant = property.get_settings_value(PropertySettings.KEY_VALIDATION, {})
	if bounds is Dictionary and not (bounds as Dictionary).is_empty():
		rules.append_array(_bound_rules(bounds))

	rules.append_array(property.get_validation_rules())
	return rules


static func _bound_rules(bounds: Dictionary) -> Array[ValidationRule]:
	var rules: Array[ValidationRule] = []

	if bounds.has("min_length") or bounds.has("max_length"):
		rules.append(
			LengthRule.new(int(bounds.get("min_length", -1)), int(bounds.get("max_length", -1)))
		)
	if bounds.has("min") or bounds.has("max"):
		rules.append(RangeRule.new(bounds.get("min"), bounds.get("max")))

	return rules
