## One registration record for one Monologue type.
##
## Subclass [FieldIndexer], [NodeIndexer] or [CollectionIndexer], never this class, and fill
## in the members from [method _init].
@abstract
class_name MonologueIndexer extends RefCounted

## Unique within this indexer's object type. Written into save files, so renaming one breaks
## existing projects.
var name: String = ""
var display_name: String = ""
## Menu grouping. A leading underscore hides the category from the add-node menu.
var category: String = "General"
var description: String = ""
var tags: Array[String] = []
## "res://" or "uid://" of a Texture2D, loaded on first use.
var icon_path: String = ""
var color: Color = Color.WHITE
var source_plugin: String = ""

var _icon_cache: Texture2D
var _icon_loaded: bool = false


func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	return Util.to_readable_name(name)


func get_color() -> Color:
	if color != Color.WHITE:
		return color
	return MonologuePalette.for_category(category)


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


## Checked before a registration is accepted. Override with a super call first.
func validate_registration() -> String:
	if name.is_empty():
		return "Indexer has no name."
	if not MonologueObjectType.is_valid(get_object_type()):
		return "Indexer '%s' has an unknown object type." % name
	return ""


@abstract func get_object_type() -> StringName

@abstract func instantiate(history: CommandManager = null) -> Object
