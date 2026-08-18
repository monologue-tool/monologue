## Issues are collected into a [ValidationResult] and surfaced to the user.
class_name ValidationIssue extends RefCounted

enum Severity {
	ERROR,
	WARNING,
	INFO,
}

var severity: Severity = Severity.ERROR
var message: String = ""
## Stable machine code such as &"unreadable_json" or &"dangling_reference".
## Tests and the problems panel filter on this, so it is never translated.
var code: StringName = &""
## Where the issue was found. Any of these may be empty.
var document_name: String = ""
var object_id: String = ""
var property_name: String = ""


static func error(issue_message: String, issue_code: StringName = &"") -> ValidationIssue:
	return _make(Severity.ERROR, issue_message, issue_code)


static func warning(issue_message: String, issue_code: StringName = &"") -> ValidationIssue:
	return _make(Severity.WARNING, issue_message, issue_code)


static func info(issue_message: String, issue_code: StringName = &"") -> ValidationIssue:
	return _make(Severity.INFO, issue_message, issue_code)


static func _make(
	issue_severity: Severity, issue_message: String, issue_code: StringName
) -> ValidationIssue:
	var issue: ValidationIssue = ValidationIssue.new()
	issue.severity = issue_severity
	issue.message = issue_message
	issue.code = issue_code
	return issue


## Pins the issue to an object, and optionally to one of its properties. Chainable.
func at(object: InspectableObject, target_property: String = "") -> ValidationIssue:
	if object:
		object_id = str(object.get_property_value("id"))
	property_name = target_property
	return self


func in_document(name: String) -> ValidationIssue:
	document_name = name
	return self


func is_error() -> bool:
	return severity == Severity.ERROR


## Human-readable "document > object > property", skipping whatever is unknown.
func get_location() -> String:
	var parts: PackedStringArray = []
	for part: String in [document_name, object_id, property_name]:
		if not part.is_empty():
			parts.append(part)
	return " > ".join(parts)


func _to_string() -> String:
	var location: String = get_location()
	if location.is_empty():
		return message
	return "%s (%s)" % [message, location]
