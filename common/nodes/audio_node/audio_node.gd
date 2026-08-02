class_name AudioNode extends InspectableNode


func initialize_properties() -> void:
	define_property(Property.new("audio")
		.set_type("context")
		.main_property()
		.exposed()
		.exported())

	define_property(Property.new("stream")
		.set_type("file")
		.file_filters(["*.ogg", "*.wav", "*.mp3"])
		.required()
		.tooltip("Sound or music to play from here on."))

	define_property(Property.new("playback/loop")
		.set_type("bool")
		.hidden_in_graph()
		.tooltip("Keeps playing until something else stops it."))

	define_property(Property.new("playback/volume")
		.set_type("float")
		.default(0.0)
		.bounds(-60.0, 6.0, 0.5)
		.suffix("dB")
		.hidden_in_graph()
		.tooltip("0 plays the file at the level it was recorded."))

	define_property(Property.new("playback/pitch")
		.set_type("float")
		.default(1.0)
		.bounds(0.1, 4.0, 0.05)
		.hidden_in_graph())


func get_type() -> String:
	return "audio"
