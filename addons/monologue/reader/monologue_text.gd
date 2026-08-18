## A translated property is saved as {language_code: text}, a plain one as a String, and
## both arrive here. The fallback order is part of the format: another engine resolving
## text differently plays a different game.
class_name MonologueText


## That language, failing that the first translation that says anything, failing that
## nothing. Falling back rather than going blank keeps a half-translated story playable,
## and a blank line reads as a bug in the game rather than a gap in the translation.
static func to_label(value: Variant, language_code: String = "") -> String:
	if value is String:
		return (value as String).strip_edges()

	if value is Dictionary:
		var translations: Dictionary = value
		var preferred: String = str(translations.get(language_code, "")).strip_edges()
		if not preferred.is_empty():
			return preferred
		for key: Variant in translations:
			var text: String = str(translations[key]).strip_edges()
			if not text.is_empty():
				return text
		return ""

	if value == null or value is Array:
		return ""

	return str(value).strip_edges()


static func languages_of(value: Variant) -> PackedStringArray:
	var codes: PackedStringArray = []
	if value is not Dictionary:
		return codes
	for key: Variant in value as Dictionary:
		if not str((value as Dictionary)[key]).strip_edges().is_empty():
			codes.append(str(key))
	return codes
