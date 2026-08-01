## The value must not be empty. Declared with [method Property.required].
class_name RequiredRule extends ValidationRule


func _init() -> void:
	code = &"required"


func check(context: ValidationContext) -> ValidationResult:
	if not _is_empty(context.value):
		return ValidationResult.ok()
	return _fail(context, "%s is required." % context.property.get_display_name())


static func _is_empty(value: Variant) -> bool:
	if value == null:
		return true
	if value is String:
		return (value as String).strip_edges().is_empty()
	if value is Array or value is Dictionary:
		return value.is_empty()
	return false
