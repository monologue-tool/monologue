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
## Field type a graph port accepts when a property holds this collection.
##
## It is the field type of the item's own main property: a choice node's option list
## accepts whatever an option item exports. Empty when items have no main property,
## which means a property holding this collection cannot be connected to.
##
## This used to be inferred by looking for a field type sharing the collection's name,
## which only ever worked because "option" happened to name both a collection and a
## field type. Renaming the collection to "options" broke every option-to-choice link.
var port_type: String = ""

var _item_type: String = ""


func get_object_type() -> StringName:
	return MonologueObjectType.COLLECTION


## What one item of this collection calls itself: "character" for "characters".
##
## Read from the item script rather than declared, so it cannot drift from what the
## items actually report, and guessed from the collection name even less: that is the
## inference that broke every option link when "option" became "options".
func get_item_type() -> String:
	if _item_type.is_empty():
		var probe: CollectionItem = instantiate(CommandManager.new()) as CollectionItem
		if probe:
			_item_type = probe.get_type()
	return _item_type


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
