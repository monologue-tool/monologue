## Creates and binds [Field] widgets from field type names.
##
## This is the UI half of the field system: [MonologueRegistry] stays free of Control,
## and everything that instantiates a scene lives here. Nothing under `common/` outside
## `common/ui/` may call this.
class_name FieldWidgetFactory


## Returns a new widget for [param field_name], or null when the type is unknown or is
## a port-only pseudo-type with no editor widget.
static func create(field_name: String) -> Field:
	var indexer: FieldIndexer = MonologueRegistry.get_instance().get_field(field_name)
	if indexer == null:
		return null
	var field: Field = indexer.instantiate() as Field
	if field == null:
		return null
	# Duplicated so that a widget mutating its settings cannot corrupt the type-level
	# defaults shared by every other instance.
	field.settings = indexer.default_settings.duplicate(true)
	return field


## Never returns null: an unknown type degrades to a visible placeholder rather than an
## empty row, so a typo in a property declaration is obvious in the inspector.
static func create_or_placeholder(field_name: String) -> Control:
	var field: Field = create(field_name)
	if field:
		return field
	var warn_label: Label = Label.new()
	warn_label.theme_type_variation = "WarnLabel"
	warn_label.text = "Unknown property type '%s'" % field_name
	return warn_label


## Connects [param property] to [param field]. Pass [param owner] to make edits
## undoable; leave it null for detached widgets whose parent commits on their behalf.
static func bind(property: Property, field: Field, owner: InspectableObject = null) -> FieldBinding:
	if not property or not is_instance_valid(field):
		return null
	var indexer: FieldIndexer = MonologueRegistry.get_instance().get_field(property.type)
	if indexer == null:
		push_warning("No field type registered as '%s'." % property.type)
		return null
	var binding: FieldBinding = FieldBinding.new(property, field, indexer, owner)
	binding.initialize()
	return binding
