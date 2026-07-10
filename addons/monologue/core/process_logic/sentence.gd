class_name MonologueSentenceLogic extends MonologueProcessLogic


func enter(ctx: MonologueContext, node: Dictionary, _data: Dictionary = {}) -> MonologueProcessResult:
	var sentence: String = ""
	var languages: Dictionary = node.get("Sentence", {})
	var speaker_idx: int = int(node.get("Speaker", -1))
	var speaker: Dictionary = ctx.get_character_from_idx(speaker_idx)
	var character_data: Dictionary = speaker.get("Character")
	var speaker_name: String = node.get("DisplayName", "")
	
	if speaker_name == "": speaker_name = character_data.get("DisplayName", "")
	if speaker_name == "": speaker_name = character_data.get("Name", "")
	
	var speaker_slot_name: Variant = ctx.timeline.character_displayer.get_slot_name_from_character_idx(speaker_idx)
	if speaker_slot_name is String and ctx.settings.highlight_speaker:
		ctx.timeline.character_displayer.focus_slot(speaker_slot_name)
	elif not speaker_slot_name and ctx.settings.highlight_speaker:
		ctx.timeline.character_displayer.focus_slot("")
	
	for language: String in languages:
		if language == ctx.settings.language:
			sentence = languages[language]
	
	sentence = ctx.process_conditional_text(sentence)
	await ctx.display_text(sentence, speaker_name)
	
	return MonologueProcessResult.interrupt_process(node.get("NextID"))


func update(ctx: MonologueContext, _node: Dictionary, _delta: float) -> MonologueProcessResult:
	if Input.is_action_just_pressed("ui_continue") or \
	(Input.is_action_just_pressed("ui_mouse_continue") and ctx.timeline.text_box_container_mouse_hovering):
		if ctx.timeline.text_box.visible_ratio < 1:
			ctx.timeline.text_box.force_display()
	return MonologueProcessResult.none()
