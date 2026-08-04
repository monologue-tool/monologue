## Brings a character on stage, takes them off, or changes how they are shown.
##
## The three actions do not need the same things: walking off needs only the animation,
## so everything describing the picture is gated on the action and disappears when it
## would mean nothing.
class_name CharacterNode extends InspectableNode

const ACTIONS: Array = ["Join", "Leave", "Update"]
const POSITIONS: Array = ["Left", "Center", "Right"]
## The actions that leave the character on screen, and so need a picture described.
const SHOWING_ACTIONS: Array = ["Join", "Update"]


func initialize_properties() -> void:
	define_property(Property.new("character")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())

	define_property(Property.new("who")
		.set_type("reference")
		.reference_scope("characters")
		.label_property("name")
		.required()
		.tooltip("Who this is about."))

	define_property(Property.new("action")
		.set_type("dropdown")
		.options(ACTIONS)
		.default("Join")
		.required()
		.tooltip("Whether the character comes on, goes off, or only changes."))

	define_property(Property.new("display/portrait")
		.set_type("reference")
		.reference_scope("ref:who:portraits")
		.label_property("name")
		.shown_by("action", SHOWING_ACTIONS)
		.hidden_in_graph()
		.tooltip("Which face to wear. Falls back to the character's default portrait."))

	define_property(Property.new("display/z_index")
		.set_type("int")
		.bounds(-64, 64)
		.shown_by("action", SHOWING_ACTIONS)
		.hidden_in_graph()
		.tooltip("Who stands in front of whom."))

	define_property(Property.new("display/position")
		.set_type("dropdown")
		.options(POSITIONS)
		.default("Left")
		.shown_by("action", SHOWING_ACTIONS)
		.hidden_in_graph()
		.tooltip("Where on screen the character stands."))

	define_property(Property.new("display/flip_h")
		.set_type("bool")
		.shown_by("action", SHOWING_ACTIONS)
		.hidden_in_graph()
		.tooltip("Flips the portrait in the horizontal axis."))

	define_property(Property.new("display/flip_v")
		.set_type("bool")
		.shown_by("action", SHOWING_ACTIONS)
		.hidden_in_graph()
		.tooltip("Flips the portrait in the vertical axis."))

	define_property(Property.new("display/offset")
		.set_type("vector2")
		.shown_by("action", SHOWING_ACTIONS)
		.hidden_in_graph()
		.tooltip("Offset the image from it's original position."))

	define_property(Property.new("animation/curve")
		.set_type("reference")
		.reference_scope("beziers")
		.label_property("name")
		.hidden_in_graph()
		.tooltip("How the move eases. Falls back to the project's default curve."))

	define_property(Property.new("animation/duration")
		.set_type("float")
		.default(0.5)
		.bounds(0.0, 10.0, 0.1)
		.suffix("s")
		.hidden_in_graph()
		.tooltip("How long the move takes. Zero happens at once."))


func get_type() -> String:
	return "character"


## A portrait belongs to one character, so naming another one leaves the node pointing
## at a face its character does not have.
func validate_object(result: ValidationResult, context: ValidationContext) -> void:
	var portrait_id: String = str(get_property_value("portrait"))
	if portrait_id.is_empty() or str(get_property_value("action")) not in SHOWING_ACTIONS:
		return

	if not ReferenceResolver.exists(context.project, "ref:who:portraits", portrait_id, self):
		result.add(
			ValidationIssue.error(
				"This portrait does not belong to the character named here.",
				&"foreign_portrait"
			).at(self, "portrait")
		)
