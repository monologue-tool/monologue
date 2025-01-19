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
	GlobalSignal.add_listener("language_deleted", store_data)


## Gets the current language from the language switcher.
func get_locale() -> LanguageOption:
	if GlobalVariables.language_switcher:
		return GlobalVariables.language_switcher.get_current_language()
	else:
		return null


func get_value() -> Variant:
	if GlobalVariables.language_switcher:
		return raw_data.get(get_locale().name, initialized_value)
	return super.get_value()


func set_value(new_value: Variant) -> void:
	if GlobalVariables.language_switcher:
		var langs = GlobalVariables.language_switcher.get_languages().keys()
		if new_value is Dictionary and Util.is_any_inside(new_value.keys(), langs):
			raw_data = _from_raw_value(new_value)
		else:
			raw_data[get_locale().name] = new_value
	super.set_value(new_value)


func store_data(node_name: String, restoration: Dictionary, _choices: Dictionary) -> void:
	if raw_data.has(node_name):
		restoration[self] = raw_data.duplicate(true)


## Export property value as localized dictionary.
func to_raw_value() -> Variant:
	if GlobalVariables.language_switcher:
		var new_dict = {}
		for key in raw_data:
			var option = GlobalVariables.language_switcher.get_by_node_name(key)
			if option:
				new_dict[str(option)] = raw_data.get(key, initialized_value)
		return new_dict
	return value


## Private method to load property value is a localized dictionary.
func _from_raw_value(string_dict: Dictionary) -> Dictionary:
	var language_dict = GlobalVariables.language_switcher.get_languages()
	var new_dict = {}
	for key in string_dict:
		var language_node_name = language_dict.get(key)
		if language_node_name:
			new_dict[language_node_name] = string_dict.get(key)
	return new_dict
