extends EditorMenuButton


func _build_menu() -> void:
	add_row("Report a Bug", _on_report_a_bug)


func _on_report_a_bug() -> void:
	OS.shell_open("https://github.com/monologue-tool/monologue/issues/new?template=BUG-REPORT.yml")
