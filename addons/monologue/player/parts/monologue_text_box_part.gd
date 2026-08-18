## The line of dialogue on screen.
##
## Every part signal takes no arguments and what it produced is read off the part: that is
## what lets the player await any of them through one path, and therefore cancel any of them
## through one path.
##
## No method here blocks. Each starts something and the matching signal says when it is done.
@abstract class_name MonologueTextBoxPart extends Control

@warning_ignore_start("unused_signal")
signal line_finished
signal answer_given
signal continued

## What the player last typed, for [signal answer_given].
var answer: String = ""


@abstract func show_line(line: String, speaker: String, tint: Color) -> void
@abstract func show_prompt(prompt: String, placeholder: String, allow_empty: bool) -> void
## Reveals the whole line at once. What a skip does.
@abstract func skip() -> void
@abstract func clear() -> void
