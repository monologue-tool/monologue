## The colours Monologue draws its types in.
##
## One entry per family of meaning, not one per type: a graph port, a picker pastille
## and a node border all read the same because they name the same thing. A new type
## picks the family it belongs to rather than inventing a shade.
class_name MonologuePalette

## Story flow. The wires that carry the reader from one node to the next.
const FLOW: Color = Color("d8d8d8")
## Words the player reads.
const TEXT: Color = Color("af85fd")
## Numbers, and anything measured.
const NUMBER: Color = Color("45cee9")
## Yes or no.
const FLAG: Color = Color("f2997e")
## Branching: choices offered and the options that make them up.
const CHOICE: Color = Color("e89145")
## Tests, variables, and everything that decides.
const LOGIC: Color = Color("d1b37b")
## Something that fires on its own rather than in sequence.
const EVENT: Color = Color("966fc5")
## A pointer at another object.
const REFERENCE: Color = Color("b48ead")
## Something holding several of something else, and the plumbing between them.
const CONTAINER: Color = Color("87b26c")
## Files: images, sounds, anything on disk.
const ASSET: Color = Color("6a9fb5")
## Curves and easings.
const CURVE: Color = Color("9df27e")
## People.
const CHARACTER: Color = Color("eb5074")
