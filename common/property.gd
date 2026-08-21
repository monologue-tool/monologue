# gdlint: disable=max-public-methods
## One property of an [InspectableObject]. What it is called, what it holds, how it is
## presented, and its current value.
##
## Declared from [method InspectableObject.initialize_properties], one option per line.
##
## The path is "category/name". With no slash it lands in General, so "notes" and
## "general/notes" mean the same thing. The category is title-cased for display.
##
## Once the owning object has finished declaring, the property freezes. The builder methods
## below stop having any effect. Only the value and the user's overrides still change.
class_name Property extends RefCounted

## Separates the category from the name in the path given to [method _init].
const PATH_SEPARATOR: String = "/"

signal value_changed(old_value: Variant, new_value: Variant)
signal connection_changed
## A runtime override changed, such as the user toggling a port on. Bound fields refresh
## themselves from this.
signal settings_changed

## Machine name. Also the JSON key this property is saved under.
var name: String = ""
var type: String = ""
## What a fresh instance starts with. A [Callable] here is evaluated per instance. Falls
## back to the field type's own default.
var default_value: Variant = null
var value: Variant = null

## Incoming wires, as {"node_id": String, "property_name": String, "item_id"?: String}.
## A read-only view. The wires live in [member StorylineDocument.connections], which refills
## this. Never serialized.
var connected_from: Array[Dictionary] = []
## Outgoing wires, in the same shape as [member connected_from].
var connected_to: Array[Dictionary] = []

## What is currently wrong with the value. Filled in by [ValidationService], rendered by the
## bound field, never serialized.
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


## Sets the field type, and folds that type's defaults in underneath anything already
## stated here. Can be called before or after the other methods, and never overwrites a
## default set with [method default].
func set_type(type_name: String) -> Property:
	if _frozen:
		_warn_frozen()
		return self

	type = type_name
	# The one place a property consults the type registry, which is headless, so this keeps
	# working outside the editor.
	var indexer: FieldIndexer = MonologueRegistry.get_instance().get_field(type_name)
	if indexer:
		for key: String in indexer.default_settings:
			if not _declared_keys.has(key):
				_settings[key] = indexer.default_settings[key]

	_refresh_default()
	return self


## (text) Stores a plain String instead of translations. For anything the player never
## reads, like ids, labels and authoring notes.
func plain() -> Property:
	set_setting(PropertySettings.KEY_TRANSLATABLE, false)
	_refresh_default()
	return self


## (text) Stores translations keyed by language code. Already the case for `text`, useful
## on `textarea`, which is plain by default.
func translatable() -> Property:
	set_setting(PropertySettings.KEY_TRANSLATABLE, true)
	_refresh_default()
	return self


func is_translatable() -> bool:
	return get_settings_value(PropertySettings.KEY_TRANSLATABLE, false) == true


## Re-derives the starting value from the field type and whether the property is translated.
## Run whenever either changes, so the declaration reads the same in any order.
func _refresh_default() -> void:
	if _has_explicit_default:
		return

	var indexer: FieldIndexer = MonologueRegistry.get_instance().get_field(type)
	var base: Variant = indexer.default_value if indexer else null
	if is_translatable() and base is String:
		base = {}
	default_value = base
	value = resolve_default()


func default(new_default: Variant) -> Property:
	if _frozen:
		_warn_frozen()
		return self

	_has_explicit_default = true
	default_value = new_default
	value = resolve_default()
	return self


## Defaults to a readable form of the name.
func label(text: String) -> Property:
	return set_setting(PropertySettings.KEY_LABEL, text)


func tooltip(text: String) -> Property:
	return set_setting(PropertySettings.KEY_TOOLTIP, text)


func category(category_name: String) -> Property:
	return set_setting(PropertySettings.KEY_CATEGORY, category_name)


func hidden_in_graph() -> Property:
	return set_setting(PropertySettings.KEY_VISIBLE_IN_GRAPH, false)


func hidden_in_inspector() -> Property:
	return set_setting(PropertySettings.KEY_VISIBLE_IN_INSPECTOR, false)


func flat() -> Property:
	return set_setting(PropertySettings.KEY_FLAT, true)


## Puts the property in the inspector's header strip instead of a category section.
## Compact, panel-less, never drawn as a graph row. Used by id and color.
func header() -> Property:
	category("Special:Header")
	hidden_in_graph()
	return flat()


func no_expand() -> Property:
	return set_setting(PropertySettings.KEY_EXPAND, false)


## Shown in the inspector and editable. Use after [method main_property], which hides it.
func editable() -> Property:
	set_setting(PropertySettings.KEY_VISIBLE_IN_INSPECTOR, true)
	return set_setting(PropertySettings.KEY_EDITABLE, true)


## Shown but frozen. Unlike [method not_editable], stays visible.
func read_only() -> Property:
	return set_setting(PropertySettings.KEY_READ_ONLY, true)


## Hidden from the inspector entirely unless read-only or carrying a port.
func not_editable() -> Property:
	return set_setting(PropertySettings.KEY_EDITABLE, false)


func protected() -> Property:
	return set_setting(PropertySettings.KEY_PROTECT, true)


## Greys this property out unless [param property_name] holds one of [param values]:
## [codeblock]
## define_property(Property.new("display/max_stack")
##     .set_type("int")
##     .enabled_by("stackable"))
## [/codeblock]
## The property stays where it is.
func enabled_by(property_name: String, values: Array = [true]) -> Property:
	return set_setting(
		PropertySettings.KEY_ENABLED_BY, {"property": property_name, "values": values}
	)


## Hides this property unless [param property_name] holds one of [param values]. For
## settings another choice makes meaningless, like where a character stands when the action
## is to walk off.
func shown_by(property_name: String, values: Array = [true]) -> Property:
	return set_setting(
		PropertySettings.KEY_SHOWN_BY, {"property": property_name, "values": values}
	)


## The gate declared under [param key], or an empty Dictionary when nothing gates this
## property. See [method enabled_by] and [method shown_by].
func get_gate(key: StringName) -> Dictionary:
	var gate: Variant = get_settings_value(key, {})
	return gate if gate is Dictionary else {}


## The object's primary connectable property. Drawn first in the graph, so it owns port
## index 0, and hidden from the inspector.
##
## Call it before the port overrides, so exposed() and exported() have the last word.
func main_property() -> Property:
	set_setting(PropertySettings.KEY_IS_MAIN_PROPERTY, true)
	set_setting(PropertySettings.KEY_VISIBLE_IN_GRAPH, true)
	set_setting(PropertySettings.KEY_VISIBLE_IN_INSPECTOR, false)
	set_setting(PropertySettings.KEY_EDITABLE, false)
	return set_setting(PropertySettings.KEY_EXPOSABLE, true)


func exposed(is_exposed: bool = true) -> Property:
	return set_setting(PropertySettings.KEY_EXPOSED, is_exposed)


func exported(is_exported: bool = true) -> Property:
	return set_setting(PropertySettings.KEY_EXPORT, is_exported)


func not_exposable() -> Property:
	return set_setting(PropertySettings.KEY_EXPOSABLE, false)


## "normal" or "large".
func port_size(size: String) -> Property:
	return set_setting(PropertySettings.KEY_PORT_SIZE, size)


func collection(collection_name: String) -> Property:
	return set_setting(PropertySettings.KEY_COLLECTION, collection_name)


func item_type(field_type: String) -> Property:
	return set_setting(PropertySettings.KEY_ITEM_TYPE, field_type)


func options(values: Array) -> Property:
	return set_setting(PropertySettings.KEY_OPTIONS, values)


## (dropdown) Dynamic choices. A collection name, or "self:<property>".
func source(source_path: String) -> Property:
	return set_setting(PropertySettings.KEY_SOURCE, source_path)


## (reference) Where the target is looked up. A collection name, "self:<property>",
## "storylines", or "node:<type>".
func reference_scope(scope: String) -> Property:
	return set_setting(PropertySettings.KEY_REFERENCE_SCOPE, scope)


## (reference) Property of the target used as its label. Defaults to "name".
func label_property(property_name: String) -> Property:
	return set_setting(PropertySettings.KEY_LABEL_PROPERTY, property_name)


## (reference) Accepts "nothing selected" as a value.
func allow_empty(is_allowed: bool = true) -> Property:
	return set_setting(PropertySettings.KEY_ALLOW_EMPTY, is_allowed)


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


func unique_among_siblings() -> Property:
	return set_setting(PropertySettings.KEY_UNIQUE, true)


## Attaches a check next to the property it guards. [param function] takes a
## [ValidationContext] or nothing, and returns null or true when the value is fine, or a
## String or [ValidationIssue] saying what is wrong:
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


## Like [method validate], but reports a warning. Shows in the problems panel without
## marking the value broken.
func warn_if(function: Callable, code: StringName = &"custom") -> Property:
	if _frozen:
		_warn_frozen()
		return self
	_validation_rules.append(
		CallableRule.new(function, code, ValidationIssue.Severity.WARNING)
	)
	return self


## Rules declared with [method validate] and [method warn_if].
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


## (int / float) The range the widget offers, and the range the value is checked against.
## Declaring no bounds lets the number drag freely and shows no fill.
func bounds(minimum: float, maximum: float, step: float = 1.0) -> Property:
	set_setting(PropertySettings.KEY_MIN_VALUE, minimum)
	set_setting(PropertySettings.KEY_MAX_VALUE, maximum)
	set_setting(PropertySettings.KEY_STEP, step)
	return value_range(minimum, maximum)


## (int / float) Unit shown next to the number, such as "s" or "dB".
func suffix(text: String) -> Property:
	return set_setting(PropertySettings.KEY_SUFFIX, text)


## Sets one declared setting. Prefer a named method when one exists. This is for keys a
## plugin defines that the core knows nothing about.
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


## The value a fresh instance starts with. Evaluates a [Callable] default, and deep-copies
## containers so two objects never share one Array.
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


## Records a user override, which is saved. Unlike [method set_setting], which declares the
## default and freezes after startup.
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


## True when this property should be a row in the graph node view. Either it is marked
## visible, or it carries a port.
func is_visible_in_graph() -> bool:
	var has_input: bool = get_settings_value(PropertySettings.KEY_EXPOSED, false) == true
	var has_output: bool = get_settings_value(PropertySettings.KEY_EXPORT, false) == true
	var visible: bool = get_settings_value(PropertySettings.KEY_VISIBLE_IN_GRAPH, true) == true
	return visible or has_input or has_output


## True when the story goes in one side of this property and out the other. A node with
## one of these can be dropped into the middle of a chain.
func is_pass_through() -> bool:
	return (
		get_settings_value(PropertySettings.KEY_EXPOSED, false) == true
		and get_settings_value(PropertySettings.KEY_EXPORT, false) == true
	)


## Replaces the cached views, announcing the change only when there is one. Called by
## [StorylineDocument], which holds the wires.
func set_connection_views(incoming: Array, outgoing: Array) -> void:
	if connected_from == incoming and connected_to == outgoing:
		return
	connected_from.assign(incoming)
	connected_to.assign(outgoing)
	connection_changed.emit()


func _warn_frozen() -> void:
	push_error("Property '%s' is frozen; declare it in initialize_properties()." % name)


func _add_rule(rule_name: String, rule_value: Variant) -> Property:
	var rules: Dictionary = _settings.get(PropertySettings.KEY_VALIDATION, {}).duplicate(true)
	rules[rule_name] = rule_value
	return set_setting(PropertySettings.KEY_VALIDATION, rules)


## Restores what was saved. The owning object keeps every override in one map, so they
## arrive separately from the value.
func _restore(stored_value: Variant, stored_overrides: Dictionary) -> void:
	value = stored_value
	_overrides = stored_overrides.duplicate(true)


func _get_overrides() -> Dictionary:
	return _overrides
