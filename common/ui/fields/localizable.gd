## Properties which can have language switching.
class_name Localizable extends Property


## Stores the value in a locale dictionary.
var raw_data: Dictionary = {}
## The value to be initialized on a new locale. Empty string by default.
var initialized_value: Variant


func _init(ui_scene: PackedScene, ui_setters: Dictionary = {},
			default: Variant = "") -> void:
	super(ui_scene, ui_setters, default)
	initialized_value = default


## Gets the current language from the language switcher.
func get_locale() -> LanguageOption:
	if GlobalVariables.language_switcher:
		return GlobalVariables.language_switcher.get_current_language()
	else:
		return null


func get_value() -> Variant:
	if GlobalVariables.language_switcher:
		return raw_data.get(get_locale(), initialized_value)
	return super.get_value()


func set_value(new_value: Variant) -> void:
	if GlobalVariables.language_switcher:
		var langs = GlobalVariables.language_switcher.get_languages().keys()
		if new_value is Dictionary and Util.is_inside(new_value.keys(), langs):
			raw_data = _from_raw_value(new_value)
		else:
			raw_data[get_locale()] = new_value
	super.set_value(new_value)


## Export property value as localized dictionary.
func to_raw_value() -> Variant:
	if GlobalVariables.language_switcher:
		var language_dict = GlobalVariables.language_switcher.get_languages()
		var new_dict = {}
		for key in raw_data:
			if language_dict.has(str(key)):
				new_dict[str(key)] = raw_data.get(key, initialized_value)
		return new_dict
	return value


## Private method to load property value is a localized dictionary.
func _from_raw_value(raw_dict: Dictionary) -> Dictionary:
	var language_dict = GlobalVariables.language_switcher.get_languages()
	var new_dict = {}
	for key in raw_dict:
		var language_option = language_dict.get(key)
		if language_option:
			new_dict[language_option] = raw_dict.get(key)
	return new_dict
