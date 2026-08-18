class_name MonologueProblem extends RefCounted

enum Severity {
	CRITICAL, ## The story can't run at all.
	ERROR, ## The story cannot be trusted to run past this.
	WARNING, ## The story runs, but something doesn't work as intended.
}

var severity: Severity = Severity.ERROR
var code: StringName = &""
var message: String = ""
var storyline_id: String = ""
var node_id: String = ""
var document: String = ""


static func critical(p_code: StringName, p_message: String) -> MonologueProblem:
	return _make(Severity.CRITICAL, p_code, p_message)


static func error(p_code: StringName, p_message: String) -> MonologueProblem:
	return _make(Severity.ERROR, p_code, p_message)


static func warning(p_code: StringName, p_message: String) -> MonologueProblem:
	return _make(Severity.WARNING, p_code, p_message)


## Pins the problem to a node, and to the storyline it belongs to.
func at(p_node_id: String, p_storyline_id: String = "") -> MonologueProblem:
	node_id = p_node_id
	if not p_storyline_id.is_empty():
		storyline_id = p_storyline_id
	return self


func in_document(p_document: String) -> MonologueProblem:
	document = p_document
	return self


func is_error() -> bool:
	return severity == Severity.ERROR


func to_dict() -> Dictionary:
	return {
		"severity": "error" if is_error() else "warning",
		"code": String(code),
		"message": message,
		"storyline_id": storyline_id,
		"node_id": node_id,
		"document": document,
	}


func _to_string() -> String:
	var place: String = node_id if not node_id.is_empty() else document
	if place.is_empty():
		return "[%s] %s" % [code, message]
	return "[%s] %s (%s)" % [code, message, place]


static func _make(
	p_severity: Severity, p_code: StringName, p_message: String
) -> MonologueProblem:
	var problem: MonologueProblem = MonologueProblem.new()
	problem.severity = p_severity
	problem.code = p_code
	problem.message = p_message
	return problem
