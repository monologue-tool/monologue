## The colours Monologue draws its types in. One per family of meaning, so a port, a
## pastille and a node border for the same thing all match.
##
## New types pick an existing family.
class_name MonologuePalette

const FLOW: Color = Color("d8d8d8")
const TEXT: Color = Color("af85fd")
const NUMBER: Color = Color("45cee9")
const FLAG: Color = Color("f2997e")
## Choices offered, and the options they are made of.
const CHOICE: Color = Color("e89145")
## Tests, variables, and everything that decides.
const LOGIC: Color = Color("d1b37b")
## Fires on its own, out of sequence.
const EVENT: Color = Color("966fc5")
const REFERENCE: Color = Color("b48ead")
## Holds several of something else, and the plumbing between them.
const CONTAINER: Color = Color("87b26c")
## Images, sounds, anything on disk.
const ASSET: Color = Color("6a9fb5")
const CURVE: Color = Color("9df27e")
const CHARACTER: Color = Color("eb5074")

## The colour each node category is drawn in. Lets the graph be read by area before any
## title is. A type that needs to stand out sets its own [member MonologueIndexer.color].
const NODE_CATEGORIES: Dictionary = {
	"Flow": FLOW,
	"Narration": TEXT,
	"Stage": ASSET,
	"Logic": LOGIC,
	"Value": NUMBER,
	"World": CONTAINER,
}


static func for_category(category: String) -> Color:
	var declared: Variant = NODE_CATEGORIES.get(category)
	return declared if declared is Color else Color.WHITE
