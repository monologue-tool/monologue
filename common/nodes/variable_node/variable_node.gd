## Writes to a project variable as the story passes through.
##
## Which variable, how, and with what are three separate properties rather than one
## composite value: each is inspected, validated and undone on its own. The value takes
## the shape the chosen variable declares, so writing text into a number is not
## something this node can express.
class_name VariableNode extends InspectableNode

const OPERATORS: Array = ["=", "+", "-", "*", "/"]


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

	# Reads its shape off the variable named by "target", not off a sibling of its own.
	define_property(Property.new("value")
		.set_type("dynamic")
		.cases("target/type", _value_cases())
		.hidden_in_graph())


func get_type() -> String:
	return "variable"


## The assignment as it would be written: "gold += 3".
func _build_preview(_language: String = "") -> Control:
	var target: String = NodePreview.named(self, "target")
	if target.is_empty():
		return null

	# "=" already is the assignment; the others are compounded onto one.
	var operator: String = str(get_property_value("operator"))
	return NodePreview.line(NodePreview.plain("%s %s= %s" % [
		target, "" if operator == "=" else operator,
		NodePreview.literal(get_property_value("value"))
	]))


## Mirrors the types a variable can declare, in [constant
## VariableCollectionItem.VALUE_TYPES].
func _value_cases() -> Dictionary:
	return {
		"bool": {"type": "bool", "default": false},
		"string": {"type": "text", "default": ""},
		"int": {"type": "int", "default": 0},
		"float": {"type": "float", "default": 0.0},
	}
