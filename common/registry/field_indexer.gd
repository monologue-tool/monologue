## Describes one field type. How it is edited, how it is drawn as a graph port, and which
## other field types it may connect to.
@abstract
class_name FieldIndexer extends MonologueIndexer

## "uid://" or "res://" of the [Field] scene. Loaded on first use.
var scene_uid: String = ""
## True for port-only pseudo-types (any, context, option). [method instantiate] returns null
## for those.
var is_port_only: bool = false
var default_value: Variant = null
## Type-level property settings, merged underneath per-property settings.
var default_settings: Dictionary = {}
## Other field types this one may connect to. "*" means any.
var compatible_types: Array[String] = []
var validators: Array[Callable] = []
var formatter: Callable
## GraphEdit slot type, assigned by the registry. 1-based: 0 is GraphEdit's own default and
## means "not registered".
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


## Null for port-only types. Prefer [FieldWidgetFactory] to calling this.
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


## On top of what the property itself declares. [ValidationService] runs them.
func get_validation_rules() -> Array[ValidationRule]:
	var rules: Array[ValidationRule] = []
	for validator: Callable in validators:
		rules.append(CallableRule.new(validator, StringName("type:%s" % name)))
	return rules


## Feeds the project's reverse reference index. Override for composite types that embed a
## reference, such as `condition`, which holds a variable id inside its Dictionary.
func extract_references(_value: Variant) -> PackedStringArray:
	return PackedStringArray()
