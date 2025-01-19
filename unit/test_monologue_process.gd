extends GdUnitTestSuite


var runner: MonologueProcess
var nested = "G{{if big then if x then if y then a else e else o else i}}l"
var v_action =  {
	"$type": "ActionVariable",
	"Variable": "MID_AGE",
	"Operator": "=",
	"Value": 66
}


func before_test():
	runner = mock(MonologueProcess, CALL_REAL_FUNC)
	runner.base_path = "res://examples/mr_sharpener"
	runner.variables = [
		{"Name": "big", "Value": true, "Type": "Boolean"},
		{"Name": "x", "Value": true, "Type": "Boolean"},
		{"Name": "y", "Value": true, "Type": "Boolean"},
		{"Name": "age", "Value": 5, "Type": "Integer"},
		{"Name": "years", "Value": 42, "Type": "Integer"},
		{"Name": "MID_AGE", "Value": 25, "Type": "Integer"},
		{"Name": "word", "Value": "kindred", "Type": "String"},
		{"Name": "red", "Value": "APPLE", "Type": "String"},
	]


func test_add_variables_preserve():
	runner.add_variables([{"Name": "age", "Value": 88, "Type": "Integer"}])
	assert_dict(runner.get_variable("age")).contains_key_value("Value", 5)


func test_add_variables_new():
	runner.add_variables([{"Name": "new", "Value": false, "Type": "Boolean"}])
	assert_dict(runner.get_variable("new")).contains_key_value("Value", false)


func test_fallback():
	runner.fallback_id = "shadows"
	runner.next_id = -1
	runner.fallback()
	assert_str(runner.next_id).is_equal("shadows")


func test_load_dialogue():
	runner.load_dialogue("res://examples/mr_sharpener/intro.json")
	var sharpener = runner.characters[1].get("Reference")
	assert_str(sharpener).is_equal("Mr.Sharpener")


func test_localize():
	runner.locale = "Spanish"
	var value = runner.localize({"English": "today", "Spanish": "hoy"})
	assert_str(value).is_equal("hoy")


func test_localize_plain_value():
	runner.locale = "Spanish"
	var value = runner.localize("no es mismo")
	assert_str(value).is_equal("no es mismo")


func test_localize_nonexist():
	runner.locale = "Spanish"
	var value = runner.localize({"English": "today"})
	assert_str(value).is_equal("")


func test_next():
	var fake = { "$type": "Nope", "ID": "a", "NextID": "b" }
	do_return(fake).on(runner).find_node_from_id(any())
	runner.next_id = -1
	runner.next()
	verify(runner, 1).skip_voiceline()
	verify(runner, 1).skip_timer()
	verify(runner, 1).parse_events()
	verify(runner, 1).fallback()
	verify(runner, 1).process_node(fake)


func test_next_story_valid_without_json_suffix():
	runner.next_story("ending_01")
	verify(runner, 1).load_dialogue("res://examples/mr_sharpener/ending_01.json")


func test_next_story_valid_with_json_suffix():
	runner.next_story("ending_02.json")
	verify(runner, 1).load_dialogue("res://examples/mr_sharpener/ending_02.json")


func test_next_story_invalid():
	runner.next_story("../THIS_STORY_DOESNT_EXIST")
	verify(runner, 0).load_dialogue(any_string())
	verify(runner, 0).next()


func test_parse_events():
	var monitor = monitor_signals(runner)
	var e1 = { "$type": "NodeEvent", "ID": "ei1", "NextID": "en1",
			"Condition": { "Variable": "z", "Operator": "==", "Value": false }}
	var e2 = { "$type": "NodeEvent", "ID": "ei2", "NextID": "en2",
			"Condition": { "Variable": "age", "Operator": "<=", "Value": 11 }}
	runner.events = [e1, e2]
	runner.next_id = "tada"
	runner.parse_events()
	await assert_signal(monitor).is_emitted("monologue_event_triggered", [e2])
	assert_str(runner.fallback_id).is_equal("tada")
	assert_str(runner.next_id).is_equal("en2")
	assert_array(runner.events).is_equal([e1])


func test_play_audio_mp3():
	var mp3 = "res://examples/mr_sharpener/assets/audios/sound.mp3"
	var audio = runner.play_audio(mp3, true, -8.15, 0.421)
	assert_object(audio.stream).is_instanceof(AudioStreamMP3)
	assert_array(audio.stream.data).is_not_empty()
	assert_bool(audio.stream.loop).is_true()
	assert_float(audio.volume_db).is_equal_approx(-8.15, 0.01)
	assert_float(audio.pitch_scale).is_equal_approx(0.421, 0.01)


func test_play_audio_ogg():
	var ogg = "res://examples/mr_sharpener/assets/audios/mystery_sting.ogg"
	var audio = runner.play_audio(ogg)
	assert_object(audio.stream).is_instanceof(AudioStreamOggVorbis)
	assert_array(audio.stream.packet_sequence.packet_data).is_not_empty()
	assert_bool(audio.stream.loop).is_false()
	assert_float(audio.volume_db).is_equal_approx(0.0, 0.01)
	assert_float(audio.pitch_scale).is_equal_approx(1.0, 0.01)


func test_play_audio_wav():
	var wav = "res://examples/mr_sharpener/assets/audios/kalimba.wav"
	var audio = runner.play_audio(wav, true, -2, 1.2)
	assert_object(audio.stream).is_instanceof(AudioStreamWAV)
	assert_array(audio.stream.data).is_not_empty()
	assert_int(audio.stream.loop_mode).is_equal(AudioStreamWAV.LOOP_FORWARD)
	assert_float(audio.volume_db).is_equal_approx(-2, 0.01)
	assert_float(audio.pitch_scale).is_equal_approx(1.2, 0.01)


func test_process_action_variable_equal():
	runner.process_action(v_action)
	assert_int(runner.get_variable("MID_AGE").get("Value")).is_equal(66)


func test_process_action_variable_plus():
	v_action["Operator"] = "+"
	runner.process_action(v_action)
	assert_int(runner.get_variable("MID_AGE").get("Value")).is_equal(91)


func test_process_action_variable_minus():
	v_action["Operator"] = "-"
	runner.process_action(v_action)
	assert_int(runner.get_variable("MID_AGE").get("Value")).is_equal(-41)


func test_process_action_variable_multiply():
	v_action["Operator"] = "*"
	runner.process_action(v_action)
	assert_int(runner.get_variable("MID_AGE").get("Value")).is_equal(1650)


func test_process_action_variable_divide():
	v_action["Operator"] = "/"
	runner.process_action(v_action)
	assert_int(runner.get_variable("MID_AGE").get("Value")).is_equal(0)


func test_process_conditional_text_base():
	var text = "{{       big        }}"
	assert_str(runner.process_conditional_text(text)).is_equal("true")


func test_process_conditional_text_calculation_nested():
	var text = "{{ if age == 2+3 then if big then 9 * 4.2 - 1 else a else b }}"
	assert_str(runner.process_conditional_text(text)).is_equal("36.8")


func test_process_conditional_text_calculation_numbers():
	var text = "{{ 4 * 1.5 + 20 / 5 }}"
	assert_str(runner.process_conditional_text(text)).is_equal("10")


func test_process_conditional_text_calculation_variable():
	var text = "{{ 10 + years }}"
	assert_str(runner.process_conditional_text(text)).is_equal("52")


func test_process_conditional_text_calculation_wrong_type():
	var text = "{{10 - 1 +  x}}"
	# even if substitution happened, spacing is preserved if no evaluation
	assert_str(runner.process_conditional_text(text)).is_equal("10 - 1 +  true")


func test_process_conditional_text_missing_variable():
	var text = "Orange {{if nice then tree else peel}}"
	assert_str(runner.process_conditional_text(text)).is_equal("Orange peel")


func test_process_conditional_text_multiple():
	var m = "{{if x then W}}{{if not y then A else O}}T?{{if big then !}}"
	assert_str(runner.process_conditional_text(m)).is_equal("WOT?!")


func test_process_conditional_text_integer():
	var int_text = "You {{if age >= 5 then old else young}}"
	assert_str(runner.process_conditional_text(int_text)).is_equal("You old")


func test_process_conditional_text_comparison():
	var calc_text = "He's {{ if years - age * 4 + 1 < MID_AGE then 1 else 2 }}"
	assert_str(runner.process_conditional_text(calc_text)).is_equal("He's 1")


func test_process_conditional_text_string_as_is():
	var text = "{{ \"big\" }}"
	assert_str(runner.process_conditional_text(text)).is_equal("big")


func test_process_conditional_text_string_evaluation():
	var str_text = "{{if word.contains(\"red\") then SPECIAL else BORING}}"
	assert_str(runner.process_conditional_text(str_text)).is_equal("SPECIAL")


func test_process_conditional_text_string_quoted():
	var text = "{{ '\"big\"' }}"
	assert_str(runner.process_conditional_text(text)).is_equal("\"big\"")


func test_process_conditional_text_if_only():
	var text = "X {{ if big}}"
	assert_str(runner.process_conditional_text(text)).is_equal("X  if true")


func test_process_conditional_text_if_then_true():
	var text = "Hey {{ if big then \"big guy\"}}"
	assert_str(runner.process_conditional_text(text)).is_equal("Hey big guy")


func test_process_conditional_text_if_then_false():
	runner.variables[0]["Value"] = false
	var text = "Hey {{    if big then big guy         }}"
	assert_str(runner.process_conditional_text(text)).is_equal("Hey ")


func test_process_conditional_text_if_then_else_true():
	var text = "I'm {{ if big then giga else smol }}"
	assert_str(runner.process_conditional_text(text)).is_equal("I'm giga")


func test_process_conditional_text_if_then_else_false():
	runner.variables[0]["Value"] = false
	var text = "I'm {{ if big then big guy else smol }}"
	assert_str(runner.process_conditional_text(text)).is_equal("I'm smol")


func test_process_conditional_text_recursive_true():
	assert_str(runner.process_conditional_text(nested)).is_equal("Gal")


func test_process_conditional_text_recursive_false_inner():
	runner.variables[2]["Value"] = false
	assert_str(runner.process_conditional_text(nested)).is_equal("Gel")


func test_process_conditional_text_recursive_false_outer():
	runner.variables[1]["Value"] = false
	assert_str(runner.process_conditional_text(nested)).is_equal("Gol")


func test_process_conditional_text_recursive_false_outmost():
	runner.variables[0]["Value"] = false
	assert_str(runner.process_conditional_text(nested)).is_equal("Gil")


func test_process_conditional_text_recursive_false_uneven():
	runner.variables[2]["Value"] = false
	var text = "G{{if big then if x then if y then a else e else o}}l"
	var result = runner.process_conditional_text(text)
	assert_str(result).is_equal("Gl")


func test_process_node_sentence():
	runner.characters = [{ "Reference": "Da Hoodlum", "ID": 28 }]
	var monitor = monitor_signals(runner)
	var sentence = {
		"$type": "NodeSentence",
		"ID": "wordsies",
		"NextID": "letterz",
		"Sentence": "Oh, shucks! I am flattered.",
		"SpeakerID": 28,
		"DisplaySpeakerName": "Handsome",
		"DisplayVariant": "",
		"VoicelinePath": "",
	}
	runner.process_node(sentence)
	var signal_args = ["Oh, shucks! I am flattered.", "Handsome", "Da Hoodlum"]
	await assert_signal(monitor).is_emitted("monologue_sentence", signal_args)


func test_pick_random_output():
	var outputs := [
		{ "ID": 0, "Weight": 5, "NextID": "MxRNES6j8G" },
		{ "ID": 1, "Weight": 25, "NextID": "MxRNES6j8G" },
		{ "ID": 2, "Weight": 55, "NextID": "MxRNES6j8G" },
		{ "ID": 3, "Weight": 15, "NextID": "MxRNES6j8G" },
	]
	var results := {}
	
	for output in outputs:
		results[output["ID"]] = 0

	for i in range(10_000):
		var output = runner.pick_random_output(outputs)
		results[output["ID"]] += 1
		
	for output in outputs:
		var expected_probability: float = output.get("Weight")/100
		var actual_probability: float = results[output["ID"]]/10_000
		assert_float(actual_probability).is_between(expected_probability-1, expected_probability+1)


func test_set_option_value():
	runner.node_list = [{ "$type": "NodeOption", "ID": "abc", "NextID": "xyz",
			"Sentence": "Wow!", "Enable": false, "OneShot": true }]
	runner.set_option_value("abc", true)
	assert_bool(runner.node_list[0].get("Enable")).is_true()


func test_select_option_invalid():
	var monitor = monitor_signals(runner)
	runner.select_option({"bad": "option"})
	await assert_signal(monitor).is_emitted("monologue_end", [null])


func test_select_option_valid():
	var monitor = monitor_signals(runner)
	var option = { "$type": "NodeOption", "ID": "v0", "NextID": "v1",
			"Sentence": "Valid?", "Enable": true, "OneShot": true }
	runner.select_option(option)
	await assert_signal(monitor).is_emitted("monologue_option_chosen", [option])
	await assert_signal(monitor).is_not_emitted("monologue_end", [null])
	assert_bool(option.get("Enable")).is_false()


func test_skip_voiceline():
	var fake_voiceline = mock(AudioStreamPlayer2D)
	runner.active_voiceline = fake_voiceline
	assert_object(runner.active_voiceline).is_not_null()
	runner.skip_voiceline()
	assert_object(runner.active_voiceline).is_null()


func test_substitute_variables():
	var subbed = runner.substitute_variables("age == years * hah - red + y")
	assert_str(subbed).is_equal("5 == 42 * hah - \"APPLE\" + true")


func test_substitute_variables_conditional():
	var subbed = runner.substitute_variables("if age > 20 then word else b")
	assert_str(subbed).is_equal("if 5 > 20 then \"kindred\" else b")
