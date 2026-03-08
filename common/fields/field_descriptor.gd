class_name FieldDescriptor extends BucketDescriptor

var scene: PackedScene
var color: Color = Color.WHITE
var default_settings: Dictionary = {}
var validators: Array[Callable] = []
var formatter: Callable
var type_id: int = -1
## Names of other field types that this type is connection-compatible with.
var compatible_types: Array[String] = []
var default_value: Variant = null


func _init(p_name: String = "", p_scene: PackedScene = null, metadata: Dictionary = {}) -> void:
	@warning_ignore_start("unsafe_method_access")
	super._init(p_name, metadata)
	scene = p_scene
	default_value = metadata.get("default_value", null)
	var raw_color: Variant = metadata.get("color")
	if raw_color is Color:
		color = raw_color
	elif raw_color is String and not raw_color.is_empty():
		color = Color(str(raw_color))
	default_settings = metadata.get("default_settings", {}).duplicate(true)
	var validator_list: Variant = metadata.get("validators")
	if validator_list is Array:
		for validator: Variant in validator_list:
			if validator is Callable:
				var valid_callable: Callable = validator
				register_validator(valid_callable)
	var raw_formatter: Variant = metadata.get("formatter")
	if raw_formatter is Callable and raw_formatter.is_valid():
		formatter = raw_formatter
	@warning_ignore_restore("unsafe_method_access")


func instantiate_field() -> Field:
	if not scene:
		return null
	var instance: Node = scene.instantiate()
	if instance is Field:
		return instance
	push_error("FieldDescriptor '%s' scene does not inherit Field." % name)
	return null


func register_validator(validator: Callable) -> void:
	if validator is Callable and validator.is_valid():
		validators.append(validator)


func validate(value: Variant) -> FieldValidationResult:
	for validator: Callable in validators:
		var result: Variant = validator.call(value)
		if result is FieldValidationResult:
			if not result.is_valid:
				return result
		elif result is bool:
			if not result:
				return FieldValidationResult.failure("Validation failed.")
		elif result is String:
			var message: String = str(result).strip_edges()
			if not message.is_empty():
				return FieldValidationResult.failure(message)
	return FieldValidationResult.success()


func format(value: Variant) -> Variant:
	if formatter and formatter.is_valid():
		return formatter.call(value)
	return value


func to_metadata() -> Dictionary:
	var base: Dictionary = super.to_metadata()
	base["color"] = color
	base["type_id"] = type_id
	base["default_settings"] = default_settings.duplicate(true)
	base["compatible_types"] = compatible_types.duplicate()
	
	return base
