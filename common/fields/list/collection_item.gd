@abstract
class_name CollectionItem extends InspectableObject

var storyline_id: String = ""
var _main_property_defined: bool = false


func _init(command_manager: CommandManager = null) -> void:
	super._init(command_manager)


## The identifying name almost every collection item carries: required, unique among
## its siblings, non-empty, and protecting the item from deletion.
func define_name_property(default_value: Variant) -> Property:
	return define_property(Property.new("name")
		.set_type("text")
		.default(default_value)
		.required()
		.unique_among_siblings()
		.protected()
		.min_length(1))


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
