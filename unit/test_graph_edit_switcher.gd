extends GdUnitTestSuite

var switcher: GraphEditSwitcher


func before_test():
	switcher = auto_free(GraphEditSwitcher.new())
	switcher.graph_edits = auto_free(Control.new())
	switcher.graph_edits.add_child(auto_free(Control.new()))
	switcher.tab_bar = auto_free(TabBar.new())
	switcher.tab_bar.add_tab("+")
	switcher.inspector_panel = mock(InspectorPanel)


func test_add_root():
	var ge = mock(MonologueGraphEdit, CALL_REAL_FUNC)
	switcher.graph_edits.add_child(ge)
	switcher.tab_bar.add_tab("new")
	switcher.tab_bar.current_tab = 1
	assert_object(ge.get_root_node()).is_null()
	switcher.add_root()
	assert_object(ge.get_root_node()).is_instanceof(RootNode)
	# calling add_root() again should not increase child count
	var child_count = ge.get_child_count()
	switcher.add_root()
	assert_int(ge.get_child_count()).is_equal(child_count)


func test_add_tab_first():
	switcher.add_tab("kitty.json")
	assert_int(switcher.tab_bar.current_tab).is_equal(0)
	assert_str(switcher.tab_bar.get_tab_title(0)).is_equal("kitty.json")


func test_add_tab_with_previous():
	switcher.tab_bar.remove_tab(0)
	switcher.tab_bar.add_tab("zero")
	switcher.tab_bar.add_tab("one")
	switcher.tab_bar.add_tab("+")
	switcher.add_tab("two")
	assert_int(switcher.tab_bar.current_tab).is_equal(2)
	assert_str(switcher.tab_bar.get_tab_title(2)).is_equal("two")


func test_connect_inspector_panel():
	var ge = mock(MonologueGraphEdit, CALL_REAL_FUNC)
	switcher.connect_inspector_panel(ge)
	var select = switcher.inspector_panel.on_graph_node_selected
	assert_bool(ge.is_connected("node_selected", select)).is_true()
	var deselect = switcher.inspector_panel.on_graph_node_deselected
	assert_bool(ge.is_connected("node_deselected", deselect)).is_true()
	var save = switcher.update_save_state
	assert_bool(ge.undo_redo.is_connected("version_changed", save)).is_true()


func test_commit_inspector_panel():
	var node = mock(MonologueGraphNode)
	switcher.commit_inspector_panel(node)
	verify(switcher.inspector_panel, 1).refocus(node)


func test_get_current_graph_edit():
	switcher.tab_bar.add_tab("one")
	switcher.tab_bar.add_tab("two")
	var one = auto_free(Control.new())
	var two = auto_free(Control.new())
	switcher.graph_edits.add_child(one)
	switcher.graph_edits.add_child(two)
	switcher.tab_bar.current_tab = 2
	assert_object(switcher.current).is_same(two)


func test_is_file_opened_false():
	assert_bool(switcher.is_file_opened("kennel/doggy.json")).is_false()


func test_is_file_opened_true():
	var doggy = mock(MonologueGraphEdit)
	doggy.file_path = "kennel/doggy.json"
	switcher.graph_edits.add_child(doggy)
	assert_bool(switcher.is_file_opened("kennel/doggy.json")).is_true()


func test_new_graph_edit():
	switcher.new_graph_edit()
	var graph_edit = switcher.graph_edits.get_child(1)
	var root = graph_edit.get_nodes()[0]
	# check if RootNode was created in the new graph edit
	assert_object(root).is_instanceof(RootNode)
	graph_edit.free()


func test_on_tab_close_pressed_saved():
	var ge = mock(MonologueGraphEdit)
	do_return(false).on(ge).is_unsaved()
	switcher.graph_edits.add_child(ge)
	var spy_switcher = spy(switcher)
	spy_switcher._on_tab_close_pressed(1)
	verify(spy_switcher, 1)._close_tab(ge, 1)


func test_on_tab_close_pressed_unsaved():
	var ge = mock(MonologueGraphEdit)
	do_return(true).on(ge).is_unsaved()
	switcher.graph_edits.add_child(ge)
	switcher._on_tab_close_pressed(1)

	var save_prompt = null
	for node in switcher.get_children():
		if node is PromptWindow:
			save_prompt = node
			break
	assert_object(save_prompt).is_not_null()
	save_prompt.free()


func test_show_current_config():
	var ge = mock(MonologueGraphEdit)
	switcher.graph_edits.add_child(ge)
	switcher.tab_bar.add_tab("ge")
	switcher.tab_bar.current_tab = 1
	switcher.show_current_config()
	verify(ge, 1).get_root_node()


func test_update_save_state_saved():
	var ge = mock(MonologueGraphEdit)
	do_return(false).on(ge).is_unsaved()
	switcher.graph_edits.add_child(ge)
	switcher.tab_bar.add_tab("wassup*")
	switcher.tab_bar.current_tab = 1
	switcher.update_save_state()
	assert_str(switcher.tab_bar.get_tab_title(1)).is_equal("wassup")


func test_update_save_state_unsaved():
	var ge = mock(MonologueGraphEdit)
	do_return(true).on(ge).is_unsaved()
	switcher.graph_edits.add_child(ge)
	switcher.tab_bar.add_tab("wassup")
	switcher.tab_bar.current_tab = 1
	switcher.update_save_state()
	assert_str(switcher.tab_bar.get_tab_title(1)).is_equal("wassup*")
