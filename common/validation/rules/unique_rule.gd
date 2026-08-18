## The value must differ from every sibling item's value for the same property.
## Declared with [method Property.unique_among_siblings].
class_name UniqueRule extends ValidationRule


func _init() -> void:
	code = &"unique"
	# Deliberately not checked while typing. Renaming A to B when B exists is a legal
	# first half of a swap, and flagging it mid-keystroke would be noise.
	phases = [ValidationContext.Phase.COMMIT, ValidationContext.Phase.AUDIT]


func check(context: ValidationContext) -> ValidationResult:
	for sibling: InspectableObject in context.siblings():
		var sibling_property: Property = sibling.get_property(context.property.name)
		if sibling_property and sibling_property.get_value() == context.value:
			return _fail(
				context,
				(
					"Another %s already uses %s '%s'."
					% [
						sibling.get_type(),
						context.property.get_display_name().to_lower(),
						str(context.value)
					]
				)
			)
	return ValidationResult.ok()
