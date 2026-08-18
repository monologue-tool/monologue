## A bag of [ValidationIssue]s gathered while doing something that could go wrong:
## reading a project, checking a value, auditing a storyline.
class_name ValidationResult extends RefCounted

var issues: Array[ValidationIssue] = []


static func ok() -> ValidationResult:
	return ValidationResult.new()


static func failure(message: String, code: StringName = &"") -> ValidationResult:
	return ValidationResult.new().add(ValidationIssue.error(message, code))


func add(issue: ValidationIssue) -> ValidationResult:
	if issue:
		issues.append(issue)
	return self


func add_error(message: String, code: StringName = &"") -> ValidationResult:
	return add(ValidationIssue.error(message, code))


func add_warning(message: String, code: StringName = &"") -> ValidationResult:
	return add(ValidationIssue.warning(message, code))


func merge(other: ValidationResult) -> ValidationResult:
	if other:
		issues.append_array(other.issues)
	return self


## True when nothing of ERROR severity was recorded. Warnings do not invalidate.
func is_valid() -> bool:
	return errors().is_empty()


func has_issues() -> bool:
	return not issues.is_empty()


func errors() -> Array[ValidationIssue]:
	return _by_severity(ValidationIssue.Severity.ERROR)


func warnings() -> Array[ValidationIssue]:
	return _by_severity(ValidationIssue.Severity.WARNING)


func with_code(code: StringName) -> Array[ValidationIssue]:
	var matching: Array[ValidationIssue] = []
	for issue: ValidationIssue in issues:
		if issue.code == code:
			matching.append(issue)
	return matching


func first_message() -> String:
	return issues[0].message if has_issues() else ""


func _by_severity(severity: ValidationIssue.Severity) -> Array[ValidationIssue]:
	var matching: Array[ValidationIssue] = []
	for issue: ValidationIssue in issues:
		if issue.severity == severity:
			matching.append(issue)
	return matching


func _to_string() -> String:
	if not has_issues():
		return "ValidationResult(ok)"
	return "ValidationResult(%s)" % ", ".join(issues.map(func(i: ValidationIssue) -> String:
		return str(i)))
