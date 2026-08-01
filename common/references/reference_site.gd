## One place in the project that points at an object by id.
##
## Produced by [ProjectObjectRegistry] while it walks the project, and read back to
## answer "what would break if this were deleted?".
class_name ReferenceSite extends RefCounted

## A value stored in a property, such as a sentence's speaker.
const KIND_REFERENCE: StringName = &"reference"
## A wire between two graph node ports.
const KIND_CONNECTION: StringName = &"connection"

## Id of the object holding the reference.
var owner_id: String = ""
## Property the reference is stored in.
var property_name: String = ""
## Id of the object being pointed at.
var target_id: String = ""
## Document the owner lives in.
var document_name: String = ""
var kind: StringName = KIND_REFERENCE


static func create(
	p_owner_id: String,
	p_property_name: String,
	p_target_id: String,
	p_document_name: String = "",
	p_kind: StringName = KIND_REFERENCE
) -> ReferenceSite:
	var site: ReferenceSite = ReferenceSite.new()
	site.owner_id = p_owner_id
	site.property_name = p_property_name
	site.target_id = p_target_id
	site.document_name = p_document_name
	site.kind = p_kind
	return site


## True when both sites describe the same slot pointing at the same object.
func matches(other: ReferenceSite) -> bool:
	return (
		owner_id == other.owner_id
		and property_name == other.property_name
		and target_id == other.target_id
		and kind == other.kind
	)


func _to_string() -> String:
	return "%s.%s -> %s" % [owner_id, property_name, target_id]
