## Autoload "Monologue". Forces the type registry to build at a predictable point in
## startup instead of lazily on first use.
##
## Nothing depends on this node existing: [method MonologueRegistry.get_instance]
## bootstraps itself, which is what lets headless tests run with no autoloads at all.
extends Node

var registry: MonologueRegistry


func _ready() -> void:
	registry = MonologueRegistry.get_instance()
