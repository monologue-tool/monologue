## Properties which can have language switching.
class_name Localizable extends Property


## Stores the value in a locale dictionary.
var raw_data: Dictionary = {}


## Gets the current language from the language switcher.
func get_locale() -> LanguageOption:
	if GlobalVariables.language_switcher:
		return GlobalVariables.language_switcher.get_current_language()
	else:
		return null


func get_value() -> Variant:
	if GlobalVariables.is_exporting_properties:
		return to_raw_string()
	return raw_data.get(get_locale(), super.get_value())


func set_value(new_value: Variant) -> void:
	if new_value is Dictionary and new_value.keys().has(str(get_locale())):
		raw_data = from_raw_string(new_value)
	else:
		raw_data[get_locale()] = new_value
	super.set_value(new_value)


func from_raw_string(raw_dict: Dictionary) -> Dictionary:
	var language_dict = GlobalVariables.language_switcher.get_languages()
	var new_dict = {}
	for key in raw_dict:
		var locale_string = language_dict.get(key)
		if locale_string:
			new_dict[locale_string] = raw_dict.get(key)
	return new_dict


func to_raw_string() -> Dictionary:
	var new_dict = {}
	for key in raw_data:
		new_dict[str(key)] = raw_data.get(key)
	return new_dict
