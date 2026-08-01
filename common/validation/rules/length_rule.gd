## Bounds on how long a text value may be.
## Declared with [method Property.min_length] and [method Property.max_length].
class_name LengthRule extends ValidationRule

var minimum: int = -1
var maximum: int = -1


func _init(p_minimum: int = -1, p_maximum: int = -1) -> void:
	code = &"length"
	minimum = p_minimum
	maximum = p_maximum


func check(context: ValidationContext) -> ValidationResult:
	var length: int = str(context.value).length() if context.value != null else 0

	if minimum >= 0 and length < minimum:
		return _fail(context, "Must be at least %d character(s)." % minimum)
	if maximum >= 0 and length > maximum:
		return _fail(context, "Must be at most %d character(s)." % maximum)
	return ValidationResult.ok()
