## Development node exercising every field type at once, so a change to the field
## system can be eyeballed in one place. Hidden from the add-node menu.
class_name ZooNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("zoo")
		.set_type("context")
		.main_property()
		.exposed(false)
		.exported())

	_define_text_properties()
	_define_value_properties()
	_define_reference_properties()
	_define_list_properties()

	define_property(Property.new("condition/condition")
		.set_type("condition")
		.default({}))


func get_type() -> String:
	return "zoo"


func _define_text_properties() -> void:
	define_property(Property.new("text/text")
		.set_type("text"))

	define_property(Property.new("text/textarea")
		.set_type("textarea"))

	define_property(Property.new("text/plain")
		.set_type("text")
		.plain())

	define_property(Property.new("text/translated_multiline")
		.set_type("text")
		.multiline())


func _define_value_properties() -> void:
	define_property(Property.new("values/bool")
		.set_type("bool"))

	define_property(Property.new("values/color2")
		.set_type("color")
		.default("#3b5dc9"))

	define_property(Property.new("values/dynamic_dropdown")
		.set_type("dropdown")
		.default("string")
		.required()
		.options(VariableCollectionItem.VALUE_TYPES))

	define_property(Property.new("values/dynamic")
		.set_type("dynamic")
		.default("abc")
		.cases("dynamic_dropdown", _dynamic_cases()))

	define_property(Property.new("values/float")
		.set_type("float")
		.default(10.0))

	define_property(Property.new("values/int")
		.set_type("int")
		.default(10))

	# Bounded, so the fill bar is exercised next to the unbounded int and float above.
	define_property(Property.new("values/bounded_float")
		.set_type("float")
		.default(10.0)
		.bounds(0.0, 100.0, 0.5)
		.suffix("%"))

	define_property(Property.new("values/vector2")
		.set_type("vector2"))

	define_property(Property.new("values/bezier")
		.set_type("bezier"))


func _define_reference_properties() -> void:
	define_property(Property.new("references/file")
		.set_type("file"))

	define_property(Property.new("references/dropdown")
		.set_type("dropdown")
		.source("characters"))

	define_property(Property.new("references/character")
		.set_type("reference")
		.reference_scope("characters"))

	define_property(Property.new("references/storyline")
		.set_type("reference")
		.reference_scope("storylines"))

	# Points into this node's own collection property, so the broken-reference chip can
	# be seen by deleting the item it names.
	define_property(Property.new("references/own_item")
		.set_type("reference")
		.reference_scope("self:collection"))


func _define_list_properties() -> void:
	define_property(Property.new("list/collection")
		.set_type("collection")
		.collection("characters"))

	define_property(Property.new("list/collection_dropdown")
		.set_type("dropdown")
		.source("self:collection"))

	define_property(Property.new("list/list")
		.set_type("list")
		.item_type("text"))

	define_property(Property.new("list/list_dropdown")
		.set_type("dropdown")
		.source("self:list"))


func _dynamic_cases() -> Dictionary:
	return {
		"bool": {"type": "bool", "default": false},
		"string": {"type": "text", "default": "", "coerce": "string"},
		"int": {"type": "int", "default": 0, "coerce": "int"},
		"float": {"type": "float", "default": 0.0, "coerce": "float"},
	}
