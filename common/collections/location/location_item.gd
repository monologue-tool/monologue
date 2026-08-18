## A place the story happens in, and the states it can be seen in.
class_name LocationCollectionItem extends CollectionItem


func initialize_properties() -> void:
	var default_variation: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		"variations", history
	)
	default_variation.set_property_value("name", "default")
	default_variation.set_property_value("protected", true)
	default_variation.set_property_value("is_default", true)

	define_name_property()

	define_property(Property.new("display_name")
		.set_type("text"))

	define_property(Property.new("variations/variations")
		.set_type("collection")
		.default([default_variation._to_dict()])
		.collection("variations")
		.warn_if(_has_no_variation, &"no_variations"))

	define_property(Property.new("extra/description")
		.set_type("textarea"))

	define_property(Property.new("extra/tags")
		.set_type("list")
		.item_type("text"))


func get_type() -> String:
	return "location"


func get_preview_property_names() -> Array[String]:
	return ["name", "description"]


## Not an error: a location with no variation is still somewhere the story can be, it
## just cannot be shown.
func _has_no_variation(context: ValidationContext) -> Variant:
	if context.value is Array and (context.value as Array).is_empty():
		return "%s has no variation." % get_property_value("name")
	return null
