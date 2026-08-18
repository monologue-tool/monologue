@abstract
class_name CollectionItem extends InspectableObject

var storyline_id: String = ""
var _main_property_defined: bool = false


func _init(command_manager: CommandManager = null) -> void:
	super._init(command_manager)


## Required, unique among its siblings, non-empty, and protects the item from deletion.
##
## With no [param default_value] the name comes from the item's id, so a fresh item already
## has one nothing else uses.
func define_name_property(default_value: Variant = null) -> Property:
	return define_property(Property.new("name")
		.set_type("text")
		.plain()
		.default(default_value if default_value != null else _generate_name())
		.required()
		.unique_among_siblings()
		.protected()
		.min_length(1))


## Lets one item of the collection be nominated as the fallback, like the portrait a
## character shows when a node names none.
##
## At most one item carries the flag. [CollectionField] keeps that true and
## [method ReferenceResolver.find_default] reads it.
func define_default_property() -> Property:
	return define_property(Property.new("extra/is_default")
		.set_type("bool")
		.hidden_in_inspector()
		.hidden_in_graph()
		.not_exposable())


func is_default_item() -> bool:
	return get_property_value("is_default") == true


## "variable-K4M2XQ7B" becomes "variable_K4M2XQ7B". Unique because the id is, and a valid
## identifier, which conditions and setters need of a variable name.
func _generate_name() -> String:
	return str(get_property_value("id")).replace("-", "_")


## An item with a main property is exported as a sub-port on the node owning the list.
func define_property(property: Property) -> Property:
	if property.is_main_property():
		if _main_property_defined:
			push_error("%s declares more than one main property." % get_type())
		_main_property_defined = true
	return super.define_property(property)


func has_main_property() -> bool:
	return _main_property_defined


@abstract func get_preview_property_names() -> Array[String]
