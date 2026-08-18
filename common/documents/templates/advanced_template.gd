class_name AdvancedTemplate extends DefaultTemplate

func _get_default_eases() -> Dictionary:
	var eases: Dictionary = super._get_default_eases()
	eases.merge({
		"Ease-Out-In": [0.58, 1.0, 0.42, 0.0],

		"Ease-In-Sine": [0.13, 0.0, 0.39, 0.0],
		"Ease-Out-Sine": [0.61, 1.0, 0.87, 1.0],
		"Ease-In-Out-Sine": [0.36, 0.0, 0.64, 1.0],
		"Ease-Out-In-Sine": [0.64, 1.0, 0.36, 0.0],

		"Ease-In-Quad": [0.11, 0.0, 0.5, 0.0],
		"Ease-Out-Quad": [0.5, 1.0, 0.89, 1.0],
		"Ease-In-Out-Quad": [0.44, 0.0, 0.56, 1.0],
		"Ease-Out-In-Quad": [0.56, 1.0, 0.44, 0.0],

		"Ease-In-Cubic": [0.32, 0.0, 0.67, 0.0],
		"Ease-Out-Cubic": [0.33, 1.0, 0.68, 1.0],
		"Ease-In-Out-Cubic": [0.66, 0.0, 0.34, 1.0],
		"Ease-Out-In-Cubic": [0.34, 1.0, 0.66, 0.0],

		"Ease-In-Quart": [0.5, 0.0, 0.75, 0.0],
		"Ease-Out-Quart": [0.25, 1.0, 0.5, 1.0],
		"Ease-In-Out-Quart": [0.78, 0.0, 0.22, 1.0],
		"Ease-Out-In-Quart": [0.22, 1.0, 0.78, 0.0],

		"Ease-In-Quint": [0.64, 0.0, 0.78, 0.0],
		"Ease-Out-Quint": [0.22, 1.0, 0.36, 1.0],
		"Ease-In-Out-Quint": [0.86, 0.0, 0.14, 1.0],
		"Ease-Out-In-Quint": [0.14, 1.0, 0.86, 0.0],

		"Ease-In-Expo": [0.7, 0.0, 0.84, 0.0],
		"Ease-Out-Expo": [0.16, 1.0, 0.3, 1.0],
		"Ease-In-Out-Expo": [0.9, 0.0, 0.1, 1.0],
		"Ease-Out-In-Expo": [0.1, 1.0, 0.9, 0.0],

		"Ease-In-Circ": [0.55, 0.0, 1.0, 0.45],
		"Ease-Out-Circ": [0.0, 0.55, 0.45, 1.0],
		"Ease-In-Out-Circ": [0.85, 0.09, 0.15, 0.91],
		"Ease-Out-In-Circ": [0.15, 0.91, 0.85, 0.09],

		"Ease-In-Back": [0.36, 0.0, 0.66, -0.56],
		"Ease-Out-Back": [0.34, 1.56, 0.64, 1.0],

		"Ease-In-Out-Jump": [1.0, 0.0, 0.0, 1.0],
		"Ease-Out-In-Back": [0.0, 1.0, 1.0, 0.0],

		"Ease-In-Out-Anticipate": [0.8, -0.4, 0.5, 1.0],
	})
	return eases

func _get_default_languages() -> Dictionary:
	return {
		"en": "English",
		"es": "Spanish",
		"fr": "French"
	}
