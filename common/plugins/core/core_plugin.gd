## Registers every type that ships with Monologue.
##
## To add a type: create `<kind>/<name>/index.gd` extending the matching indexer, then
## add one preload line to the list below. The lists are explicit rather than a
## directory scan so that the compiler verifies every entry, the type ids are
## deterministic, and adding a type is a reviewable one-line diff.
class_name MonologueCorePlugin extends MonologuePlugin

const PLUGIN_NAME: String = "monologue.core"

const FIELDS: Array[GDScript] = [
	preload("res://common/fields/any/index.gd"),
	preload("res://common/fields/bezier/index.gd"),
	preload("res://common/fields/bool/index.gd"),
	preload("res://common/fields/collection/index.gd"),
	preload("res://common/fields/color/index.gd"),
	preload("res://common/fields/condition/index.gd"),
	preload("res://common/fields/context/index.gd"),
	preload("res://common/fields/dropdown/index.gd"),
	preload("res://common/fields/dynamic/index.gd"),
	preload("res://common/fields/file/index.gd"),
	preload("res://common/fields/float/index.gd"),
	preload("res://common/fields/int/index.gd"),
	preload("res://common/fields/list/index.gd"),
	preload("res://common/fields/option/index.gd"),
	preload("res://common/fields/reference/index.gd"),
	preload("res://common/fields/slider/index.gd"),
	preload("res://common/fields/text/index.gd"),
	preload("res://common/fields/textarea/index.gd"),
	preload("res://common/fields/translatable/index.gd"),
	preload("res://common/fields/vector2/index.gd"),
]

const NODES: Array[GDScript] = [
	preload("res://common/nodes/root_node/index.gd"),
	preload("res://common/nodes/sentence_node/index.gd"),
	preload("res://common/nodes/choice_node/index.gd"),
	preload("res://common/nodes/option_node/index.gd"),
	preload("res://common/nodes/text_node/index.gd"),
	preload("res://common/nodes/zoo_node/index.gd"),
]

const COLLECTIONS: Array[GDScript] = [
	preload("res://common/collections/character/index.gd"),
	preload("res://common/collections/variable/index.gd"),
	preload("res://common/collections/item/index.gd"),
	preload("res://common/collections/location/index.gd"),
	preload("res://common/collections/language/index.gd"),
	preload("res://common/collections/portrait/index.gd"),
	preload("res://common/collections/bezier/index.gd"),
	preload("res://common/collections/option/index.gd"),
]


func get_plugin_name() -> String:
	return PLUGIN_NAME


func get_plugin_version() -> String:
	return ProjectSettings.get_setting("application/config/version", "0.0.0")


func register(registry: MonologueRegistry) -> void:
	for group: Array[GDScript] in [FIELDS, NODES, COLLECTIONS]:
		for script: GDScript in group:
			registry.register(script.new())
