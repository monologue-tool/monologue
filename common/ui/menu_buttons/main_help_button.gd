extends EditorMenuButton


func _build_menu() -> void:
	add_row("Documentation", Callable(), false)
	add_row("Support Us", Callable(), false)
	add_row("Contribute", Callable(), false)
	add_separator()
	add_row("Report a Bug", _on_report_a_bug)
	add_row("Copy System Info", _on_save_system_info)


func _on_report_a_bug() -> void:
	OS.shell_open("https://github.com/monologue-tool/monologue/issues/new?template=BUG-REPORT.yml")


func _on_save_system_info() -> void:
	var lines: Array[String] = []

	var version: String = ProjectSettings.get_setting("application/config/version")

	lines.append("Monologue %s - System Info" % version)
	lines.append("")
	lines.append("version: %s " % version)
	lines.append("is debug: %s" % OS.is_debug_build())
	lines.append("os: %s (%s)" % [OS.get_name(), OS.get_version()])
	lines.append("cpu: %s (%s core)" % [OS.get_processor_name(), OS.get_processor_count()])
	lines.append("memory:")
	for key: String in OS.get_memory_info().keys():
		var value: int = OS.get_memory_info()[key]
		lines.append("   - %s: %.2f Gb (%s bytes)" % [key, value / 1e+9, value])

	DisplayServer.clipboard_set("\n".join(lines))
