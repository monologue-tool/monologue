## Centralizes all known Property settings as typed KEY_* constants.
## Use these constants instead of magic strings to avoid typos and ease refactoring.
class_name PropertySettings

# Display

## Whether the property appears as a row inside the graph node view.
const KEY_VISIBLE_IN_GRAPH: String = "visible_in_graph"
## Whether the property appears in the inspector panel.
const KEY_VISIBLE_IN_INSPECTOR: String = "visible_in_inspector"
## Inspector category this property belongs to (default: "General").
const KEY_CATEGORY: String = "category"
## Human-readable label override. Falls back to the property name when empty.
const KEY_LABEL: String = "label"
## Tooltip text shown on the property label in the inspector.
const KEY_TOOLTIP: String = "tooltip"
## Whether the property container expands horizontally (default: true).
const KEY_EXPAND: String = "expand"
## Whether the property container renders without a visible background panel.
const KEY_FLAT: String = "flat"

# Editing

## Whether the property is editable in the inspector.
## If false (and not read_only / not a port), the property is hidden entirely.
const KEY_EDITABLE: String = "editable"
## Whether the property is visible in the inspector but cannot be modified.
## The field is shown in a disabled/frozen state. Takes precedence over KEY_EDITABLE
## for visibility: a read_only property is always shown even if editable is false.
const KEY_READ_ONLY: String = "read_only"
## Whether the value must be unique among sibling items in the same ListField.
## Validated on commit. Typically applied to the "name" property of collection items.
const KEY_UNIQUE: String = "unique"
## Whether the value is required (non-empty / non-zero). Validated on commit.
const KEY_REQUIRED: String = "required"
## Whether the list item that carries this property is protected from deletion.
const KEY_PROTECT: String = "protect"
## Sibling property whose value decides whether this one may be edited, stored as
## { "property": String, "values": Array }. Absent when nothing gates it.
const KEY_ENABLED_BY: StringName = &"enabled_by"
## Same shape as KEY_ENABLED_BY, but takes the property out of the inspector instead of
## greying it out.
const KEY_SHOWN_BY: StringName = &"shown_by"

# Validation

## Dictionary of field-type-specific validation rules applied during commit.
## Example: { "min_length": 1, "max_length": 64 }
const KEY_VALIDATION: StringName = "validation"

# Ports

## Whether an input port (left side) is shown, allowing incoming connections.
const KEY_EXPOSED: StringName = &"exposed"
## Whether an output port (right side) is shown, allowing outgoing connections.
const KEY_EXPORT: StringName = &"export"
## Whether the user can toggle the input port via the inspector.
const KEY_EXPOSABLE: StringName = &"exposable"
## Marks this as the primary connectable context property of the node.
const KEY_IS_MAIN_PROPERTY: StringName = &"is_main_property"

# Field-type-specific

## (list) Name of the collection registry to query for list items.
const KEY_COLLECTION: StringName = &"collection"
## (list) Field type used by each standard list item.
const KEY_ITEM_TYPE: StringName = &"item_type"
## (port) Visual size of the port slot ("normal" or "large").
const KEY_PORT_SIZE: StringName = &"port_size"
## (int / float) Lowest value the widget offers. Declared together with KEY_MAX_VALUE;
## a number missing either one is unbounded and drags freely.
const KEY_MIN_VALUE: StringName = &"min_value"
## (int / float) Highest value the widget offers.
const KEY_MAX_VALUE: StringName = &"max_value"
## (int / float) Increment between two values, and how many decimals are shown.
const KEY_STEP: StringName = &"step"
## (int / float) Whether the value is kept whole. True for int, false for float.
const KEY_ROUNDED: StringName = &"rounded"
## (int / float) Unit shown after the number, such as "s" or "dB".
const KEY_SUFFIX: StringName = &"suffix"
## (int / float) Text shown before the number.
const KEY_PREFIX: StringName = &"prefix"
## (dropdown) Static array of option strings offered to the user.
const KEY_OPTIONS: StringName = &"options"
## (dropdown) Dynamic source: a collection name or "self:<property>" path.
const KEY_SOURCE: StringName = &"source"
## (reference) Where the target may be found: a collection name, "self:<property>",
## "storylines", or "node:<type>". See [ReferenceResolver].
const KEY_REFERENCE_SCOPE: StringName = &"reference_scope"
## (reference) Property of the target read to label it. Defaults to "name".
const KEY_LABEL_PROPERTY: StringName = &"label_property"
## (reference) Whether "nothing selected" is an accepted value.
const KEY_ALLOW_EMPTY: StringName = &"allow_empty"
## (text) Whether the value is a set of translations keyed by language code rather than
## a plain String. On for `text`, off for `textarea`, and switched per property with
## [method Property.plain] / [method Property.translatable].
const KEY_TRANSLATABLE: StringName = &"translatable"
## (text) When true, renders a multi-line TextEdit instead of a LineEdit.
const KEY_MULTILINE: StringName = &"multiline"
## (text / translatable) Placeholder ghost text shown when the field is empty.
const KEY_PLACEHOLDER: StringName = &"placeholder"
## (textarea) Number of visible text rows used to compute minimum height.
const KEY_ROWS: StringName = &"rows"
## (dynamic) Name of the sibling property whose value selects the active variant.
const KEY_CASE_PROPERTY: StringName = &"case_property"
## (dynamic) Mapping from case-value string to { type, default, coerce? } dict.
const KEY_CASES: StringName = &"cases"
## (file) Array of file filter strings passed to the file dialog (e.g. ["*.png", "*.jpg"]).
## An empty array means no filter (all files are shown).
const KEY_FILE_FILTERS: StringName = &"file_filters"

# Defaults

## Default values for all base settings. Field-type-specific keys are omitted
## because they only apply to specific field types and have no meaningful global default.
const DEFAULTS: Dictionary = {
	KEY_VISIBLE_IN_GRAPH: true,
	KEY_VISIBLE_IN_INSPECTOR: true,
	KEY_EDITABLE: true,
	KEY_READ_ONLY: false,
	KEY_EXPOSABLE: true,
	KEY_EXPOSED: false,
	KEY_EXPORT: false,
	KEY_CATEGORY: "General",
	KEY_LABEL: "",
	KEY_EXPAND: true,
	KEY_FLAT: false,
}
