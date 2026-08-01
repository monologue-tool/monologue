## Wraps a check written by hand next to the property it guards:
## [codeblock]
## define_property(Property.new("name")
##     .set_type("text")
##     .validate(_must_be_an_identifier))
##
## func _must_be_an_identifier(context: ValidationContext) -> Variant:
##     if str(context.value).is_valid_identifier():
##         return null
##     return "Use letters, digits and underscores only."
## [/codeblock]
##
## The function may take a [ValidationContext] or just the value, and may return
## null / true (fine), false (generic failure), a String (that message), or a
## [ValidationIssue] / [ValidationResult] used as-is. See [method _coerce].
class_name CallableRule extends ValidationRule

var function: Callable


func _init(
	p_function: Callable,
	p_code: StringName = &"custom",
	p_severity: ValidationIssue.Severity = ValidationIssue.Severity.ERROR
) -> void:
	function = p_function
	code = p_code
	severity = p_severity


func check(context: ValidationContext) -> ValidationResult:
	if not function.is_valid():
		return ValidationResult.ok()

	# Accept both shapes so a one-line check does not have to take a context it
	# will not use.
	var raw: Variant = (
		function.call(context) if function.get_argument_count() >= 1 else function.call()
	)
	return _coerce(context, raw)


func _coerce(context: ValidationContext, raw: Variant) -> ValidationResult:
	if raw == null:
		return ValidationResult.ok()
	if raw is ValidationResult:
		return raw
	if raw is ValidationIssue:
		return ValidationResult.ok().add(context.issue_at(raw))
	if raw is bool:
		return ValidationResult.ok() if raw else _fail(context, "Invalid value.")
	if raw is String:
		var message: String = (raw as String).strip_edges()
		return ValidationResult.ok() if message.is_empty() else _fail(context, message)

	push_warning(
		"Validator for '%s' returned %s, which means nothing." % [
			context.property.name, type_string(typeof(raw))
		]
	)
	return ValidationResult.ok()
