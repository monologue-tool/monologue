# gdlint: disable=max-public-methods
@abstract
class_name InspectableObject extends Resource

## Names a saved object's type. Reserved: no property may be called this.
const TYPE_KEY: String = "$type"
## Holds every property's user overrides, keyed by property name. Also reserved.
const EDITOR_SETTINGS_KEY: String = "_editor_settings"

signal property_changed(property_name: String)

var _properties: Dictionary[String, Property] = {}
var _children: Dictionary[String, Array] = {}  # Children object of properties
var history: CommandManager
var settings: Dictionary = {}
var _parent_object: InspectableObject
var _parent_property_name: String
## True once _init() has finished declaring. Anything declared after that is frozen on
## the spot, so a subclass adding properties after super._init() is still safe.
var _is_sealed: bool = false


func get_parent_object() -> InspectableObject:
	return _parent_object


func get_parent_property_name() -> String:
	return _parent_property_name


func _set_parent_info(parent: InspectableObject, pname: String) -> void:
	_parent_object = parent
	_parent_property_name = pname


func _init(command_manager: CommandManager = null) -> void:
	if not command_manager:
		push_warning("InspectableObject created without a command manager.")
	history = command_manager

	define_property(Property.new("id")
		.set_type("text")
		.plain()
		.default(IDGen.generate_object_id(get_type()))
		.read_only()
		.hidden_in_inspector()
		.hidden_in_graph()
		.unique_among_siblings())

	initialize_properties()
	_seal_properties()


## Closes the schema: from here a property's type, default, settings and rules are
## fixed, and only its value and the user's own overrides may still change. That is
## what stops one instance of a type from quietly diverging from every other instance.
##
## A subclass may declare after calling super._init(), past this point;
## [method define_property] freezes those on the spot, so declaration order is free.
func _seal_properties() -> void:
	for property: Property in _properties.values():
		property.freeze()
	_is_sealed = true
	_load_settings()


func _load_settings() -> void:
	var new_settings: Dictionary = {}
	new_settings.merge(get_settings(), true)
	settings = new_settings


## Registers a property on this object. Build and configure it inline, one option per
## line, and hand it over:
## [codeblock]
## define_property(Property.new("speaker/name")
##     .set_type("reference")
##     .required()
##     .tooltip("Who says this line."))
## [/codeblock]
##
## The path is "category/name"; see [Property] for the details. Returns the same
## property, for the rare case a declaration needs to keep a reference to it.
func define_property(property: Property) -> Property:
	if property.type.is_empty():
		push_error("Property '%s' on %s has no type; call set_type()." % [property.name, get_type()])
	if _properties.has(property.name):
		push_error("Property '%s' is declared twice on %s." % [property.name, get_type()])
	_properties.set(property.name, property)

	property.value_changed.connect(
		func(_old: Variant, _new: Variant) -> void: property_changed.emit(property.name)
	)

	# A subclass may declare after calling super._init(), which is past the freeze pass.
	# Freezing here keeps the invariant regardless of declaration order.
	if _is_sealed:
		property.freeze()

	return property


func get_properties() -> Array[Property]:
	var properties: Array[Property] = []
	for pname: String in _properties.keys():
		properties.append(_properties[pname])

	return properties


func get_property(pname: String) -> Property:
	return _properties.get(pname)


func get_property_value(pname: String) -> Variant:
	var property: Property = get_property(pname)
	if not property:
		return
	return property.get_value()


func get_property_settings_value(pname: String, skey: String) -> Variant:
	var property: Property = get_property(pname)
	return property._overrides.get(skey)


func set_property_value(pname: String, pvalue: Variant) -> void:
	if not _properties.has(pname):
		return

	var old_value: Variant = get_property_value(pname)

	if typeof(pvalue) == typeof(old_value) and pvalue == old_value:
		return

	var command: PropertyChangeCommand = PropertyChangeCommand.new(self, pname, old_value, pvalue)
	history.execute(command)


func set_property_settings_value(pname: String, skey: String, svalue: Variant) -> void:
	if not _properties.has(pname):
		return

	var old_value: Variant = get_property_settings_value(pname, skey)

	var command: PropertySettingsChangeCommand = PropertySettingsChangeCommand.new(
		self, pname, skey, old_value, svalue
	)
	history.execute(command)


## Whether [param property] may currently be edited, given the property gating it.
## True when nothing gates it. See [method Property.enabled_by].
func is_property_enabled(property: Property) -> bool:
	return _is_gate_open(property.get_gate(PropertySettings.KEY_ENABLED_BY))


## Whether [param property] currently belongs in the inspector, given the property
## gating it. True when nothing gates it. See [method Property.shown_by].
func is_property_shown(property: Property) -> bool:
	return _is_gate_open(property.get_gate(PropertySettings.KEY_SHOWN_BY))


## True when some property is gated on [param property_name], so a change to it changes
## what the inspector should be showing.
func gates_other_properties(property_name: String) -> bool:
	for property: Property in get_properties():
		for key: StringName in [PropertySettings.KEY_ENABLED_BY, PropertySettings.KEY_SHOWN_BY]:
			if str(property.get_gate(key).get("property", "")) == property_name:
				return true
	return false


## A gate is open when nothing was declared, and when the property it names holds one of
## the values it lists. A gate pointing at a property this object does not have is open
## too: a declaration typo should not silently freeze half the inspector.
func _is_gate_open(gate: Dictionary) -> bool:
	if gate.is_empty():
		return true

	var source: Property = get_property(str(gate.get("property", "")))
	if source == null:
		return true

	var accepted: Variant = gate.get("values", [])
	if accepted is not Array:
		return true
	return source.get_value() in (accepted as Array)


func get_property_children(property_name: String) -> Array:
	return _children.get(property_name, [])


## Every child list this object holds, whatever property they hang off.
func get_all_property_children() -> Array:
	return _children.values()


## Cross-property checks that no single property can express. Default is no-op;
## override where one property's value constrains another:
## [codeblock]
## func validate_object(result: ValidationResult, _context: ValidationContext) -> void:
##     if get_property_value("enable_condition") and get_property_value("condition").is_empty():
##         result.add(ValidationIssue.warning("Condition is on but empty.", &"empty_condition"))
## [/codeblock]
func validate_object(_result: ValidationResult, _context: ValidationContext) -> void:
	pass


func set_property_children(property_name: String, objects: Array) -> void:
	for object: InspectableObject in objects:
		if not object.property_changed.is_connected(_on_property_children_property_change):
			object.property_changed.connect(
				_on_property_children_property_change.bind(property_name)
			)
		object._set_parent_info(self, property_name)

	_children[property_name] = objects


func add_property_children(property_name: String, object: InspectableObject) -> void:
	if not object.property_changed.is_connected(_on_property_children_property_change):
		object.property_changed.connect(_on_property_children_property_change.bind(property_name))
	object._set_parent_info(self, property_name)

	_children.get_or_add(property_name, [])
	_children.get(property_name).append(object)


func remove_property_children(property_name: String, object: InspectableObject) -> void:
	if not property_name in _children:
		return
	if object.property_changed.is_connected(_on_property_children_property_change):
		object.property_changed.disconnect(_on_property_children_property_change)
	object._set_parent_info(null, "")
	_children.get(property_name).erase(object)


func move_property_child(property_name: String, object: InspectableObject, to_index: int) -> void:
	if not property_name in _children:
		return

	var children_array: Array = _children.get(property_name)
	var current_index: int = children_array.find(object)

	if current_index == -1:
		return

	if to_index < 0:
		to_index = 0
	if to_index >= children_array.size():
		to_index = children_array.size() - 1

	children_array.remove_at(current_index)
	children_array.insert(to_index, object)


func _on_property_children_property_change(
	_children_property_name: String, property_name: String
) -> void:
	var childrens: Array = get_property_children(property_name)
	var value: Array = []
	for object: InspectableObject in childrens:
		value.append(object._to_dict())

	set_property_value(property_name, value)


## Writes each property under its own name, holding its value and nothing else. The
## user's port toggles and other overrides are gathered into one map beside them, so a
## saved value never has to share its slot with editor bookkeeping.
func _to_dict() -> Dictionary:
	var dict: Dictionary = {TYPE_KEY: get_type()}
	var overrides: Dictionary = {}

	for property: Property in get_properties():
		dict[property.name] = property.get_value()
		var property_overrides: Dictionary = property._get_overrides()
		if not property_overrides.is_empty():
			overrides[property.name] = property_overrides

	if not overrides.is_empty():
		dict[EDITOR_SETTINGS_KEY] = overrides

	return dict


func _from_dict(dict: Dictionary) -> void:
	var overrides: Dictionary = dict.get(EDITOR_SETTINGS_KEY, {})
	for property: Property in get_properties():
		property._restore(
			dict.get(property.name, property.get_value()), overrides.get(property.name, {})
		)


func get_settings() -> Dictionary:
	return {}


## Returns external list items for a given list property (e.g. connected OptionNodes).
## Override in subclasses that support externally-sourced list items.
func get_external_list_items(_property_name: String) -> Array[Dictionary]:
	return []


func rebuild_preview() -> void:
	pass


@warning_ignore("native_method_override")
func duplicate(deep: bool = false) -> Resource:
	var duplicated: InspectableNode = super.duplicate(deep)
	duplicated.history = history
	duplicated.settings = settings

	for property: Property in get_properties():
		var d_prop: Property = duplicated.get_property(property.name)
		d_prop.value = property.get_value()

	return duplicated


@abstract func get_type() -> String
@abstract func initialize_properties() -> void
