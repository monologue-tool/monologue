## One piece of text the player reads, in every language it has been written in.
##
## Knows where it came from well enough to be written back: the live object that owns
## the root property, and the path of list items to walk down from there. That path is
## empty for text sitting directly on a node, and one step long for a choice's options
## or a character's portraits.
class_name TranslationEntry extends RefCounted

## Separates an object id from the property, in the key exporters carry around.
const KEY_SEPARATOR: String = "/"

## Stable across exports and imports. Built from ids, so renaming anything keeps it.
var key: String = ""
## Shown to whoever is translating, so a line has some context to be translated in.
var context: String = ""
var document_name: String = ""
var property_name: String = ""
## {language_code: text}. The same dictionary shape the property itself holds.
var translations: Dictionary = {}

## The live object holding the root property this text lives under.
var owner: InspectableObject
## Steps from [member owner] down to the record holding the text, each
## {"property": String, "item_id": String}. Empty when the text is on the owner itself.
var path: Array = []


static func create(
	p_owner: InspectableObject,
	p_property_name: String,
	p_translations: Dictionary,
	p_object_id: String,
	p_context: String,
	p_document_name: String,
	p_path: Array = []
) -> TranslationEntry:
	var entry: TranslationEntry = TranslationEntry.new()
	entry.owner = p_owner
	entry.property_name = p_property_name
	entry.translations = p_translations.duplicate(true)
	entry.key = "%s%s%s" % [p_object_id, KEY_SEPARATOR, p_property_name]
	entry.context = p_context
	entry.document_name = p_document_name
	entry.path = p_path.duplicate(true)
	return entry


func get_text(language: String) -> String:
	return str(translations.get(language, ""))


func has_text(language: String) -> bool:
	return not get_text(language).strip_edges().is_empty()


## The text as it reads in [param language], or in whatever language it does exist in,
## so a row is never blank when there is something to show.
func get_preview(language: String) -> String:
	var text: String = get_text(language)
	if not text.is_empty():
		return text
	for code: Variant in translations:
		var fallback: String = str(translations[code]).strip_edges()
		if not fallback.is_empty():
			return fallback
	return ""


func _to_string() -> String:
	return key
