## Describes one field type: how it is edited, how it is drawn as a graph port, and
## which other field types it may connect to.
##
## The editor widget is referenced by uid rather than preloaded so that requiring this
## script does not drag Control and the theme into headless code. Call
## [method get_scene] only from the UI layer.
@abstract
class_name FieldIndexer extends MonologueIndexer

## "uid://" or "res://" of the [Field] scene. Loaded on first use.
var scene_uid: String = ""
## True for port-only pseudo-types (any, context, option) that have no editor widget.
## [method instantiate] returns null for these, by design.
var is_port_only: bool = false
## Value a property of this type starts with when none is given.
var default_value: Variant = null
## Type-level property settings, merged underneath per-property settings.
var default_settings: Dictionary = {}
## Names of other field types this type may connect to in the graph.
## "*" means "any type". Applied to the GraphEdit by
## [method MonologueRegistry.apply_connection_types].
var compatible_types: Array[String] = []
## Type-level validators. See the validation docs for the contract.
var validators: Array[Callable] = []
## Optional normaliser applied to a value before it is stored.
var formatter: Callable
## Assigned by the registry, 1-based. 0 means "not a registered field type".
## Used as the GraphEdit slot type, where 0 is the engine's own default.
var type_id: int = 0

var _scene_cache: PackedScene
var _scene_loaded: bool = false


func get_object_type() -> StringName:
	return MonologueObjectType.FIELD


func validate_registration() -> String:
	var error: String = super.validate_registration()
	if not error.is_empty():
		return error
	if not is_port_only and scene_uid.is_empty():
		return "Field '%s' has no scene_uid and is not marked is_port_only." % name
	return ""


## Loads the widget scene on first call and caches it. Null when [member is_port_only].
func get_scene() -> PackedScene:
	if _scene_loaded:
		return _scene_cache
	_scene_loaded = true
	if is_port_only or scene_uid.is_empty():
		return null
	var resource: Resource = load(scene_uid)
	if resource is PackedScene:
		_scene_cache = resource
	else:
		push_error("Field '%s': scene_uid '%s' is not a PackedScene." % [name, scene_uid])
	return _scene_cache


## Returns a new [Field] widget, or null for port-only types.
## Prefer [FieldWidgetFactory] over calling this directly.
func instantiate(_history: CommandManager = null) -> Object:
	var scene: PackedScene = get_scene()
	if scene == null or not scene.can_instantiate():
		return null
	var instance: Node = scene.instantiate()
	if instance is Field:
		return instance
	push_error("Field '%s': scene root does not extend Field." % name)
	instance.free()
	return null


## Rules every property of this field type is checked against, on top of whatever the
## property itself declares. Running them is [ValidationService]'s job.
func get_validation_rules() -> Array[ValidationRule]:
	var rules: Array[ValidationRule] = []
	for validator: Callable in validators:
		rules.append(CallableRule.new(validator, StringName("type:%s" % name)))
	return rules


## Returns the ids of every object a value of this type points at.
##
## The default is "no references". Override for composite types that embed one, such
## as `condition`, which stores a variable id inside its Dictionary. This is what lets
## the project build a reverse reference index without any node class knowing about it.
func extract_references(_value: Variant) -> PackedStringArray:
	return PackedStringArray()
