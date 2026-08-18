## What one property's port carries: which slot type it is, how it reads, what colour it is
## drawn in.
##
## The one place a port type is worked out. The graph draws from this, and a node that follows
## another node's type -- a reroute is whatever was plugged into it -- resolves through the
## same function, so the two can never disagree about what a wire is carrying.
class_name NodePort


## The port [param prop] hands on, as {"type_id": int, "label": String, "color": Color}.
##
## [param hops] counts the nodes already followed to get here, so that a reroute wired in a
## circle is given up on rather than asked forever.
static func of(node: InspectableNode, prop: Property, hops: int = 0) -> Dictionary:
	var carried: Dictionary = node.carried_port(prop, hops)
	return carried if not carried.is_empty() else declared(node, prop)


## The port [param prop] declares, whatever it may be carrying on top of that.
##
## What a node takes in is always this. A reroute that had adopted a type on both of its
## sides could never be rewired without first being unplugged from whatever it feeds.
static func declared(node: InspectableNode, prop: Property) -> Dictionary:
	var registry: MonologueRegistry = MonologueRegistry.get_instance()
	if prop.type == "reference":
		var scope: String = str(prop.get_settings_value(PropertySettings.KEY_REFERENCE_SCOPE, ""))
		if not scope.is_empty():
			return {
				"type_id": registry.get_reference_type_id(scope),
				"label": ReferenceResolver.describe_scope(scope, node),
				"color": color_of(prop.type),
			}

	# A collection port accepts whatever its items' main property exports, so that an option
	# node can be plugged into a choice node's option list.
	var type_name: String = prop.type
	if prop.type == "collection":
		var collection_name: String = prop.get_settings_value(PropertySettings.KEY_COLLECTION, "")
		var indexer: CollectionIndexer = registry.get_collection(collection_name)
		if indexer and not indexer.port_type.is_empty():
			type_name = indexer.port_type

	return {
		"type_id": registry.get_field_type_id(type_name),
		"label": type_name,
		"color": color_of(type_name),
	}


static func color_of(field_name: String) -> Color:
	var indexer: FieldIndexer = MonologueRegistry.get_instance().get_field(field_name)
	return indexer.color if indexer else Color.WHITE
