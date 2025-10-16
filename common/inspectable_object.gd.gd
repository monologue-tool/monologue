@abstract
class_name InspectableObject extends RefCounted

var _properties: Dictionary[String, Property] = {}
var _observers: Array[Object] = []


func _init() -> void:
	define_property("id", IDGen.generate(), "text", {})


func define_property(
	pname: String, default_value: Variant, type: String, options: Dictionary = {}
) -> void:
	var property: Property = Property.new(pname, default_value, type, options)
	_properties.set(pname, property)

	property.add_observer(
		func(opname: String, old_value: Variant, new_value: Variant) -> void:
			_notify_change(opname, old_value, new_value)
			_on_property_changed(opname, old_value, new_value)
	)


func add_observer(object: Object) -> void:
	if object in _observers:
		push_warning("Observer is already registered.")
		return

	_observers.append(object)


func _notify_change(pname: String, old_value: Variant, new_value: Variant) -> void:
	for observer: Object in _observers:
		if not observer.has_method("on_property_changed"):
			push_warning("Object doesn't have method 'on_property_changed'.")
			return

		observer.call("on_property_changed", pname, old_value, new_value)


func get_properties() -> Array[Property]:
	var properties: Array[Property] = []
	for pname in _properties.keys():
		properties.append(_properties[pname])

	return properties


func get_property(pname: String) -> Property:
	return _properties.get(pname)


func get_property_value(pname: String) -> Variant:
	return get_property(pname).get_value()


func set_property_value(pname: String, pvalue: Variant) -> void:
	if not _properties.has(pname):
		return

	var property: Property = get_property(pname)
	property.set_value(pvalue)


func _to_dict() -> Dictionary:
	var dict: Dictionary = {"$type": get_type()}
	for property: Property in get_properties():
		dict[property.name] = property.value

	return dict


@abstract func get_type() -> String
@abstract func initialize_properties() -> void
@abstract func _on_property_changed(pname: String, old_value: Variant, new_value: Variant) -> void
