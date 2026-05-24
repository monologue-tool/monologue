class_name MemoryUsageLabel extends Label


func _process(_delta: float) -> void:
	var memory_usage: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1_048_576.0
	text = "Memory: %.1f MB" % memory_usage
	
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var time_process: float = Performance.get_monitor(Performance.TIME_PROCESS)
	var draw_calls: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	tooltip_text = "FPS: %.1f (Process: %.2f ms)\nDraw calls: %d" % [fps, time_process, draw_calls]
	
	process_mode = ProcessMode.PROCESS_MODE_DISABLED
	await get_tree().create_timer(1.0, true, false, true).timeout
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
