## Putting a node into a chain and taking one out of it, without the wires either side having
## to be redrawn by hand.
##
## Only the property the story passes through is ever joined. An option wired into a choice is
## not that kind of link, and bridging across it would invent a route nobody drew.
class_name GraphChain extends RefCounted

## Space left between a node dropped into a chain and whatever it pushed out of the way.
const GAP: float = 40.0


## Takes a drop that landed on a wire the node can join. True when it did.
##
## The wire's two ends stay where they are: whatever fed the wire now feeds the node, and the
## node feeds whatever the wire fed. Anything the newcomer landed on top of is pushed right,
## by exactly enough to clear it, so a chain does not end up piled in one place.
static func take_drop(graph: MonologueGraphEdit, node: InspectableNode) -> bool:
	var storyline: StorylineDocument = graph.get_storyline()
	if storyline == null or node == null:
		return false

	var wire: NodeConnection = wire_under(graph, node)
	if wire == null:
		return false

	var refused: String = refuse_reason(storyline, node, wire)
	if not refused.is_empty():
		Log.info(refused)
		return false

	_insert(graph, storyline, node, wire)
	graph.refresh()
	return true


## The wire running under a node, or null when none does. The reach is half the node's height,
## so the wire has to pass through the node and not merely near it.
static func wire_under(graph: MonologueGraphEdit, node: InspectableNode) -> NodeConnection:
	var view: GraphNode = node.graph_view as GraphNode
	if not is_instance_valid(view):
		return null

	var middle: Vector2 = view.position + view.size * graph.zoom / 2.0
	return graph.wire_at(middle, view.size.y * graph.zoom / 2.0)


## Why this node cannot take that wire's place, or "" when it can.
static func refuse_reason(
	storyline: StorylineDocument, node: InspectableNode, wire: NodeConnection
) -> String:
	var named: String = Util.to_readable_name(node.get_type())
	if wire.from_node_id == node.get_id() or wire.to_node_id == node.get_id():
		return "That wire already ends at this %s." % named

	var passes: Property = node.get_pass_through_property()
	if passes == null:
		return "The story stops at a %s, so it cannot sit in the middle of a chain." % named

	if not storyline.get_outgoing(node.get_id(), passes.name).is_empty():
		return "This %s already leads somewhere, so dropping it here would fork the story." % named

	return ""


## Takes nodes out, joining what fed them to what they fed, in one step.
##
## A whole stretch can go at once: the join skips over everything else on its way out, so
## three nodes removed from the middle of a chain leave one wire and not three dangling ends.
static func bridge_out(
	graph: MonologueGraphEdit, nodes: Array[InspectableNode], sections: Array[StorylineDocument]
) -> bool:
	var storyline: StorylineDocument = graph.get_storyline()
	if storyline == null or nodes.is_empty():
		return false

	var joins: Array[Dictionary] = joins_around(storyline, nodes)
	var history: CommandManager = storyline.history
	var step: CommandTransaction = history.begin(
		"Remove %d nodes from the chain" % nodes.size()
	)

	# Wired first, then the nodes go. A join touches neither end being removed, so the delete
	# takes the old wires and leaves the new one standing.
	for join: Dictionary in joins:
		history.execute(
			NodeConnectionCommand.new(
				graph, join["from"], join["to"], join["from_name"], join["to_name"]
			)
		)

	history.execute(DeleteNodesCommand.new(storyline.id, nodes, sections))
	step.commit()

	graph.refresh()
	return true


## The wires that would join what feeds these nodes to what they feed, once they are gone.
static func joins_around(
	storyline: StorylineDocument, nodes: Array[InspectableNode]
) -> Array[Dictionary]:
	var leaving: Dictionary[String, bool] = {}
	for node: InspectableNode in nodes:
		leaving[node.get_id()] = true

	var joins: Array[Dictionary] = []
	for node: InspectableNode in nodes:
		var passes: Property = node.get_pass_through_property()
		if passes == null:
			continue

		var lands: Array[NodeConnection] = _survivors_after(storyline, node, leaving)
		for incoming: NodeConnection in storyline.get_incoming(node.get_id(), passes.name):
			if leaving.has(incoming.from_node_id):
				continue
			for outgoing: NodeConnection in lands:
				joins.append(
					{
						"from": incoming.from_node_id,
						"from_name": incoming.get_from_name(),
						"to": outgoing.to_node_id,
						"to_name": outgoing.get_to_name(),
					}
				)
	return joins


## Where the story lands once a run of nodes is gone: the first wires whose target stays.
## Walks through the ones leaving, so a whole stretch taken out still joins up.
static func _survivors_after(
	storyline: StorylineDocument, node: InspectableNode, leaving: Dictionary[String, bool]
) -> Array[NodeConnection]:
	var landed: Array[NodeConnection] = []
	var seen: Dictionary[String, bool] = {}
	var pending: Array[InspectableNode] = [node]

	while not pending.is_empty():
		var walked: InspectableNode = pending.pop_front()
		if seen.has(walked.get_id()):
			continue
		seen[walked.get_id()] = true

		var passes: Property = walked.get_pass_through_property()
		if passes == null:
			continue

		for outgoing: NodeConnection in storyline.get_outgoing(walked.get_id(), passes.name):
			if not leaving.has(outgoing.to_node_id):
				landed.append(outgoing)
				continue

			var next: InspectableNode = storyline.get_node(outgoing.to_node_id)
			if next != null:
				pending.append(next)

	return landed


static func _insert(
	graph: MonologueGraphEdit,
	storyline: StorylineDocument,
	node: InspectableNode,
	wire: NodeConnection
) -> void:
	var passes: Property = node.get_pass_through_property()
	var history: CommandManager = storyline.history
	var step: CommandTransaction = history.begin(
		"Insert %s into the chain" % Util.to_readable_name(node.get_type())
	)

	history.execute(
		NodeConnectionCommand.new(
			graph,
			wire.from_node_id,
			wire.to_node_id,
			wire.get_from_name(),
			wire.get_to_name(),
			true
		)
	)
	history.execute(
		NodeConnectionCommand.new(
			graph, wire.from_node_id, node.get_id(), wire.get_from_name(), passes.name
		)
	)
	history.execute(
		NodeConnectionCommand.new(
			graph, node.get_id(), wire.to_node_id, passes.name, wire.get_to_name()
		)
	)

	_make_room(storyline, node, wire.to_node_id, history)
	step.commit()


## Shifts what the newcomer overlaps, and everything downstream of it, far enough right to
## clear it. Nothing moves when there was already room.
static func _make_room(
	storyline: StorylineDocument,
	node: InspectableNode,
	pushed_id: String,
	history: CommandManager
) -> void:
	var pushed: InspectableNode = storyline.get_node(pushed_id)
	if pushed == null:
		return

	var landed: Rect2 = _rect_of(node)
	var shift: float = landed.end.x + GAP - pushed.get_editor_position().x
	if shift <= 0.0:
		return

	for downstream: InspectableNode in _chain_from(storyline, pushed_id, node.get_id()):
		var was: Vector2 = downstream.get_editor_position()
		history.execute(
			PropertyChangeCommand.new(
				downstream, "editor_position", [was.x, was.y], [was.x + shift, was.y]
			)
		)


## Where a node sits and how much room it takes, in graph coordinates.
static func _rect_of(node: InspectableNode) -> Rect2:
	var view: GraphNode = node.graph_view as GraphNode
	var taken: Vector2 = view.size if is_instance_valid(view) else Vector2.ZERO
	return Rect2(node.get_editor_position(), taken)


## Everything the story reaches from [param start_id], that one included. Remembers where it
## has been, so a chain looping back on itself is walked once and the newcomer never moves.
static func _chain_from(
	storyline: StorylineDocument, start_id: String, skip_id: String
) -> Array[InspectableNode]:
	var found: Array[InspectableNode] = []
	var seen: Dictionary[String, bool] = {skip_id: true}
	var pending: Array[String] = [start_id]

	while not pending.is_empty():
		var node_id: String = pending.pop_front()
		if seen.has(node_id):
			continue
		seen[node_id] = true

		var node: InspectableNode = storyline.get_node(node_id)
		if node == null:
			continue
		found.append(node)

		for wire: NodeConnection in storyline.get_outgoing(node_id):
			pending.append(wire.to_node_id)

	return found
