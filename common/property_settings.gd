## Centralizes all known Property settings as typed KEY_* constants.
## Use these constants instead of magic strings to avoid typos and ease refactoring.
class_name PropertySettings

# ─── Display ──────────────────────────────────────────────────────────────────

## Whether the property appears as a row inside the graph node view.
const KEY_VISIBLE_IN_GRAPH := "visible_in_graph"
## Whether the property appears in the inspector panel.
const KEY_VISIBLE_IN_INSPECTOR := "visible_in_inspector"
## Inspector category this property belongs to (default: "General").
const KEY_CATEGORY := "category"
## Human-readable label override. Falls back to the property name when empty.
const KEY_LABEL := "label"
## Tooltip text shown on the property label in the inspector.
const KEY_TOOLTIP := "tooltip"
## Whether the property container expands horizontally (default: true).
const KEY_EXPAND := "expand"
## Whether the property container renders without a visible background panel.
const KEY_FLAT := "flat"

# ─── Editing ──────────────────────────────────────────────────────────────────

## Whether the property is editable in the inspector.
## If false (and not read_only / not a port), the property is hidden entirely.
const KEY_EDITABLE := "editable"
## Whether the property is visible in the inspector but cannot be modified.
## The field is shown in a disabled/frozen state. Takes precedence over KEY_EDITABLE
## for visibility: a read_only property is always shown even if editable is false.
const KEY_READ_ONLY := "read_only"
## Whether the value must be unique among sibling items in the same ListField.
## Validated on commit. Typically applied to the "name" property of collection items.
const KEY_UNIQUE := "unique"
## Whether the value is required (non-empty / non-zero). Validated on commit.
const KEY_REQUIRED := "required"
## Whether the list item that carries this property is protected from deletion.
const KEY_PROTECT := "protect"

# ─── Validation ───────────────────────────────────────────────────────────────

## Dictionary of field-type-specific validation rules applied during commit.
## Example: { "min_length": 1, "max_length": 64 }
const KEY_VALIDATION := "validation"

# ─── Ports ────────────────────────────────────────────────────────────────────

## Whether an input port (left side) is shown, allowing incoming connections.
const KEY_EXPOSED := "exposed"
## Whether an output port (right side) is shown, allowing outgoing connections.
const KEY_EXPORT := "export"
## Whether the user can toggle the input port via the inspector.
const KEY_EXPOSABLE := "exposable"
## Marks this as the primary connectable context property of the node.
const KEY_IS_MAIN_PROPERTY := "is_main_property"

# ─── Field-type-specific ──────────────────────────────────────────────────────

## (list) Name of the collection registry to query for list items.
const KEY_COLLECTION := "collection"
## (port) Visual size of the port slot ("normal" or "large").
const KEY_PORT_SIZE := "port_size"
## (dropdown) Static array of option strings offered to the user.
const KEY_OPTIONS := "options"
## (dropdown) Dynamic source: a collection name or "self:<property>" path.
const KEY_SOURCE := "source"
## (translatable) When true, renders a multi-line TextEdit instead of a LineEdit.
const KEY_MULTILINE := "multiline"
## (text / translatable) Placeholder ghost text shown when the field is empty.
const KEY_PLACEHOLDER := "placeholder"
## (textarea) Number of visible text rows used to compute minimum height.
const KEY_ROWS := "rows"
## (dynamic) Name of the sibling property whose value selects the active variant.
const KEY_CASE_PROPERTY := "case_property"
## (dynamic) Mapping from case-value string to { type, default, coerce? } dict.
const KEY_CASES := "cases"
## (file) Array of file filter strings passed to the file dialog (e.g. ["*.png", "*.jpg"]).
## An empty array means no filter (all files are shown).
const KEY_FILE_FILTERS := "file_filters"

# ─── Defaults ─────────────────────────────────────────────────────────────────

## Default values for all base settings. Field-type-specific keys are omitted
## because they only apply to specific field types and have no meaningful global default.
const DEFAULTS := {
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
