extends GdUnitTestSuite

## A property can be gated on the value of a sibling: greyed out with enabled_by, taken
## out of the inspector with shown_by. The decision is the object's, since a property on
## its own cannot see what its siblings hold.


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


func test_an_ungated_property_is_always_enabled_and_shown() -> void:
	var object: GatedObject = _object()
	var duration: Property = object.get_property("duration")

	assert_bool(object.is_property_enabled(duration)).is_true()
	assert_bool(object.is_property_shown(duration)).is_true()


func test_a_gated_property_follows_the_property_it_names() -> void:
	var object: GatedObject = _object()
	var max_stack: Property = object.get_property("max_stack")

	assert_bool(object.is_property_enabled(max_stack)).is_true()

	object.get_property("stackable").set_value(false)

	assert_bool(object.is_property_enabled(max_stack)).is_false()


func test_shown_by_accepts_any_of_the_values_it_lists() -> void:
	var object: GatedObject = _object()
	var position: Property = object.get_property("editor_position")

	assert_bool(object.is_property_shown(position)).is_true()

	object.get_property("mode").set_value("Leave")

	assert_bool(object.is_property_shown(position)).is_false()


func test_the_two_gates_are_independent() -> void:
	var object: GatedObject = _object()
	object.get_property("mode").set_value("Leave")

	# Hidden, but nothing says it is disabled: the gates answer different questions.
	assert_bool(object.is_property_shown(object.get_property("editor_position"))).is_false()
	assert_bool(object.is_property_enabled(object.get_property("editor_position"))).is_true()


func test_an_object_knows_which_properties_decide_for_others() -> void:
	var object: GatedObject = _object()

	assert_bool(object.gates_other_properties("stackable")).is_true()
	assert_bool(object.gates_other_properties("mode")).is_true()
	assert_bool(object.gates_other_properties("duration")).is_false()


func test_a_gate_naming_nothing_leaves_the_property_alone() -> void:
	# A typo in a declaration must not quietly freeze half the inspector.
	var property: Property = Property.new("orphan").set_type("text").enabled_by("nonexistent")
	var object: GatedObject = _object()

	assert_bool(object.is_property_enabled(property)).is_true()
