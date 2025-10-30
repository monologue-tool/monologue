## Cursor resources singleton.
##
## Provides preloaded cursor texture resources for use throughout the application.
extends Node

## Default arrow cursor texture resource.
@onready var arrow = preload("res://ui/assets/cursors/cursor.svg")

## Hand cursor texture resource for interactive elements.
@onready var hand = preload("res://ui/assets/cursors/hand.svg")

## Closed hand cursor texture resource for drag operations.
@onready var closed_hand = preload("res://ui/assets/cursors/closed_hand.svg")
