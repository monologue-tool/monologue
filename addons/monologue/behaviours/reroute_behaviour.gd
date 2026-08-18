## Passes the story straight through, which is all a reroute is: a bent wire.
##
## It runs what an unclaimed node runs, and exists only so that it is claimed. Reading the
## folder then answers which types this runtime knows, and falling through to the path is
## left meaning one thing: nobody has heard of this type.
extends MonologuePathThroughBehaviour


func handles() -> PackedStringArray:
	return ["reroute"]
