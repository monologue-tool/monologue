## The target of a reference must still exist.
##
## Applied to every property of type "reference". Reports the missing id rather than
## repairing anything: the value stays put so that restoring the target, by undo or by
## hand, makes the reference work again.
class_name ReferenceRule extends ValidationRule


func _init() -> void:
	code = &"dangling_reference"
	# Needs the whole project to answer, so it stays out of the typing path.
	phases = [ValidationContext.Phase.COMMIT, ValidationContext.Phase.AUDIT]


func check(context: ValidationContext) -> ValidationResult:
	var target_id: String = str(context.value) if context.value != null else ""
	if target_id.is_empty():
		return ValidationResult.ok()

	# Without a project there is nothing to look the target up in, which is the case in
	# unit tests for other rules; silence beats a false alarm.
	if context.project == null:
		return ValidationResult.ok()

	var scope: String = str(context.setting(PropertySettings.KEY_REFERENCE_SCOPE, ""))
	if scope.is_empty():
		return ValidationResult.ok()

	if ReferenceResolver.exists(context.project, scope, target_id, context.object):
		return ValidationResult.ok()

	return _fail(
		context,
		(
			"%s points at '%s', which no longer exists."
			% [context.property.get_display_name(), target_id]
		)
	)
