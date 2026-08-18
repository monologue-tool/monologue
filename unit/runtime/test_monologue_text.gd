extends GdUnitTestSuite

## How a stored value becomes the line a player reads. This is format, not implementation:
## the fallback order decides what a half-translated story shows, so a port that resolves
## text differently plays a different game.


func test_the_asked_for_language_wins_and_a_gap_falls_back_rather_than_going_blank() -> void:
	# A blank line reads as a bug in the game; another language reads as a gap in the
	# translation, which is what it is. Whitespace is a gap too.
	var both: Dictionary = {"en": "Hello.", "fr": "Bonjour."}
	assert_str(MonologueText.to_label(both, "fr")).is_equal("Bonjour.")
	assert_str(MonologueText.to_label(both, "en")).is_equal("Hello.")

	assert_str(MonologueText.to_label({"en": "Hello."}, "fr")).is_equal("Hello.")
	assert_str(MonologueText.to_label({"fr": "   ", "en": "Hello."}, "fr")).is_equal("Hello.")

	# Anything that is not a translation is read as it stands, and nothing reads as nothing.
	assert_str(MonologueText.to_label("Hello.", "fr")).is_equal("Hello.")
	assert_str(MonologueText.to_label("  padded  ")).is_equal("padded")
	assert_str(MonologueText.to_label(3, "en")).is_equal("3")
	for empty: Variant in [{}, null, [], {"en": "  "}]:
		assert_str(MonologueText.to_label(empty, "en")).override_failure_message(
			"%s should read as nothing at all." % str(empty)
		).is_empty()


func test_a_value_carries_only_the_languages_that_actually_say_something() -> void:
	assert_array(
		MonologueText.languages_of({"en": "Hello.", "fr": "  ", "nl": "Hallo."})
	).contains_exactly(["en", "nl"])
	assert_array(MonologueText.languages_of("plain")).is_empty()
