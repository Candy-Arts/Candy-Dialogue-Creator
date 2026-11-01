#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Node

#^ A window's tree structure changed (deferred, at most once per frame):
signal layout_changed(window_id: String)
#^ Right before saving - hosts copy panel state into the tree:
signal state_capture_requested
#^ Edit Layout was turned on or off:
signal editing_changed(editing: bool)

const MAIN_WINDOW_ID := "main"
#^ The layout's key in ProfileSettings.txt:
const SETTINGS_KEY := "ui_layout"
const EDITING_KEY := "edit_layout"
const SAVE_VERSION := 1
const DEFAULT_WINDOW_SIZE := Vector2i(900, 600)
#^ The built-in layout (see the top of this script):
const DEFAULT_LAYOUT_FILE := "res://Defaults/window_layout.txt"

#^ Extra windows' theme (set by CandyTheme):
var window_theme: Theme = null

var _roots: Dictionary = {}     #/ window_id -> CandyAreaData
var _windows: Dictionary = {}   #/ window_id -> Window (extra windows only)
var _dirty: Dictionary = {}     #/ window_id -> true
var _window_counter: int = 0


func _ready() -> void:
	#? Also set in project.godot. Real OS windows where supported.
	if DisplayServer.has_feature(DisplayServer.FEATURE_SUBWINDOWS):
		get_tree().root.gui_embed_subwindows = false

	#? The layout belongs to a profile - nothing is built until one opens.
	CandyProfiles.profile_opened.connect(_on_profile_opened)
	CandyProfiles.profile_closed.connect(_on_profile_closed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_layout()
		CandyProfiles.save_settings()


func _on_profile_opened(_user: String, _profile: String) -> void:
	if not load_layout():
		_apply_default_layout()


func _on_profile_closed() -> void:
	for window_id in _windows.keys():
		close_window(window_id)
	_roots.clear()
	layout_changed.emit.call_deferred(MAIN_WINDOW_ID)


#& Edit Layout

func is_editing() -> bool:
	return bool(CandyProfiles.get_setting(EDITING_KEY, false))


func set_editing(value: bool) -> void:
	if value == is_editing():
		return
	CandyProfiles.set_setting(EDITING_KEY, value)
	editing_changed.emit(value)


#& Default layout & system locks

#* Apply the built-in layout to every window (build_default_layout() as fallback):
func _apply_default_layout() -> void:
	if apply_layout_data(CandyVariantFile.read(DEFAULT_LAYOUT_FILE)):
		return
	push_warning("CandyLayout: %s is missing or unusable; using the fallback layout." % DEFAULT_LAYOUT_FILE)
	for window_id in _windows.keys():
		close_window(window_id)
	_roots = {MAIN_WINDOW_ID: build_default_layout()}
	_mark_changed(MAIN_WINDOW_ID)


#* Build the fallback layout:
func build_default_layout() -> CandyAreaData:
	var navigator := CandyAreaData.make_leaf("navigator")
	var buttons := CandyAreaData.make_leaf("dialogue_buttons")
	var editor := CandyAreaData.make_leaf("dialogue_editor")
	var left := CandyAreaData.make_split(CandyAreaData.Layout.TOP_BOTTOM, navigator, buttons, 0.8)
	var workspace := CandyAreaData.make_split(CandyAreaData.Layout.LEFT_RIGHT, left, editor, 0.3)
	return _with_top_bar(workspace)


#* Make a window's root, the top bar over workspace, locked:
func _with_top_bar(workspace: CandyAreaData) -> CandyAreaData:
	var top_bar := CandyAreaData.make_leaf("top_bar")
	var root := CandyAreaData.make_split(CandyAreaData.Layout.TOP_BOTTOM, top_bar, workspace)
	_apply_system_locks(root)
	return root


#* Lock a window's [top bar] over [workspace] split:
func _apply_system_locks(root: CandyAreaData) -> void:
	#? Re-applied from code, so an edited save file can't unlock it.
	root.layout = CandyAreaData.Layout.TOP_BOTTOM
	root.size_mode = CandyAreaData.SizeMode.FIXED_FIRST
	root.fixed_size = 0.0  #/ = the top bar's minimum height
	root.can_resize = false
	root.can_collapse = false

	var top := root.first
	top.can_change_panel = false
	top.can_split = false
	top.can_close = false
	top.show_header = false


#* Give Areas of a panel type that no longer exists the default panel:
func _replace_missing_panels(root: CandyAreaData) -> void:
	var leaves: Array[CandyAreaData] = []
	root.collect_leaves(leaves)
	for leaf in leaves:
		if not CandyPanels.has_panel(leaf.panel_id):
			leaf.panel_id = CandyPanels.DEFAULT_PANEL
			leaf.panel_state = {}


func _has_top_bar(root: CandyAreaData) -> bool:
	return root != null \
		and not root.is_leaf() \
		and root.first.is_leaf() \
		and root.first.panel_id == "top_bar"


#& Queries

func get_root(window_id: String) -> CandyAreaData:
	return _roots.get(window_id)


func find_area(window_id: String, area_id: int) -> CandyAreaData:
	var root := get_root(window_id)
	if root == null:
		return null
	return root.find_area(area_id)


func get_window_ids() -> Array:
	return _roots.keys()


#* Check whether an Area (leaf or group) can close - every Area inside must be closable:
func can_close_area(window_id: String, area_id: int) -> bool:
	var area := find_area(window_id, area_id)
	if area == null or not area.can_close:
		return false
	var leaves: Array[CandyAreaData] = []
	area.collect_leaves(leaves)
	for leaf in leaves:
		if not leaf.can_close:
			return false
	if _closes_window(window_id, area):
		return window_id != MAIN_WINDOW_ID
	return area.get_parent_area().can_collapse


#* Check whether closing an Area closes the window (it's the workspace under the top bar):
func _closes_window(window_id: String, area: CandyAreaData) -> bool:
	var parent := area.get_parent_area()
	if parent == null:
		return true
	return parent == get_root(window_id) and area == parent.second


#* Check whether a split's menu may restructure it (wrap, swap, rotate):
func can_edit_split(window_id: String, area_id: int) -> bool:
	var area := find_area(window_id, area_id)
	return area != null and not area.is_leaf() and area.can_collapse			#/ One that can't collapse is permanent ([top bar] over [workspace])


#& Edits

#* Add a new Area next to a leaf or a whole group (spanning its edge):
#? new_area_first: left/top, else right/bottom.
func split_area(window_id: String, area_id: int, layout: CandyAreaData.Layout, new_area_first: bool = false) -> CandyAreaData:
	var area := find_area(window_id, area_id)
	if area == null:
		return null
	if area.is_leaf():
		if not area.can_split:
			return null
	elif not can_edit_split(window_id, area_id):
		return null

	#Ł The target's (first) panel type:
	var panel_id = area.first_leaf().panel_id
	if not CandyPanels.is_selectable(panel_id):
		panel_id = CandyPanels.DEFAULT_PANEL
	var new_leaf := CandyAreaData.make_leaf(panel_id)
	var split = area.wrap_with(new_leaf, layout, new_area_first)
	if split.get_parent_area() == null:
		_roots[window_id] = split

	_mark_changed(window_id)
	return new_leaf


#* Add a new Area between a split's sides, showing its first Area's panel type:
func insert_area(window_id: String, split_id: int) -> CandyAreaData:
	if not can_edit_split(window_id, split_id):
		return null
	var split := find_area(window_id, split_id)
	var panel_id := split.first_leaf().panel_id
	if not CandyPanels.is_selectable(panel_id):
		panel_id = CandyPanels.DEFAULT_PANEL
	var new_leaf := CandyAreaData.make_leaf(panel_id)
	split.insert_between(new_leaf)
	_mark_changed(window_id)
	return new_leaf


func swap_split(window_id: String, area_id: int) -> void:
	if not can_edit_split(window_id, area_id):
		return
	find_area(window_id, area_id).swap_children()
	_mark_changed(window_id)


func rotate_split(window_id: String, area_id: int) -> void:
	if not can_edit_split(window_id, area_id):
		return
	find_area(window_id, area_id).toggle_layout()
	_mark_changed(window_id)


func close_area(window_id: String, area_id: int) -> void:
	if not can_close_area(window_id, area_id):
		return
	var area := find_area(window_id, area_id)
	if _closes_window(window_id, area):
		close_window(window_id)
		return

	#Ł The sibling takes the parent's place:
	var parent := area.get_parent_area()
	parent.keep_sizes_without(area)
	var sibling := parent.sibling_of(area)
	var grandparent := parent.get_parent_area()
	if grandparent != null:
		grandparent.replace_child(parent, sibling)
	else:
		_roots[window_id] = sibling
		sibling.set_parent_area(null)

	_mark_changed(window_id)


func set_area_panel(window_id: String, area_id: int, panel_id: String) -> void:
	var area := find_area(window_id, area_id)
	if area == null or not area.is_leaf() or not area.can_change_panel:
		return
	if not CandyPanels.is_selectable(panel_id) or area.panel_id == panel_id:
		return
	area.panel_id = panel_id
	area.panel_state = {}
	_mark_changed(window_id)


#* Set a leaf Area's minimum and maximum size in pixels (0 = none):
#? limits: CandyMinSizeFields.limits_of(), kept in its config.
func set_area_size_limits(window_id: String, area_id: int, limits: Dictionary) -> void:
	var area := find_area(window_id, area_id)
	if area == null or not area.is_leaf():
		return
	var config := area.config.duplicate()
	config.merge(CandyMinSizeFields.limits_of(limits), true)
	area.config = config
	_mark_changed(window_id)


#* Check whether an Area may be replaced by a loaded Area layout:
func can_replace_area(window_id: String, area_id: int) -> bool:
	var area := find_area(window_id, area_id)
	if area == null:
		return false
	#? So the top bar and the window's root stay: a split editable, everything inside closable and changeable.
	if not area.is_leaf() and not can_edit_split(window_id, area_id):
		return false
	var leaves: Array[CandyAreaData] = []
	area.collect_leaves(leaves)
	for leaf in leaves:
		if not leaf.can_close or not leaf.can_change_panel or not leaf.show_header:
			return false
	return true


#* Get an Area and everything inside, with current panel state, as an Area layout:
func area_layout(window_id: String, area_id: int) -> Dictionary:
	var area := find_area(window_id, area_id)
	if area == null:
		return {}
	state_capture_requested.emit()
	return CandyLayoutLibrary.area_layout(area)


#* Replace an Area with a saved Area layout:
func replace_area(window_id: String, area_id: int, layout: Dictionary) -> bool:
	if not can_replace_area(window_id, area_id):
		return false
	var loaded := CandyLayoutLibrary.area_from_layout(layout)
	if loaded == null:
		return false
	#Ł Missing or unpickable panel types (the top bar) get the default panel:
	var leaves: Array[CandyAreaData] = []
	loaded.collect_leaves(leaves)
	for leaf in leaves:
		if not CandyPanels.is_selectable(leaf.panel_id):
			leaf.panel_id = CandyPanels.DEFAULT_PANEL
			leaf.panel_state = {}

	var area := find_area(window_id, area_id)
	var parent := area.get_parent_area()
	if parent == null:
		_roots[window_id] = loaded
	else:
		parent.replace_child(area, loaded)
	_mark_changed(window_id)
	return true


#* Check whether an Area can be dragged onto another of the window (see CandyAreaDrop):
func can_drop_area(window_id: String, source_id: int, target_id: int,
		zone: CandyAreaDrop.Zone, mode: CandyAreaDrop.Mode) -> bool:
	var source := find_area(window_id, source_id)
	var target := find_area(window_id, target_id)
	if not CandyAreaDrop.changes(source, target, zone, mode):
		return false
	if not source.show_header or not target.show_header:			#/ The top bar
		return false
	#Ł What happens to the source:
	if mode == CandyAreaDrop.Mode.COPY:
		if not CandyPanels.is_selectable(source.panel_id):
			return false
	elif not can_close_area(window_id, source_id) or _closes_window(window_id, source):
		return false
	#Ł And to the target:
	if zone != CandyAreaDrop.Zone.CENTER:
		return target.can_split
	if mode == CandyAreaDrop.Mode.SWAP:
		return target.can_close
	return target.can_close and target.can_change_panel


#* Drag an Area onto another of the window (see CandyAreaDrop):
func drop_area(window_id: String, source_id: int, target_id: int,
		zone: CandyAreaDrop.Zone, mode: CandyAreaDrop.Mode) -> bool:
	if not can_drop_area(window_id, source_id, target_id, zone, mode):
		return false
	var source := find_area(window_id, source_id)
	var copy: CandyAreaData = null
	if mode == CandyAreaDrop.Mode.COPY:
		state_capture_requested.emit()			#/ So the copy has the panel's current state
		copy = CandyAreaData.from_dict(source.to_dict())
	_roots[window_id] = CandyAreaDrop.apply(source, find_area(window_id, target_id), zone, mode, copy)
	_mark_changed(window_id)
	return true


func reset_layout() -> void:
	if not CandyProfiles.is_profile_open():
		return
	_apply_default_layout()


func _mark_changed(window_id: String) -> void:
	#? Deferred, so the UI that triggered the change isn't freed mid-callback.
	if _dirty.is_empty():
		_flush_changes.call_deferred()
	_dirty[window_id] = true


func _flush_changes() -> void:
	var ids := _dirty.keys()
	_dirty.clear()
	for window_id in ids:
		if _roots.has(window_id):
			layout_changed.emit(window_id)


#& Windows

#* Open a new OS window, the top bar over one Area, and return its id:
func open_window(panel_id: String = "") -> String:
	if not CandyPanels.is_selectable(panel_id):
		panel_id = CandyPanels.DEFAULT_PANEL
	var window_id := _new_window_id()
	_roots[window_id] = _with_top_bar(CandyAreaData.make_leaf(panel_id))
	_create_window(window_id, Rect2i())
	return window_id


#* Release the focus in every window, so the field being typed in commits:
func release_focus() -> void:
	get_viewport().gui_release_focus()
	for window_id in _windows:
		_windows[window_id].gui_release_focus()


#* Commit the field being typed in, in every window, keeping the caret in it:
#? For reading the dialogue while the user may be typing (saving, exporting, testing).
func commit_typing() -> void:
	var viewports: Array[Viewport] = [get_viewport()]
	for window_id in _windows:
		viewports.append(_windows[window_id])
	for viewport in viewports:
		var focused := viewport.gui_get_focus_owner()
		if focused == null:
			continue
		viewport.gui_release_focus()
		if is_instance_valid(focused) and not focused.is_queued_for_deletion() and focused.is_visible_in_tree():			#/ Not if the commit removed it (line UI rebuilt)
			focused.grab_focus()


func close_window(window_id: String) -> void:
	if window_id == MAIN_WINDOW_ID:
		return
	if _windows.has(window_id):
		_windows[window_id].queue_free()
	_windows.erase(window_id)
	_roots.erase(window_id)


func _new_window_id() -> String:
	var window_id := ""
	while window_id == "" or _roots.has(window_id):
		_window_counter += 1
		window_id = "window_%d" % _window_counter
	return window_id


func _create_window(window_id: String, rect: Rect2i) -> void:
	var win := Window.new()
	CandyLocale.claim(win)
	win.title = "Candy Dialogue Creator"
	win.min_size = Vector2i(320, 240)
	if window_theme != null:
		win.theme = window_theme

	#Ł Always positioned here:
	#? Centered by Godot, `position` stays (0, 0) until moved, and the top bar's menus pop up in the screen's corner.
	win.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	if rect.has_area() and _is_rect_on_a_screen(rect):
		win.position = rect.position
		win.size = rect.size
	else:
		#Ł Middle of the main window's screen:
		var screen := DisplayServer.window_get_current_screen(DisplayServer.MAIN_WINDOW_ID)
		var area := DisplayServer.screen_get_usable_rect(screen)
		win.size = DEFAULT_WINDOW_SIZE.min(area.size).max(win.min_size)
		@warning_ignore("integer_division")
		win.position = area.position + (area.size - win.size) / 2

	var host := CandyAreaHost.new()
	host.window_id = window_id
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win.add_child(host)

	win.close_requested.connect(close_window.bind(window_id))
	_windows[window_id] = win
	add_child(win)


func _is_rect_on_a_screen(rect: Rect2i) -> bool:
	for screen in DisplayServer.get_screen_count():
		var screen_rect := Rect2i(DisplayServer.screen_get_position(screen), DisplayServer.screen_get_size(screen))
		if screen_rect.intersects(rect):
			return true
	return false


#& Save / load

func save_layout() -> bool:
	if not CandyProfiles.is_profile_open() or _roots.is_empty():
		return false
	CandyProfiles.set_setting(SETTINGS_KEY, layout_data())
	return true


#* Get every window's layout, with current panel state:
#? As saved in the profile and in named window layouts (CandyLayoutLibrary).
func layout_data() -> Dictionary:
	state_capture_requested.emit()

	var windows: Array = []
	for window_id in _roots:
		var entry := {"id": window_id, "root": _roots[window_id].to_dict()}
		if _windows.has(window_id):
			var win: Window = _windows[window_id]
			entry["rect"] = [win.position.x, win.position.y, win.size.x, win.size.y]
		windows.append(entry)
	return {"version": SAVE_VERSION, "windows": windows}


#* Rebuild the layout stored in the open profile:
func load_layout() -> bool:
	if not CandyProfiles.is_profile_open():
		return false
	return apply_layout_data(CandyProfiles.get_setting(SETTINGS_KEY, {}))			#/ False: nothing usable saved, the caller falls back to the default


#* Replace every window's layout with data, as layout_data() gives it:
func apply_layout_data(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) != SAVE_VERSION:
		return false

	var new_roots := {}
	var rects := {}
	var windows = data.get("windows", [])
	if typeof(windows) != TYPE_ARRAY:
		return false
	for entry in windows:
		if typeof(entry) != TYPE_DICTIONARY or typeof(entry.get("root")) != TYPE_DICTIONARY:
			continue
		var root := CandyAreaData.from_dict(entry["root"])
		var window_id := str(entry.get("id", ""))
		if root == null or window_id == "" or new_roots.has(window_id):
			continue
		_replace_missing_panels(root)
		if window_id != MAIN_WINDOW_ID and not _has_top_bar(root):
			#% An extra window without a top bar gets one:
			root = _with_top_bar(root)
		new_roots[window_id] = root
		var r = entry.get("rect")
		if typeof(r) == TYPE_ARRAY and r.size() == 4:
			rects[window_id] = Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))

	if not _has_top_bar(new_roots.get(MAIN_WINDOW_ID)):
		return false
	for window_id in new_roots:
		_apply_system_locks(new_roots[window_id])

	for window_id in _windows.keys():
		close_window(window_id)
	_roots = new_roots
	for window_id in _roots:
		if window_id != MAIN_WINDOW_ID:
			_create_window.call_deferred(window_id, rects.get(window_id, Rect2i()))
	_mark_changed(MAIN_WINDOW_ID)
	return true