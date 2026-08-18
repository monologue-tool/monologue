## One way out of a called function. Never edited by hand: a call node fills its exit
## list from wherever the function's chain actually runs out.
class_name ExitCollectionItem extends CollectionItem


func initialize_properties() -> void:
	define_property(Property.new("exit")
		.set_type("context")
		.main_property())

	define_name_property()


func get_type() -> String:
	return "exit"


func get_preview_property_names() -> Array[String]:
	return ["name"]
