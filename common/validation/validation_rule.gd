## One thing that can be checked about a value.
##
## Each rule is independent and testable on its own, and adding one never touches the
## code that runs them. [ValidationService] collects the rules that apply to a property
## from its declaration and runs them in order.
@abstract
class_name ValidationRule extends RefCounted

## Stable machine code copied onto any issue this rule produces.
var code: StringName = &""
var severity: ValidationIssue.Severity = ValidationIssue.Severity.ERROR
## Phases this rule runs in. Rules that are expensive, or that would fight the user
## mid-keystroke, leave LIVE out.
var phases: Array[ValidationContext.Phase] = [
	ValidationContext.Phase.LIVE,
	ValidationContext.Phase.COMMIT,
	ValidationContext.Phase.AUDIT,
]


func applies_to(context: ValidationContext) -> bool:
	return context.phase in phases


@abstract func check(context: ValidationContext) -> ValidationResult


## Builds a result carrying this rule's code and severity, pinned to the context.
func _fail(context: ValidationContext, message: String) -> ValidationResult:
	var issue: ValidationIssue = ValidationIssue.new()
	issue.severity = severity
	issue.message = message
	issue.code = code
	return ValidationResult.ok().add(context.issue_at(issue))
