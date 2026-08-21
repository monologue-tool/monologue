extends GdUnitTestSuite

## Putting a node into a chain and taking one out of it.
##
## The drop itself needs a canvas and cannot be tested here. What can be is the part that
## decides where the wires end up, which is the part that gets it wrong.

var _project: MonologueProject
var _storyline: StorylineDocument


func before_test() -> void:
	MonologueRegistry.reset_instance()
	_project = auto_free(MonologueProject.new())
	await _project.ready
	ProjectManager.current_project = _project

	_storyline = _project.storylines[0]
	for node: InspectableNode in _storyline.nodes.duplicate():
		if node.get_type() != "root":
			_storyline.remove_node(node)


func after_test() -> void:
	ProjectManager.current_project = null
	MonologueRegistry.reset_instance()


## By each end's own flow port, which a node type names after itself.
func _wire(from_node: InspectableNode, to_node: InspectableNode) -> NodeConnection:
	var wire: NodeConnection = NodeConnection.create(
		from_node.get_id(), from_node.get_type(), to_node.get_id(), to_node.get_type()
	)
	_storyline.add_connection(wire)
	return wire


## A chain of [param length] sentences, wired end to end.
func _chain(length: int) -> Array[InspectableNode]:
	var made: Array[InspectableNode] = []
	for index: int in length:
		var node: InspectableNode = _storyline.create_node("sentence")
		if not made.is_empty():
			_wire(made[made.size() - 1], node)
		made.append(node)
	return made


func test_the_story_passes_through_a_sentence_and_stops_at_an_end() -> void:
	# Everything else here rests on telling those two apart.
	var line: InspectableNode = _storyline.create_node("sentence")
	var stop: InspectableNode = _storyline.create_node("end")

	assert_object(line.get_pass_through_property()).override_failure_message(
		"A sentence carries the story on, but nothing says so."
	).is_not_null()
	assert_object(stop.get_pass_through_property()).override_failure_message(
		"An end node offered itself as somewhere the story could pass through."
	).is_null()


func test_taking_one_node_out_joins_the_two_it_sat_between() -> void:
	var chain: Array[InspectableNode] = _chain(3)

	var joins: Array[Dictionary] = GraphChain.joins_around(_storyline, [chain[1]])

	assert_int(joins.size()).override_failure_message(
		"Removing one node from a chain of three left %d joins." % joins.size()
	).is_equal(1)
	assert_str(joins[0]["from"]).is_equal(chain[0].get_id())
	assert_str(joins[0]["to"]).is_equal(chain[2].get_id())


func test_taking_a_whole_stretch_out_leaves_one_join_and_not_three() -> void:
	# Each of the three would otherwise join to the next one going, and every one of those
	# wires would land on a node that is not there any more.
	var chain: Array[InspectableNode] = _chain(5)
	var middle: Array[InspectableNode] = [chain[1], chain[2], chain[3]]

	var joins: Array[Dictionary] = GraphChain.joins_around(_storyline, middle)

	assert_int(joins.size()).override_failure_message(
		"Three nodes taken out of the middle left %d joins." % joins.size()
	).is_equal(1)
	assert_str(joins[0]["from"]).is_equal(chain[0].get_id())
	assert_str(joins[0]["to"]).is_equal(chain[4].get_id())


func test_a_node_at_the_end_of_a_chain_joins_to_nothing() -> void:
	var chain: Array[InspectableNode] = _chain(2)

	assert_array(GraphChain.joins_around(_storyline, [chain[1]])).override_failure_message(
		"The last node of a chain was joined onward, to a node that is not there."
	).is_empty()


func test_two_ways_in_each_reach_the_way_out() -> void:
	# A node several chains run through has to leave every one of them joined up.
	var middle: InspectableNode = _storyline.create_node("sentence")
	var after: InspectableNode = _storyline.create_node("sentence")
	var first: InspectableNode = _storyline.create_node("sentence")
	var second: InspectableNode = _storyline.create_node("sentence")
	_wire(first, middle)
	_wire(second, middle)
	_wire(middle, after)

	var joins: Array[Dictionary] = GraphChain.joins_around(_storyline, [middle])

	assert_int(joins.size()).override_failure_message(
		"Two chains ran through the node and %d came out the other side." % joins.size()
	).is_equal(2)


func test_a_node_the_story_stops_at_cannot_be_dropped_into_a_chain() -> void:
	var chain: Array[InspectableNode] = _chain(2)
	var stop: InspectableNode = _storyline.create_node("end")

	var refused: String = GraphChain.refuse_reason(
		_storyline, stop, _storyline.connections[0]
	)

	assert_str(refused).override_failure_message(
		"An end node was allowed into the middle of a chain, where nothing gets past it."
	).is_not_empty()
	assert_int(chain.size()).is_equal(2)


func test_a_node_already_leading_somewhere_is_not_dropped_into_a_chain() -> void:
	# It would come out of the drop with two ways on, which is a fork nobody asked for.
	var chain: Array[InspectableNode] = _chain(2)
	var busy: InspectableNode = _storyline.create_node("sentence")
	_wire(busy, _storyline.create_node("sentence"))

	var refused: String = GraphChain.refuse_reason(
		_storyline, busy, _storyline.connections[0]
	)

	assert_str(refused).override_failure_message(
		"A node that already leads somewhere was dropped into a chain anyway."
	).is_not_empty()
	assert_int(chain.size()).is_equal(2)


func test_a_free_node_is_welcome_in_a_chain() -> void:
	_chain(2)
	var newcomer: InspectableNode = _storyline.create_node("sentence")

	assert_str(
		GraphChain.refuse_reason(_storyline, newcomer, _storyline.connections[0])
	).override_failure_message("A free sentence was turned away from a chain.").is_empty()
