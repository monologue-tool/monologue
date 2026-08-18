## The single entry point for adding types to Monologue. A plugin registers indexers and
## nothing else:
## [codeblock]
## class_name MyPlugin extends MonologuePlugin
##
## func get_plugin_name() -> String:
##     return "my.plugin"
##
## func register(registry: MonologueRegistry) -> void:
##     registry.register(preload("res://my_plugin/duration/index.gd").new())
## [/codeblock]
@abstract
class_name MonologuePlugin extends RefCounted

## Stable identifier, conventionally "vendor.name". Tags every type this plugin registers,
## so uninstalling removes them all.
@abstract func get_plugin_name() -> String


func get_plugin_version() -> String:
	return "1.0.0"


## Called once on install.
@abstract func register(registry: MonologueRegistry) -> void


## Called on uninstall. Types registered through [param registry] are removed automatically.
## Override only for extra teardown.
func unregister(_registry: MonologueRegistry) -> void:
	pass
