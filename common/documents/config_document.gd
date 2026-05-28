class_name ConfigurationDocument extends InspectableDocument

func initialize_properties() -> void:
	define_property("show_project_explorer", true, "bool", {}, "Interface")
	define_property("show_inspector", true, "bool", {}, "Interface")
	define_property("show_console", false, "bool", {}, "Interface")
	define_property("show_status_bar", true, "bool", {}, "Interface")
	
	define_property("snap", false, "bool", {}, "Graph")
	define_property("show_grid", true, "bool", {}, "Graph")

func set_property_value(pname: String, pvalue: Variant) -> void:
	super.set_property_value(pname, pvalue)
	ConfigManager.save_configuration()

func get_type() -> String:
	return "preferences"
