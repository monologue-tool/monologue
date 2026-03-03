class_name FieldDescriptor extends BucketDescriptor

var scene: PackedScene
var color: Color = Color.WHITE
var default_settings: Dictionary = {}
var validators: Array[Callable] = []
var formatter: Callable
var type_id: int = -1


func _init(p_name: String = "", p_scene: PackedScene = null, metadata: Dictionary = {}) -> void:
	super._init(p_name, metadata)
	scene = p_scene
	var raw_color = metadata.get("color")
	if raw_color is Color:
		color = raw_color
	elif raw_color is String and not raw_color.is_empty():
		color = Color(raw_color)
	default_settings = metadata.get("default_settings", {}).duplicate(true)
	var validator_list = metadata.get("validators")
	if validator_list is Array:
		for validator in validator_list:
			register_validator(validator)
	var raw_formatter = metadata.get("formatter")
	if raw_formatter is Callable and raw_formatter.is_valid():
		formatter = raw_formatter


func instantiate_field() -> Field:
	if not scene:
		return null
	var instance = scene.instantiate()
	if instance is Field:
		return instance
	push_error("FieldDescriptor '%s' scene does not inherit Field." % name)
	return null


func register_validator(validator: Callable) -> void:
	if validator is Callable and validator.is_valid():
		validators.append(validator)


func validate(value: Variant):
	for validator in validators:
		var result = validator.call(value)
		if result is FieldValidationResult:
			if not result.is_valid:
				return result
		elif result is bool:
			if not result:
				return FieldValidationResult.failure("Validation failed.")
		elif result is String:
			var message := (result as String).strip_edges()
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
	return base
