## Every translatable piece of text in a project, gathered in one place.
##
## Headless: it walks the model, not the editor. Which properties count is decided by
## the properties themselves -- [method Property.is_translatable] -- so a new field type
## that holds translations appears here without this class hearing about it.
##
## Text lives in two shapes: on live objects such as nodes and documents, and inside
## collection records, which are plain dictionaries. Both are walked; an entry knows
## which it came from and writes itself back accordingly.
class_name TranslationTable extends RefCounted

const COLLECTION_TYPE: String = "collection"

var entries: Array[TranslationEntry] = []
var _by_key: Dictionary[String, TranslationEntry] = {}
var _prototypes: Dictionary[String, CollectionItem] = {}
var _history: CommandManager


## Walks a project and returns everything translatable in it.
static func collect(project: MonologueProject) -> TranslationTable:
	var table: TranslationTable = TranslationTable.new()
	if project == null:
		return table

	table._history = project.command_manager
	for document: InspectableDocument in project.get_all_documents():
		table._collect_object(document, document.get_document_name())
		if document is StorylineDocument:
			for node: InspectableNode in (document as StorylineDocument).nodes:
				table._collect_object(node, document.get_document_name())
	return table


## The language codes the project declares, in the order they were added.
static func languages_of(project: MonologueProject) -> PackedStringArray:
	var codes: PackedStringArray = []
	if project == null:
		return codes

	for entry: Variant in project.get_collection_value("languages"):
		if entry is not Dictionary:
			continue
		var code: String = str((entry as Dictionary).get("code", "")).strip_edges()
		if not code.is_empty() and code not in codes:
			codes.append(code)
	return codes


func get_entry(key: String) -> TranslationEntry:
	return _by_key.get(key)


func get_keys() -> PackedStringArray:
	var keys: PackedStringArray = []
	for entry: TranslationEntry in entries:
		keys.append(entry.key)
	return keys


## Entries with nothing written in [param language].
func missing(language: String) -> Array[TranslationEntry]:
	var found: Array[TranslationEntry] = []
	for entry: TranslationEntry in entries:
		if not entry.has_text(language):
			found.append(entry)
	return found


## How much of the project reads in [param language], from 0 to 1. An empty project is
## fully translated, which is the only answer that does not divide by zero.
func coverage(language: String) -> float:
	if entries.is_empty():
		return 1.0
	return float(entries.size() - missing(language).size()) / float(entries.size())


## Writes one translation back into the project, through the undo history. Returns
## false when the key is unknown or the text was already that.
func apply(key: String, language: String, text: String) -> bool:
	var entry: TranslationEntry = get_entry(key)
	if entry == null or language.is_empty():
		return false
	if entry.get_text(language) == text:
		return false

	var translations: Dictionary = entry.translations.duplicate(true)
	translations[language] = text
	return _write(entry, translations)


## Applies a whole imported batch, and returns how many entries actually moved.
## Unknown keys are reported rather than invented: an import never adds text the
## project has nowhere to put.
func apply_batch(batch: Dictionary, result: ValidationResult = null) -> int:
	var applied: int = 0
	for language: String in batch:
		var by_key: Dictionary = batch[language]
		for key: String in by_key:
			if get_entry(key) == null:
				if result:
					result.add_warning(
						"No text in this project is called '%s'; it was left out." % key,
						&"unknown_translation_key"
					)
				continue
			if apply(key, language, str(by_key[key])):
				applied += 1
	return applied


func _collect_object(object: InspectableObject, document_name: String) -> void:
	var object_id: String = str(object.get_property_value("id"))
	var context: String = _describe(object)

	for property: Property in object.get_properties():
		if property.type == COLLECTION_TYPE:
			_collect_records(object, property, [], document_name)
			continue
		if not property.is_translatable():
			continue
		_add(
			TranslationEntry.create(
				object,
				property.name,
				property.get_value() if property.get_value() is Dictionary else {},
				object_id,
				context,
				document_name,
				object.get_type(),
				property.get_settings(),
				_speaker_of(object.get_property_value("speaker"))
			)
		)


## Walks the records of a collection property, and the collections nested inside them.
func _collect_records(
	owner: InspectableObject, property: Property, path: Array, document_name: String
) -> void:
	var collection_name: String = str(
		property.get_settings_value(PropertySettings.KEY_COLLECTION, "")
	)
	var prototype: CollectionItem = _get_prototype(collection_name)
	var value: Variant = _read_at(owner, path, property.name)
	if prototype == null or value is not Array:
		return

	for record: Variant in value:
		if record is not Dictionary:
			continue
		var record_dict: Dictionary = record
		var record_id: String = str(record_dict.get("id", ""))
		if record_id.is_empty():
			continue

		var step: Array = path + [{"property": property.name, "item_id": record_id}]
		for item_property: Property in prototype.get_properties():
			if item_property.type == COLLECTION_TYPE:
				_collect_records(owner, item_property, step, document_name)
				continue
			if not item_property.is_translatable():
				continue
			var stored: Variant = record_dict.get(item_property.name)
			_add(
				TranslationEntry.create(
					owner,
					item_property.name,
					stored if stored is Dictionary else {},
					record_id,
					_describe_record(record_dict, prototype),
					document_name,
					prototype.get_type(),
					property.get_settings(),
					_speaker_of(record_dict.get("speaker")),
					step
				)
			)


func _add(entry: TranslationEntry) -> void:
	if _by_key.has(entry.key):
		return
	entries.append(entry)
	_by_key[entry.key] = entry


## Puts a new set of translations where the entry came from. Everything goes through
## set_property_value, so an import is one undo step per line rather than a silent edit.
func _write(entry: TranslationEntry, translations: Dictionary) -> bool:
	if entry.owner == null:
		return false

	if entry.path.is_empty():
		entry.owner.set_property_value(entry.property_name, translations)
		entry.translations = translations
		return true

	var root_property: String = str(entry.path[0]["property"])
	var rebuilt: Variant = _rebuild(
		entry.owner.get_property_value(root_property),
		entry.path,
		0,
		entry.property_name,
		translations
	)
	if rebuilt is not Array:
		return false

	entry.owner.set_property_value(root_property, rebuilt)
	entry.translations = translations
	return true


## Returns a copy of [param records] with one record's property replaced, walking down
## [param path] to find it. Copies rather than mutates: the stored array is the value
## the undo history is about to be handed.
func _rebuild(
	records: Variant, path: Array, depth: int, property_name: String, translations: Dictionary
) -> Variant:
	if records is not Array:
		return records

	var target_id: String = str(path[depth]["item_id"])
	var rebuilt: Array = []
	for record: Variant in records:
		if record is not Dictionary or str((record as Dictionary).get("id", "")) != target_id:
			rebuilt.append(record)
			continue

		var copy: Dictionary = (record as Dictionary).duplicate(true)
		if depth == path.size() - 1:
			copy[property_name] = translations
		else:
			var nested: String = str(path[depth + 1]["property"])
			copy[nested] = _rebuild(
				copy.get(nested), path, depth + 1, property_name, translations
			)
		rebuilt.append(copy)

	return rebuilt


## Reads the property holding a nested collection, following the path taken so far.
func _read_at(owner: InspectableObject, path: Array, property_name: String) -> Variant:
	if path.is_empty():
		return owner.get_property_value(property_name)

	var records: Variant = owner.get_property_value(str(path[0]["property"]))
	for depth: int in range(path.size()):
		if records is not Array:
			return null
		var target_id: String = str(path[depth]["item_id"])
		var found: Dictionary = {}
		for record: Variant in records:
			if record is Dictionary and str((record as Dictionary).get("id", "")) == target_id:
				found = record
				break
		if found.is_empty():
			return null
		records = found.get(
			property_name if depth == path.size() - 1 else str(path[depth + 1]["property"])
		)
	return records


## The name of the character a line is spoken by. Resolved once at collect time: the
## table is rebuilt whenever it is shown, so it cannot go stale in the meantime.
static func _speaker_of(ref: Variant) -> String:
	var character_id: String = str(ref) if ref != null else ""
	if character_id.is_empty():
		return ""
	return ReferenceResolver.resolve_property(
		ProjectManager.current_project, "characters", character_id, "name"
	)


static func _describe(object: InspectableObject) -> String:
	var label: String = Util.to_label(object.get_property_value("label"))
	if not label.is_empty():
		return label
	var name: String = Util.to_label(object.get_property_value("name"))
	if not name.is_empty():
		return name
	return Util.to_readable_name(object.get_type())


static func _describe_record(record: Dictionary, prototype: CollectionItem) -> String:
	var label: String = Util.to_label(record.get(prototype.get_preview_property_names()[0]))
	if not label.is_empty():
		return label
	return Util.to_readable_name(prototype.get_type())


func _get_prototype(collection_name: String) -> CollectionItem:
	if _prototypes.has(collection_name):
		return _prototypes[collection_name]

	var prototype: CollectionItem = MonologueRegistry.get_instance().create_collection_item(
		collection_name, _history
	)
	if prototype:
		_prototypes[collection_name] = prototype
	return prototype
