extends GdUnitTestSuite

## The presentation the addon ships with: the pieces of it that can be answered without a
## screen. What it looks like is not testable here and is not what these are for -- what is,
## is that it reads what a story names wherever that happens to live, and that a curve an
## author drew is the curve a fade follows.


func test_a_picture_that_is_not_there_reads_as_nothing_rather_than_failing() -> void:
	# A story half-written names art that has not been drawn yet. That is a normal state for
	# a story and must not stop it playing.
	assert_object(MonologueAssets.picture("")).is_null()
	assert_object(MonologueAssets.picture("res://nothing/at/all.png")).is_null()
	assert_object(MonologueAssets.sound("")).is_null()
	assert_object(MonologueAssets.sound("res://nothing/at/all.ogg")).is_null()

	# Asking again is free, and answers the same.
	assert_object(MonologueAssets.picture("res://nothing/at/all.png")).is_null()
	MonologueAssets.forget()


func test_a_picture_beside_the_story_is_read_the_same_as_one_inside_the_game() -> void:
	# The case ResourceLoader alone cannot serve: art that lives next to the save rather than
	# in the export. It is the usual case for a story, not the exception.
	var loose: String = "%s/portrait.png" % create_temp_dir("assets")
	var drawn: Image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	drawn.fill(Color.RED)
	assert_int(drawn.save_png(loose)).is_equal(OK)

	var texture: Texture2D = MonologueAssets.picture(loose)
	assert_object(texture).override_failure_message(
		"A picture sitting next to the story was not read."
	).is_not_null()
	assert_int(texture.get_width()).is_equal(4)

	# And the second asking is the same object, not a second read of the disk.
	assert_object(MonologueAssets.picture(loose)).is_same(texture)
	MonologueAssets.forget()


func test_a_fade_follows_the_curve_the_author_drew() -> void:
	# The curve says y for a given x, and x is not the parameter: reading it as though it
	# were is the mistake that makes every easing look almost right.
	var linear: Array = [0.0, 0.0, 1.0, 1.0]
	var ease_out: Array = [0.0, 0.0, 0.58, 1.0]

	for at: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		assert_float(MonologueDefaultCharacters._eased(linear, at)).override_failure_message(
			"A straight curve bent."
		).is_equal_approx(at, 0.01)

	# Both ends are pinned wherever the curve goes in between.
	assert_float(MonologueDefaultCharacters._eased(ease_out, 0.0)).is_equal_approx(0.0, 0.01)
	assert_float(MonologueDefaultCharacters._eased(ease_out, 1.0)).is_equal_approx(1.0, 0.01)

	# An ease-out is ahead of a straight line for the whole of the middle.
	assert_float(MonologueDefaultCharacters._eased(ease_out, 0.5)).override_failure_message(
		"An ease-out did not run ahead of a straight line."
	).is_greater(0.5)

	# Nothing to follow is a straight line rather than a stumble.
	assert_float(MonologueDefaultCharacters._eased([], 0.4)).is_equal_approx(0.4, 0.01)


func test_the_player_the_addon_ships_carries_all_five_of_its_parts() -> void:
	# Every one of them is a NodePath into the scene, and a scene edited by hand is exactly
	# where one of those quietly stops pointing at anything.
	var player: MonologueDefaultPlayer = auto_free(MonologueDefaultPlayer.create())
	add_child(player)

	assert_object(player.text_box).is_not_null()
	assert_object(player.choices).is_not_null()
	assert_object(player.characters).override_failure_message(
		"The shipped player has nobody to put on stage."
	).is_not_null()
	assert_object(player.scenery).override_failure_message(
		"The shipped player has nothing to put behind them."
	).is_not_null()
	assert_object(player.sound).override_failure_message(
		"The shipped player is silent."
	).is_not_null()
