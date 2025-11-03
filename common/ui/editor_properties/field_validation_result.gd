class_name FieldValidationResult extends RefCounted

var is_valid: bool
var message: String


func _init(p_is_valid: bool = true, p_message: String = "") -> void:
	is_valid = p_is_valid
	message = p_message


static func success() -> FieldValidationResult:
	return FieldValidationResult.new(true, "")


static func failure(error_message: String) -> FieldValidationResult:
	return FieldValidationResult.new(false, error_message)
