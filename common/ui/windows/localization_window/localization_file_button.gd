## Moves translations between the project and the tools that edit them.
extends EditorMenuButton

## Export targets, in menu order. The id each one is listed under is its index here.
const FORMATS: Array[Dictionary] = [
	{"label": "To JSON", "format": TranslationIO.Format.JSON},
	{"label": "To CSV", "format": TranslationIO.Format.CSV},
	{"label": "To Portable Object", "format": TranslationIO.Format.PO},
]


func _build_menu() -> void:
	add_row("Import...", _on_import)
	add_separator()

	var export_menu: PopupMenu = add_submenu_row("Export", _on_export)
	for index: int in FORMATS.size():
		export_menu.add_item(str(FORMATS[index]["label"]), index)


func _on_import() -> void:
	var window: LocalizationWindow = owner
	if window:
		window.import_translations()


func _on_export(format_index: int) -> void:
	var window: LocalizationWindow = owner
	if window == null or format_index < 0 or format_index >= FORMATS.size():
		return
	window.export_translations(FORMATS[format_index]["format"])
