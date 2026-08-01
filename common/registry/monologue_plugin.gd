## The single entry point for adding types to Monologue.
##
## Everything Monologue ships with is registered by [MonologueCorePlugin]; there is no
## second, privileged path. A plugin registers indexers and nothing else:
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

## Stable identifier, conventionally "vendor.name". Used to tag every type this
## plugin registers so they can all be removed again on uninstall.
@abstract func get_plugin_name() -> String


func get_plugin_version() -> String:
	return "1.0.0"


## Called once on install. Register every type the plugin provides here.
@abstract func register(registry: MonologueRegistry) -> void


## Called on uninstall. Types registered through [param registry] are removed
## automatically; override only for extra teardown.
func unregister(_registry: MonologueRegistry) -> void:
	pass
