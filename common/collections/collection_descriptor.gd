class_name CollectionDescriptor extends BucketDescriptor

var collection_script: GDScript
var default_settings: Dictionary = {}


func _init(p_name: String = "", p_script: Script = null, metadata: Dictionary = {}) -> void:
	super._init(p_name, metadata)
	collection_script = p_script


func instantiate_item(history: CommandManager) -> CollectionItem:
	if collection_script == null:
		push_warning("Descriptor '%s' missing script for instantiation." % name)
		return null
	var instance: CollectionItem = collection_script.new(history)
	if instance is CollectionItem:
		return instance
	push_error("Descriptor '%s' does not create an InspectableNode." % name)
	return null


func to_metadata() -> Dictionary:
	return super.to_metadata()
