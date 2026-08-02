## Calls out to the game: a name the runtime recognises, and whatever it needs with it.
##
## Monologue does not interpret either; it carries them across so the game can act on
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


func get_type() -> String:
	return "action"
