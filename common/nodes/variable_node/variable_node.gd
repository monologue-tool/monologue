## Writes to a project variable as the story passes through.
##
## Which variable, how, and with what are three separate properties rather than one
## composite value: each is inspected, validated and undone on its own.
class_name VariableNode extends InspectableNode

const OPERATORS: Array = ["=", "+", "-", "*", "/"]
## Value shapes offered, and the variable type each one answers for.
const VALUE_CASES: Dictionary = {
	"Text": {"type": "text", "default": ""},
	"Number": {"type": "float", "default": 0.0},
	"Flag": {"type": "bool", "default": false},
}
const VARIABLE_TYPE_BY_CASE: Dictionary = {
	"Text": "string", "Number": "int", "Flag": "bool"
}


func initialize_properties() -> void:
	define_property(Property.new("variable")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())

	define_property(Property.new("target")
		.set_type("reference")
		.reference_scope("variables")
		.required()
		.tooltip("Variable to write to."))

	define_property(Property.new("operator")
		.set_type("dropdown")
		.options(OPERATORS)
		.default("=")
		.hidden_in_graph())

	define_property(Property.new("value_type")
		.set_type("dropdown")
		.options(VALUE_CASES.keys())
		.default("Text")
		.hidden_in_graph()
		.tooltip("What kind of value to write. Must match the variable."))

	define_property(Property.new("value")
		.set_type("dynamic")
		.cases("value_type", VALUE_CASES)
		.hidden_in_graph())


func get_type() -> String:
	return "variable"


## Writing text into a number is the mistake this node makes easy, and the one nothing
## else would catch until the story ran.
func validate_object(result: ValidationResult, context: ValidationContext) -> void:
	var target: String = str(get_property_value("target"))
	if target.is_empty() or context.project == null:
		return

	var declared: String = _variable_type(context.project, target)
	var expected: String = VARIABLE_TYPE_BY_CASE.get(str(get_property_value("value_type")), "")
	if declared.is_empty() or expected.is_empty():
		return

	var numeric: Array = ["int", "float"]
	if declared == expected or (declared in numeric and expected in numeric):
		return

	result.add(
		ValidationIssue.warning(
			"This writes a %s into '%s', which holds a %s." % [expected, target, declared],
			&"value_type_mismatch"
		).at(self, "value_type")
	)


static func _variable_type(project: MonologueProject, variable_id: String) -> String:
	for entry: Variant in project.get_collection_value("variables"):
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == variable_id:
			return str((entry as Dictionary).get("type", ""))
	return ""
