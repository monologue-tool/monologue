class_name PropertySettingsChangeCommand extends Command

var target: InspectableObject
var property_name: String
var settings_name: String
var old_value: Variant
var new_value: Variant


func _init(
	p_target: InspectableObject,
	p_property: String,
	p_settings_name: String,
	p_old: Variant,
	p_new: Variant,
) -> void:
	target = p_target
	property_name = p_property
	settings_name = p_settings_name
	old_value = p_old
	new_value = p_new


func execute() -> void:
	var property: Property = target.get_property(property_name)
	property.settings[settings_name] = new_value
	_handle_connection_visibility(new_value)
	target._notify_change(property_name)
	property.refresh_bindings()
	#target._notify_property_settings_change(property_name, settings_name, old_value, new_value)


func undo() -> void:
	var property: Property = target.get_property(property_name)
	if old_value:
		property.settings[settings_name] = old_value
	else:
		property.settings.erase(settings_name)
	_handle_connection_visibility(old_value)
	target._notify_change(property_name)
	property.refresh_bindings()
	#target._notify_property_settings_change(property_name, settings_name, new_value, old_value)


func get_description() -> String:
	return "Change settings of `%s` property" % property_name


func _handle_connection_visibility(setting_value: Variant) -> void:
	if settings_name not in ["exposed", "export"]:
		return
	var node = _get_target_node()
	if not node:
		return
	var graph_view = node.graph_view
	if not graph_view:
		return
	var graph_edit = graph_view.get_parent()
	if not (graph_edit is MonologueGraphEdit):
		return
	var manager: ConnectionManager = graph_edit.connection_manager
	if not manager:
		return
	var node_name: String = graph_view.name
	if settings_name == "exposed":
		if setting_value:
			manager.restore_incoming_property_connections(node_name, property_name)
			return
		manager.suspend_incoming_property_connections(node_name, property_name)
	else:
		if setting_value:
			manager.restore_outgoing_property_connections(node_name, property_name)
			return
		manager.suspend_outgoing_property_connections(node_name, property_name)


func _get_target_node():
	if target is InspectableNode:
		return target
	return null
