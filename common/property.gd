# gdlint: disable=max-public-methods
## One property of an [InspectableObject]: what it is called, what type of value it
## holds, how it is presented, and what it currently contains.
##
## Declared inside [method InspectableObject.initialize_properties], one option per
## line so the whole shape of a property is readable at a glance:
## [codeblock]
## define_property(Property.new("speaker/name")
##     .set_type("reference")
##     .required()
##     .tooltip("Who says this line."))
## [/codeblock]
##
## The path given to [method _init] is "category/name". A path with no slash lands in
## the General category, so "notes" and "general/notes" mean the same thing. The
## category segment is title-cased for display: "extra/notes" shows under "Extra".
##
## Once the owning object has finished declaring, the property is frozen: the methods
## below stop having any effect, and only the value and the user's own overrides can
## still change. That is what stops one node from quietly diverging from every other
## node of the same type.
##
## Pure data: it knows nothing about widgets or the scene tree, so it can be built and
## asserted on without booting the editor. The UI observes it through
## [signal value_changed] and [signal settings_changed].
class_name Property extends RefCounted

## Separates the category from the name in the path given to [method _init].
const PATH_SEPARATOR: String = "/"

signal value_changed(old_value: Variant, new_value: Variant)
signal connection_changed
## Emitted when a runtime override changes, e.g. the user toggling a port on.
## Bound fields refresh themselves from this.
signal settings_changed

## Machine name. Also the JSON key this property is saved under.
var name: String = ""
## Name of the field type used to edit it. Set with [method set_type].
var type: String = ""
## What a fresh instance starts with. May be a [Callable], evaluated per instance.
## Defaults to the field type's own default until [method default] says otherwise.
var default_value: Variant = null
var value: Variant = null

## Input connections. Each entry: {"node_id": String, "property_name": String}.
var connected_from: Array[Dictionary] = []
## Output connections. Each entry: {"node_id": String, "property_name": String}.
var connected_to: Array[Dictionary] = []

## What is currently wrong with this property's value. Transient: filled in by
## [ValidationService], rendered by the bound field, never serialized.
var issues: Array[ValidationIssue] = []

## Declared in code. Frozen once the owning object is built.
var _settings: Dictionary = {}
## Checks declared with [method validate] / [method warn_if].
var _validation_rules: Array[ValidationRule] = []
## Changed by the user at runtime. The only part saved as "_editor_settings".
var _overrides: Dictionary = {}
## Keys this declaration set explicitly, so a later [method set_type] cannot undo them.
var _declared_keys: Dictionary = {}
var _has_explicit_default: bool = false
var _frozen: bool = false


## [param path] is "category/name", or just "name" for the General category.
func _init(path: String) -> void:
	_settings = PropertySettings.DEFAULTS.duplicate(true)

	var separator_index: int = path.rfind(PATH_SEPARATOR)
	if separator_index == -1:
		name = path
	else:
		name = path.substr(separator_index + 1)
		var raw_category: String = path.substr(0, separator_index)
		_settings[PropertySettings.KEY_CATEGORY] = Util.to_readable_name(raw_category)


## Sets the field type used to edit this property, and folds in that type's own
## defaults underneath anything this declaration has already stated.
##
## Order-independent: calling it before or after the other methods gives the same
## result, and it never overwrites a default set with [method default].
func set_type(type_name: String) -> Property:
	if _frozen:
		_warn_frozen()
		return self

	type = type_name
	# The one place a property consults the type registry. The registry is headless,
	# so this keeps working outside the editor.
	var indexer: FieldIndexer = MonologueRegistry.get_instance().get_field(type_name)
	if indexer:
		for key: String in indexer.default_settings:
			if not _declared_keys.has(key):
				_settings[key] = indexer.default_settings[key]
		if not _has_explicit_default:
			default_value = indexer.default_value

	value = resolve_default()
	return self


## Overrides the field type's default. Only needed when this property should start
## with something else.
func default(new_default: Variant) -> Property:
	if _frozen:
		_warn_frozen()
		return self

	_has_explicit_default = true
	default_value = new_default
	value = resolve_default()
	return self


## Overrides the inspector label. Defaults to a readable form of the name.
func label(text: String) -> Property:
	return set_setting(PropertySettings.KEY_LABEL, text)


func tooltip(text: String) -> Property:
	return set_setting(PropertySettings.KEY_TOOLTIP, text)


## Overrides the category taken from the declaration path.
func category(category_name: String) -> Property:
	return set_setting(PropertySettings.KEY_CATEGORY, category_name)


func hidden_in_graph() -> Property:
	return set_setting(PropertySettings.KEY_VISIBLE_IN_GRAPH, false)


func hidden_in_inspector() -> Property:
	return set_setting(PropertySettings.KEY_VISIBLE_IN_INSPECTOR, false)


## Renders without a background panel.
func flat() -> Property:
	return set_setting(PropertySettings.KEY_FLAT, true)


## Belongs in the inspector's header strip rather than a category section: compact,
## panel-less, and never drawn as a graph row. Used by id and color.
func header() -> Property:
	category("Special:Header")
	hidden_in_graph()
	return flat()


func no_expand() -> Property:
	return set_setting(PropertySettings.KEY_EXPAND, false)


## Shown in the inspector and editable. Use after [method main_property], which hides
## the property by default.
func editable() -> Property:
	set_setting(PropertySettings.KEY_VISIBLE_IN_INSPECTOR, true)
	return set_setting(PropertySettings.KEY_EDITABLE, true)


## Shown but frozen. Unlike [method not_editable], stays visible in the inspector.
func read_only() -> Property:
	return set_setting(PropertySettings.KEY_READ_ONLY, true)


## Hidden from the inspector entirely unless read-only or carrying a port.
func not_editable() -> Property:
	return set_setting(PropertySettings.KEY_EDITABLE, false)


## Marks the owning list item as undeletable.
func protected() -> Property:
	return set_setting(PropertySettings.KEY_PROTECT, true)


## The object's primary connectable property: drawn first in the graph, so it owns
## port index 0, and hidden from the inspector.
##
## Call this before the port overrides, so exposed()/exported() have the last word.
func main_property() -> Property:
	set_setting(PropertySettings.KEY_IS_MAIN_PROPERTY, true)
	set_setting(PropertySettings.KEY_VISIBLE_IN_GRAPH, true)
	set_setting(PropertySettings.KEY_VISIBLE_IN_INSPECTOR, false)
	set_setting(PropertySettings.KEY_EDITABLE, false)
	return set_setting(PropertySettings.KEY_EXPOSABLE, true)


## Input port on the left of the graph node.
func exposed(is_exposed: bool = true) -> Property:
	return set_setting(PropertySettings.KEY_EXPOSED, is_exposed)


## Output port on the right of the graph node.
func exported(is_exported: bool = true) -> Property:
	return set_setting(PropertySettings.KEY_EXPORT, is_exported)


## Prevents the user toggling the input port from the inspector.
func not_exposable() -> Property:
	return set_setting(PropertySettings.KEY_EXPOSABLE, false)


## "normal" or "large".
func port_size(size: String) -> Property:
	return set_setting(PropertySettings.KEY_PORT_SIZE, size)


## (collection) Name of the collection type each item is built from.
func collection(collection_name: String) -> Property:
	return set_setting(PropertySettings.KEY_COLLECTION, collection_name)


## (list) Field type of each item.
func item_type(field_type: String) -> Property:
	return set_setting(PropertySettings.KEY_ITEM_TYPE, field_type)


## (dropdown) Static choices.
func options(values: Array) -> Property:
	return set_setting(PropertySettings.KEY_OPTIONS, values)


## (dropdown) Dynamic choices: a collection name, or "self:<property>".
func source(source_path: String) -> Property:
	return set_setting(PropertySettings.KEY_SOURCE, source_path)


## (reference) Where the target is looked up: a collection name, "self:<property>",
## "storylines", or "node:<type>".
func reference_scope(scope: String) -> Property:
	return set_setting(PropertySettings.KEY_REFERENCE_SCOPE, scope)


## (reference) Property of the target used as its label. Defaults to "name".
func label_property(property_name: String) -> Property:
	return set_setting(PropertySettings.KEY_LABEL_PROPERTY, property_name)


## (reference) Accepts "nothing selected" as a value.
func allow_empty(is_allowed: bool = true) -> Property:
	return set_setting(PropertySettings.KEY_ALLOW_EMPTY, is_allowed)


## (text / translatable) Renders a multi-line editor.
func multiline(rows: int = 3) -> Property:
	set_setting(PropertySettings.KEY_MULTILINE, true)
	return set_setting(PropertySettings.KEY_ROWS, rows)


func placeholder(text: String) -> Property:
	return set_setting(PropertySettings.KEY_PLACEHOLDER, text)


## (file) Dialog filters such as ["*.png"]. Empty means no filter.
func file_filters(filters: Array) -> Property:
	return set_setting(PropertySettings.KEY_FILE_FILTERS, filters)


## (dynamic) Swaps the widget based on a sibling property's value.
func cases(case_property: String, case_map: Dictionary) -> Property:
	set_setting(PropertySettings.KEY_CASE_PROPERTY, case_property)
	return set_setting(PropertySettings.KEY_CASES, case_map)


func required() -> Property:
	return set_setting(PropertySettings.KEY_REQUIRED, true)


## Value must differ from every sibling item's value for the same property.
func unique_among_siblings() -> Property:
	return set_setting(PropertySettings.KEY_UNIQUE, true)


## Attaches a check written next to the property it guards. [param function] takes a
## [ValidationContext] (or nothing) and returns null/true when the value is fine, or a
## String / [ValidationIssue] describing what is wrong:
## [codeblock]
## define_property(Property.new("name")
##     .set_type("text")
##     .validate(_must_be_an_identifier))
## [/codeblock]
func validate(function: Callable, code: StringName = &"custom") -> Property:
	if _frozen:
		_warn_frozen()
		return self
	_validation_rules.append(CallableRule.new(function, code))
	return self


## Same as [method validate], but reports a warning instead of an error, so it shows up
## in the problems panel without marking the value broken.
func warn_if(function: Callable, code: StringName = &"custom") -> Property:
	if _frozen:
		_warn_frozen()
		return self
	_validation_rules.append(
		CallableRule.new(function, code, ValidationIssue.Severity.WARNING)
	)
	return self


## Rules declared with [method validate] / [method warn_if]. Read by ValidationService.
func get_validation_rules() -> Array[ValidationRule]:
	return _validation_rules


func min_length(length: int) -> Property:
	return _add_rule("min_length", length)


func max_length(length: int) -> Property:
	return _add_rule("max_length", length)


## Named value_range so it does not shadow GDScript's own range().
func value_range(minimum: float, maximum: float) -> Property:
	_add_rule("min", minimum)
	return _add_rule("max", maximum)


## Sets one declared setting. Prefer a named method when one exists; this is for keys
## a plugin defines that the core knows nothing about.
func set_setting(key: String, setting_value: Variant) -> Property:
	if _frozen:
		_warn_frozen()
		return self
	_settings[key] = setting_value
	_declared_keys[key] = true
	return self


func set_settings(values: Dictionary) -> Property:
	for key: String in values:
		set_setting(key, values[key])
	return self


## Called by the owning object once it has finished declaring. Idempotent.
func freeze() -> void:
	_frozen = true


func is_frozen() -> bool:
	return _frozen


## The value a fresh instance starts with: evaluates a [Callable] default, and
## deep-copies containers so two objects never share one Array.
func resolve_default() -> Variant:
	var resolved: Variant = default_value
	if resolved is Callable:
		resolved = (resolved as Callable).call()
	if resolved is Dictionary or resolved is Array:
		return resolved.duplicate(true)
	return resolved


func set_value(new_value: Variant) -> void:
	if typeof(value) == typeof(new_value) and value == new_value:
		return
	var old_value: Variant = value
	value = new_value
	value_changed.emit(old_value, new_value)


func get_value() -> Variant:
	return value


## Records a user override, which survives into the save file. Distinct from
## [method set_setting], which declares the default and is frozen after startup.
func set_settings_value(key: String, setting_value: Variant) -> void:
	_overrides[key] = setting_value
	settings_changed.emit()


func erase_settings_value(key: String) -> void:
	if _overrides.erase(key):
		settings_changed.emit()


## Declared settings with the user's runtime overrides applied on top.
func get_settings() -> Dictionary:
	var merged: Dictionary = _settings.duplicate(true)
	merged.merge(_overrides, true)
	return merged


func has_settings(key: String) -> bool:
	return _overrides.has(key) or _settings.has(key)


func get_settings_value(key: String, fallback: Variant = null) -> Variant:
	if _overrides.has(key):
		return _overrides[key]
	return _settings.get(key, fallback)


func get_display_name() -> String:
	var custom_label: String = get_settings_value(PropertySettings.KEY_LABEL, "")
	return Util.to_readable_name(custom_label if not custom_label.is_empty() else name)


func get_category() -> String:
	return get_settings_value(PropertySettings.KEY_CATEGORY, "General")


## "category/name", the same shape the declaration used.
func get_path() -> String:
	return "%s%s%s" % [get_category(), PATH_SEPARATOR, name]


func is_main_property() -> bool:
	return get_settings_value(PropertySettings.KEY_IS_MAIN_PROPERTY, false) == true


func is_input_connected() -> bool:
	return connected_from.size() > 0


func is_output_connected() -> bool:
	return connected_to.size() > 0


func is_port_connected() -> bool:
	return is_input_connected() or is_output_connected()


## True when this property should be a row in the graph node view: either it is marked
## visible, or it carries at least one port.
func is_visible_in_graph() -> bool:
	var has_input: bool = get_settings_value(PropertySettings.KEY_EXPOSED, false) == true
	var has_output: bool = get_settings_value(PropertySettings.KEY_EXPORT, false) == true
	var visible: bool = get_settings_value(PropertySettings.KEY_VISIBLE_IN_GRAPH, true) == true
	return visible or has_input or has_output


func add_connection_from(node_id: String, property_name: String) -> void:
	var connection: Dictionary = {"node_id": node_id, "property_name": property_name}
	if connection not in connected_from:
		connected_from.append(connection)
		connection_changed.emit()


func add_connection_to(node_id: String, property_name: String) -> void:
	var connection: Dictionary = {"node_id": node_id, "property_name": property_name}
	if connection not in connected_to:
		connected_to.append(connection)
		connection_changed.emit()


func remove_connection_from(node_id: String, property_name: String) -> void:
	_remove_connection(connected_from, node_id, property_name)


func remove_connection_to(node_id: String, property_name: String) -> void:
	_remove_connection(connected_to, node_id, property_name)


func clear_connections() -> void:
	var had_connections: bool = not connected_from.is_empty() or not connected_to.is_empty()
	connected_from.clear()
	connected_to.clear()
	if had_connections:
		connection_changed.emit()


func _warn_frozen() -> void:
	push_error("Property '%s' is frozen; declare it in initialize_properties()." % name)


func _add_rule(rule_name: String, rule_value: Variant) -> Property:
	var rules: Dictionary = _settings.get(PropertySettings.KEY_VALIDATION, {}).duplicate(true)
	rules[rule_name] = rule_value
	return set_setting(PropertySettings.KEY_VALIDATION, rules)


func _remove_connection(
	connections: Array[Dictionary], node_id: String, property_name: String
) -> void:
	var previous_size: int = connections.size()
	connections.assign(
		connections.filter(
			(func(entry: Dictionary) -> bool:
				return not (entry["node_id"] == node_id and entry["property_name"] == property_name))
		)
	)
	if connections.size() != previous_size:
		connection_changed.emit()


func _to_dict() -> Dictionary:
	var dict: Dictionary = {"value": get_value()}

	if not connected_from.is_empty():
		dict["from_node"] = connected_from
	if not connected_to.is_empty():
		dict["to_node"] = connected_to
	if not _overrides.is_empty():
		dict["_editor_settings"] = _overrides

	return dict


func _from_dict(raw: Dictionary) -> void:
	if raw.is_empty():
		return

	value = raw.get("value", value)
	_overrides = raw.get("_editor_settings", _overrides)
	if raw.get("from_node"):
		connected_from.assign(raw.get("from_node", []))
	if raw.get("to_node"):
		connected_to.assign(raw.get("to_node", []))
