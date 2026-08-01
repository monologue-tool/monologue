## Describes one collection type: a named list of reusable items shared across a project
## (characters, variables, items, ...).
@abstract
class_name CollectionIndexer extends MonologueIndexer

## Script extending [CollectionItem]. Safe to preload: item scripts are model code.
var item_script: GDScript
## True for collections that exist once per project. False for collections that only
## ever live embedded inside another object, such as a choice node's options.
var is_project_scoped: bool = true
## Property of an item used as its human-readable label when this collection is the
## target of a `reference` property.
var label_property: String = "name"


func get_object_type() -> StringName:
	return MonologueObjectType.COLLECTION


func validate_registration() -> String:
	var error: String = super.validate_registration()
	if not error.is_empty():
		return error
	if item_script == null:
		return "Collection '%s' has no item_script." % name
	return ""


func instantiate(history: CommandManager = null) -> Object:
	if item_script == null:
		return null
	var instance: Variant = item_script.new(history)
	if instance is CollectionItem:
		return instance
	push_error("Collection '%s': item_script does not extend CollectionItem." % name)
	return null
