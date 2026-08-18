## Describes one collection type: a named list of reusable items shared across a project
## (characters, variables, items, ...).
@abstract
class_name CollectionIndexer extends MonologueIndexer

## Safe to preload. Item scripts are model code.
var item_script: GDScript
## False for collections that only live embedded inside another object, such as a choice
## node's options.
var is_project_scoped: bool = true
var label_property: String = "name"
## Field type a graph port accepts when a property holds this collection. The field type of
## the item's own main property. Empty when items have none, which leaves the property
## unconnectable.
var port_type: String = ""

var _item_type: String = ""
var _default_support: int = -1


func get_object_type() -> StringName:
	return MonologueObjectType.COLLECTION


## "character" for "characters". Read from the item script, never guessed from the name.
func get_item_type() -> String:
	if _item_type.is_empty():
		var probe: CollectionItem = instantiate(CommandManager.new()) as CollectionItem
		if probe:
			_item_type = probe.get_type()
	return _item_type


## True when one item can be marked as the one to fall back to. Read off the item script.
func has_default_item() -> bool:
	if _default_support < 0:
		var probe: CollectionItem = instantiate(CommandManager.new()) as CollectionItem
		_default_support = 1 if probe and probe.get_property("is_default") else 0
	return _default_support == 1


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
