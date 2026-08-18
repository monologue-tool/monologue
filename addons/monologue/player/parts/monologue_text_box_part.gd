## The line of dialogue on screen.
##
## Part signals take no arguments. What they produced is read off the part, so the player
## handles all of them through one path.
##
## No method here blocks. Each starts something, and the matching signal says when it is
## done.
@abstract class_name MonologueTextBoxPart extends Control

@warning_ignore_start("unused_signal")
signal line_finished
signal answer_given
signal continued

var answer: String = ""


@abstract func show_line(line: String, speaker: String, tint: Color) -> void
@abstract func show_prompt(prompt: String, placeholder: String, allow_empty: bool) -> void
@abstract func skip() -> void
@abstract func clear() -> void
