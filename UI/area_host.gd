#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAreaHost
extends Control

@export var window_id: String = "main"

var _view: Control = null
var _leaves: Array[CandyAreaLeaf] = []
var _panels: Dictionary = {}        #/ area_id -> Control
var _panel_types: Dictionary = {}   #/ area_id -> panel_id
#^ Dragging Areas within this window, in Edit Layout mode:
var _drag: CandyAreaDrag


func _ready() -> void:
	CandyThemeDefaults.add_background(self)
	_drag = CandyAreaDrag.new(
		func(area: CandyAreaData) -> String: return CandyPanels.get_title(area.panel_id),
		func(source: CandyAreaData, target: CandyAreaData, zone: CandyAreaDrop.Zone, mode: CandyAreaDrop.Mode) -> bool:
			return CandyLayout.can_drop_area(window_id, source.id, target.id, zone, mode),
		func(source: CandyAreaData, target: CandyAreaData, zone: CandyAreaDrop.Zone, mode: CandyAreaDrop.Mode) -> void:
			CandyLayout.drop_area(window_id, source.id, target.id, zone, mode))

	CandyLayout.editing_changed.connect(func(_editing: bool): rebuild())

	CandyLayout.layout_changed.connect(_on_layout_changed)
	CandyLayout.state_capture_requested.connect(capture_panel_states)
	rebuild()


#* Run window shortcuts:
func _shortcut_input(event: InputEvent) -> void:
	#? After the controls, so a text field keeps the keys it uses.
	if CandyShortcuts.handle_window_event(event, get_window()):
		get_viewport().set_input_as_handled()


func _on_layout_changed(changed_window_id: String) -> void:
	if changed_window_id == window_id:
		rebuild()


#* Rebuild the view:
func rebuild() -> void:
	#@ Step 1 - Detach panels so they survive the old view being freed:
	for leaf in _leaves:
		leaf.take_panel()
	_leaves.clear()
	if _view != null:
		remove_child(_view)
		_view.queue_free()
		_view = null

	var root := CandyLayout.get_root(window_id)
	var used := {}
	if root != null:
		_view = _build(root, used, CandyLayout.is_editing())
		add_child(_view)
		_place_view()

	#@ Step 2 - Free panels whose Area is gone:
	for area_id in _panels.keys():
		if not used.has(area_id):
			_panels[area_id].queue_free()
			_panels.erase(area_id)
			_panel_types.erase(area_id)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_place_view()


func _place_view() -> void:
	if _view == null:
		return
	var margin := get_theme_constant(&"margin", CandyThemeDefaults.AREA_HOST)
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, margin)


#* Build the view of an Area:
func _build(area: CandyAreaData, used: Dictionary, editing: bool) -> Control:
	if area.is_leaf():
		used[area.id] = true
		var leaf := CandyAreaLeaf.new()
		leaf.setup(window_id, area, _get_panel_for(area))
		_leaves.append(leaf)
		if editing and leaf.area_button != null:			#/ Edit Layout mode: editable Areas get their frame
			return CandyAreaCap.around(CandyAreaFrame.around_leaf(leaf, leaf.area_button, &"window", _drag), area.config)
		return CandyAreaCap.around(leaf, area.config)

	var editable := CandyLayout.can_edit_split(window_id, area.id)
	var split := CandyAreaSplit.new()
	split.setup(area, _build(area.first, used, editing), _build(area.second, used, editing))
	if not editable:
		return split
	split.enable_menu(CandyPanels.get_title, _can_remove_side)
	split.enable_layouts(CandyLayoutLibrary.AREAS, _capture_area)
	split.edit_requested.connect(_on_split_edit_requested)
	if not editing:
		return split
	return CandyAreaFrame.around_split(split, &"window")


func _capture_area(area: CandyAreaData) -> Dictionary:
	return CandyLayout.area_layout(window_id, area.id)


func _can_remove_side(child: CandyAreaData) -> bool:
	return CandyLayout.can_close_area(window_id, child.id)


func _on_split_edit_requested(action: String, area: CandyAreaData, argument: Variant) -> void:
	match action:
		"wrap":
			CandyLayout.split_area(window_id, area.id, argument[0], argument[1])
		"insert":
			CandyLayout.insert_area(window_id, area.id)
		"swap":
			CandyLayout.swap_split(window_id, area.id)
		"rotate":
			CandyLayout.rotate_split(window_id, area.id)
		"remove":
			CandyLayout.close_area(window_id, area.id)
		"replace":
			CandyLayout.replace_area(window_id, area.id, argument)


func _get_panel_for(area: CandyAreaData) -> Control:
	if _panels.has(area.id):
		if _panel_types[area.id] == area.panel_id:
			return _panels[area.id]
		_panels[area.id].queue_free()  #/ Panel type changed

	var panel := CandyPanels.instantiate(area.panel_id)
	if panel is CandyPanel:
		panel.area_id = area.id
		panel.window_id = window_id
		panel.fills_area = true
		if not area.panel_state.is_empty():
			panel.set_state(area.panel_state)
	_panels[area.id] = panel
	_panel_types[area.id] = area.panel_id
	return panel


#* Copy each panel's state into its Area, to be saved:
func capture_panel_states() -> void:
	for area_id in _panels:
		var panel: Control = _panels[area_id]
		var area := CandyLayout.find_area(window_id, area_id)
		if area != null and panel is CandyPanel:
			area.panel_state = panel.get_state()