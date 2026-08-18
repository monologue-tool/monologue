extends GdUnitTestSuite

## A property can be gated on the value of a sibling: greyed out with enabled_by, taken out
## of the inspector with shown_by. The decision is the object's, since a property on its own
## cannot see what its siblings hold.


class GatedObject extends InspectableObject:
	func initialize_properties() -> void:
		define_property(Property.new("mode")
			.set_type("dropdown")
			.options(["Join", "Leave"])
			.default("Join"))

		define_property(Property.new("stackable")
			.set_type("bool")
			.default(true))

		define_property(Property.new("max_stack")
			.set_type("int")
			.enabled_by("stackable"))

		define_property(Property.new("editor_position")
			.set_type("text")
			.shown_by("mode", ["Join"]))

		define_property(Property.new("duration")
			.set_type("float"))

	func get_type() -> String:
		return "gated"


func _object() -> GatedObject:
	return GatedObject.new(CommandManager.new())


func test_a_gate_follows_what_it_names_and_the_two_gates_stay_apart() -> void:
	var object: GatedObject = _object()
	var ungated: Property = object.get_property("duration")
	var enabled_gate: Property = object.get_property("max_stack")
	var shown_gate: Property = object.get_property("editor_position")

	for property: Property in [ungated, enabled_gate, shown_gate]:
		assert_bool(object.is_property_enabled(property)).is_true()
		assert_bool(object.is_property_shown(property)).is_true()

	object.get_property("stackable").set_value(false)
	object.get_property("mode").set_value("Leave")

	assert_bool(object.is_property_enabled(enabled_gate)).is_false()
	assert_bool(object.is_property_shown(shown_gate)).is_false()

	# The gates answer different questions: hidden does not mean disabled, and the ungated
	# property is untouched by either.
	assert_bool(object.is_property_shown(enabled_gate)).is_true()
	assert_bool(object.is_property_enabled(shown_gate)).is_true()
	assert_bool(object.is_property_enabled(ungated)).is_true()
	assert_bool(object.is_property_shown(ungated)).is_true()


func test_an_object_knows_who_decides_and_shrugs_at_a_gate_naming_nothing() -> void:
	var object: GatedObject = _object()

	assert_bool(object.gates_other_properties("stackable")).is_true()
	assert_bool(object.gates_other_properties("mode")).is_true()
	assert_bool(object.gates_other_properties("duration")).is_false()

	# A typo in a declaration must not quietly freeze half the inspector.
	var orphan: Property = Property.new("orphan").set_type("text").enabled_by("nonexistent")
	assert_bool(object.is_property_enabled(orphan)).is_true()
