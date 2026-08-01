@abstract
class_name CollectionItem extends InspectableObject

var storyline_id: String = ""
var _main_property_defined: bool = false


func _init(command_manager: CommandManager = null) -> void:
	super._init(command_manager)


## The identifying name almost every collection item carries: required, unique among
## its siblings, non-empty, and protecting the item from deletion.
##
## With no [param default_value] the name is derived from the item's id, so a fresh
## item already has one nothing else uses.
func define_name_property(default_value: Variant = null) -> Property:
	return define_property(Property.new("name")
		.set_type("text")
		.default(default_value if default_value != null else _generate_name())
		.required()
		.unique_among_siblings()
		.protected()
		.min_length(1))


## Turns "variable-K4M2XQ7B" into "variable_K4M2XQ7B": unique because the id is, and a
## valid identifier, which is what conditions and setters need of a variable name.
func _generate_name() -> String:
	return str(get_property_value("id")).replace("-", "_")


## Tracks the main property as it is declared. An item with one is exported as a
## sub-port on the graph node that owns the list.
func define_property(property: Property) -> Property:
	if property.is_main_property():
		if _main_property_defined:
			push_error("%s declares more than one main property." % get_type())
		_main_property_defined = true
	return super.define_property(property)


func has_main_property() -> bool:
	return _main_property_defined


func _on_property_changed(_pname: String) -> void:
	pass


@abstract func get_preview_property_names() -> Array[String]
