## Calls out to the game: a name the runtime recognises, and whatever it needs with it.
##
## Monologue interprets neither. It carries them across so the game can act on
## them. What the names mean is the game's business.
class_name ActionNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("action")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())

	define_property(Property.new("name")
		.set_type("text")
		.plain()
		.required()
		.placeholder("play_cutscene")
		.tooltip("What the game should do. Matched by the runtime, never by Monologue."))

	define_property(Property.new("arguments")
		.set_type("list")
		.item_type("text")
		.hidden_in_graph()
		.tooltip("Passed through in order, as written."))

	define_property(Property.new("wait")
		.set_type("bool")
		.default(false)
		.hidden_in_graph()
		.tooltip("Hold the story until the game says it is done."))

	define_property(Property.new("result")
		.set_type("reference")
		.reference_scope("variables")
		.label_property("name")
		.hidden_in_graph()
		.tooltip("Variable to keep what the game answers in."))


func get_type() -> String:
	return "action"


## The call as the game receives it: name and what is passed with it.
func _build_preview(_language: String = "") -> Control:
	var action_name: String = str(get_property_value("name")).strip_edges()
	if action_name.is_empty():
		return null

	var written: PackedStringArray = []
	var arguments: Variant = get_property_value("arguments")
	if arguments is Array:
		for argument: Variant in arguments:
			written.append(NodePreview.literal(argument))
	var call_out: String = "%s(%s)" % [action_name, ", ".join(written)]
	var into: String = NodePreview.named(self, "result")
	if into.is_empty():
		return NodePreview.line(NodePreview.plain(call_out))
	return NodePreview.line(NodePreview.plain("%s \u2192 %s" % [call_out, into]))
