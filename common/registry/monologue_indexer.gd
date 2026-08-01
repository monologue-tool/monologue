## One registration record for one Monologue type.
##
## An indexer is both the description of a type and the factory that creates it.
## Subclass [FieldIndexer], [NodeIndexer] or [CollectionIndexer] -- never this class
## directly -- and fill the members in [method _init]:
## [codeblock]
## extends FieldIndexer
##
## func _init() -> void:
##     name = "text"
##     display_name = "Text"
##     color = Color("af85fd")
##     scene_uid = "uid://be0xxn5gocqjo"
## [/codeblock]
##
## Metadata lives in typed members rather than a Dictionary so the compiler checks it,
## autocompletion lists it, and "find references" works on it.
@abstract
class_name MonologueIndexer extends RefCounted

## Machine name, unique within this indexer's object type.
## Written into save files -- renaming one breaks existing projects.
var name: String = ""
## Name shown in menus. Defaults to a readable form of [member name].
var display_name: String = ""
## Menu grouping. A leading underscore hides the category from the add-node menu.
var category: String = "General"
## One-line description shown in tooltips and generated docs.
var description: String = ""
var tags: Array[String] = []
## "res://" path or "uid://" of a Texture2D, loaded on first use.
## A path (not a preloaded Texture2D) so the model layer stays free of resources.
var icon_path: String = ""
var color: Color = Color.WHITE
## Set by the registry to the name of the plugin that registered this type.
var source_plugin: String = ""

var _icon_cache: Texture2D
var _icon_loaded: bool = false


func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	return Util.to_readable_name(name)


## Loads [member icon_path] on first call and caches it. Null when unset or missing.
func get_icon() -> Texture2D:
	if _icon_loaded:
		return _icon_cache
	_icon_loaded = true
	if icon_path.is_empty():
		return null
	var resource: Resource = load(icon_path)
	if resource is Texture2D:
		_icon_cache = resource
	else:
		push_warning("Indexer '%s': icon_path '%s' is not a Texture2D." % [name, icon_path])
	return _icon_cache


## Checked by the registry before accepting a registration.
## Override to add type-specific requirements, calling super first.
func validate_registration() -> String:
	if name.is_empty():
		return "Indexer has no name."
	if not MonologueObjectType.is_valid(get_object_type()):
		return "Indexer '%s' has an unknown object type." % name
	return ""


@abstract func get_object_type() -> StringName

## Creates one instance of the type this indexer describes.
@abstract func instantiate(history: CommandManager = null) -> Object
