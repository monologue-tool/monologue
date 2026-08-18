## Finds things in folders and hands them out by name.
##
## Both of the addon's extension points work this way, behaviours and services, so the folder
## scanning, the name claiming and the shadow warning live here once. A subclass says what it
## is looking for, where, and how a thing gives its names.
@abstract class_name MonologueIndex extends Node

## name -> the thing. Not necessarily something scanned for. Anything handed in through
## declare() counts too.
var _by_name: Dictionary = {}


## The folder shipped with the addon, then whatever a game added under [param setting]. Read
## from ProjectSettings and not from an editor plugin, so a game that never enabled one still
## gets its own folders.
func _init(
	built_in_folder: String, setting: String, problems: Array[MonologueProblem] = []
) -> void:
	index(built_in_folder, problems)
	for folder: String in _declared_folders(setting):
		index(folder, problems)


## What a scanned script has to be to count.
@abstract func wanted() -> Script


## The names one thing answers to. Several is legal. A behaviour claims one per node type.
@abstract func names_of(thing: Node) -> PackedStringArray


## Builds every usable node a folder holds. A folder may hold a helper next to the things
## that use it, so anything else is passed over in silence.
##
## ResourceLoader.list_directory and not DirAccess. It still answers in an exported game,
## where a script is no longer a file on disk.
func index(folder: String, problems: Array[MonologueProblem] = []) -> void:
	var found: int = 0

	for file_name: String in ResourceLoader.list_directory(folder):
		if not file_name.ends_with(".gd"):
			continue

		var script: Variant = load(folder.path_join(file_name))
		if script is not GDScript:
			continue
		var gdscript: GDScript = script
		if gdscript.is_abstract() or not gdscript.can_instantiate():
			continue
		if not _descends_from(gdscript, wanted()):
			continue

		found += 1
		var made: Node = gdscript.new()
		if not adopt(made, problems):
			made.free()

	if found == 0:
		problems.append(
			MonologueProblem.warning(&"empty_folder", "Nothing usable was found in '%s'." % folder)
		)


## Takes something already built, for a game that would rather write the wiring than fill a
## folder. False when it was refused, and the caller owns it again.
func declare(thing: Node, problems: Array[MonologueProblem] = []) -> bool:
	return adopt(thing, problems)


func has(thing_name: String) -> bool:
	return _by_name.has(thing_name)


func names() -> PackedStringArray:
	var known: PackedStringArray = []
	known.append_array(_by_name.keys())
	known.sort()
	return known


## Overridable so a subclass can refuse one, or keep a list of its own alongside.
func adopt(thing: Node, problems: Array[MonologueProblem] = []) -> bool:
	if thing.get_parent() == null:
		add_child(thing)
	for thing_name: String in names_of(thing):
		_claim(thing_name, thing, problems)
	return true


## Read off the inheritance chain instead of building one and looking. A script's _init can
## do anything, including scanning this very folder.
static func _descends_from(script: Script, base: Script) -> bool:
	var current: Script = script
	while current != null:
		if current == base:
			return true
		current = current.get_base_script()
	return false


## A story would otherwise silently reach whichever was read last.
func _claim(thing_name: String, thing: Object, problems: Array[MonologueProblem]) -> void:
	if thing_name.is_empty():
		problems.append(
			MonologueProblem.warning(
				&"nameless_entry", "Something with no name cannot be reached; it was skipped."
			)
		)
		return

	if _by_name.has(thing_name) and _by_name[thing_name] != thing:
		problems.append(
			MonologueProblem.warning(
				&"name_shadowed",
				"Two things answer to '%s'; the last one read won." % thing_name
			)
		)
	_by_name[thing_name] = thing


func _declared_folders(setting: String) -> PackedStringArray:
	var folders: PackedStringArray = []
	var declared: Variant = ProjectSettings.get_setting(setting, [])
	if declared is PackedStringArray or declared is Array:
		for folder: Variant in declared:
			folders.append(str(folder))
	return folders
