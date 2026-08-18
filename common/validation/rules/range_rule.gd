## Bounds on a numeric value. Declared with [method Property.value_range].
class_name RangeRule extends ValidationRule

var minimum: Variant = null
var maximum: Variant = null


func _init(p_minimum: Variant = null, p_maximum: Variant = null) -> void:
	code = &"range"
	minimum = p_minimum
	maximum = p_maximum


func check(context: ValidationContext) -> ValidationResult:
	if not _is_numeric(context.value):
		return ValidationResult.ok()

	var number: float = float(context.value)
	if minimum != null and number < float(minimum):
		return _fail(context, "Must be at least %s." % str(minimum))
	if maximum != null and number > float(maximum):
		return _fail(context, "Must be at most %s." % str(maximum))
	return ValidationResult.ok()


static func _is_numeric(value: Variant) -> bool:
	if value is int or value is float:
		return true
	return value is String and (value as String).is_valid_float()
