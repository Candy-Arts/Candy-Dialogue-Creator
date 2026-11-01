#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyTabsPanel
extends CandyPanel

enum ContextId { PANEL_SETTINGS, RENAME_TAB, RESET_TAB_NAME, DELETE_TAB, SAVE_LAYOUT,
	#/ The tab's panel's own actions use this id and up:
	PANEL_ACTION_FIRST = 100 }
const META_PANEL_ID := "candy_panel_id"
#^ A renamed tab's name, kept on the panel so it follows a drag to another Tab Panel:
const META_CUSTOM_TITLE := "candy_custom_title"
#^ The strip menu's Options id, after the panels' ids:
const STRIP_OPTIONS_ID := 10000
#^ Tab sides, as saved and as the Options name them:
const TAB_SIDES: PackedStringArray = ["top", "left", "right"]
const TAB_SIDE_LABELS: PackedStringArray = ["Top", "Left", "Right"]	#/ translatable

#^ Shared by every Tab Panel, so tabs drag between them (-1 = reorder within each only):
const REARRANGE_GROUP := 1

var _tabs: TabContainer
var _strip: CandyTabStrip
var _tab_side := "top"
var _add_popup: PopupMenu
#^ The strip's empty space menu - Options, then the panels to add:
var _strip_popup: PopupMenu
#^ The tab menu's Add Tab submenu, listing like _add_popup:
var _add_submenu: PopupMenu
var _context_popup: PopupMenu
var _empty_state: Control
var _add_ids: PackedStringArray = []
var _context_tab: int = -1
var _context_actions: PackedStringArray = []
#^ Save / Load Layout for the right-clicked tab's panel:
var _layout_menu: CandyLayoutMenu
var _pending_state: Dictionary = {}
var _name_prompt: CandyNamePrompt
var _settings_dialog: AcceptDialog
var _side_button: OptionButton
var _min_size_fields: CandyMinSizeFields


func _ready() -> void:
	_tabs = TabContainer.new()
	_tabs.tabs_visible = false
	add_child(_tabs)
	#? Pass on the current tab's minimum size, for the Area.
	_tabs.minimum_size_changed.connect(update_minimum_size)

	_strip = CandyTabStrip.new()
	_strip.container = _tabs
	_strip.rearrange_group = REARRANGE_GROUP
	#? The strip's right-click is its own, not the Area's.
	_strip.set_meta(CandyPopups.OWN_CONTEXT_MENU, true)
	_strip.tab_clicked.connect(func(index: int): _tabs.current_tab = index)
	_strip.tab_double_clicked.connect(_prompt_rename)
	_strip.context_requested.connect(_on_strip_context_requested)
	_strip.tab_dropped.connect(_on_tab_dropped)
	_strip.minimum_size_changed.connect(_apply_tab_side)
	add_child(_strip)

	#Ł Add Tab menu:
	#! Parented to the panel: a non-tab child of the TabContainer shifts child indexes off tab indexes.
	#? Headed, to say the panel picked is added, not swapped in.
	_add_popup = PopupMenu.new()
	_add_popup.about_to_popup.connect(_fill_add_menu.bind(_add_popup, CandyLocale.t("Add Tab")))
	_add_popup.id_pressed.connect(_on_add_selected)
	add_child(_add_popup)
	_strip_popup = PopupMenu.new()
	_strip_popup.about_to_popup.connect(_fill_strip_menu)
	_strip_popup.id_pressed.connect(_on_strip_menu_selected)
	add_child(_strip_popup)

	#Ł Tab right-click menu (rebuilt for each tab's panel):
	_context_popup = PopupMenu.new()
	_context_popup.id_pressed.connect(_on_context_selected)
	add_child(_context_popup)
	_add_submenu = PopupMenu.new()
	_add_submenu.id_pressed.connect(_on_add_selected)
	_context_popup.add_child(_add_submenu)

	_name_prompt = CandyNamePrompt.new()
	add_child(_name_prompt)

	_tabs.child_order_changed.connect(_update_empty_state)

	_build_empty_state()
	_build_settings_dialog()

	if _pending_state.is_empty():
		add_panel(CandyPanels.DEFAULT_PANEL)
	else:
		_restore(_pending_state)
	_apply_tab_side()
	_update_empty_state()


#& Tabs

#* Add a panel as a new, selected tab, and return it:
func add_panel(panel_id: String, state: Dictionary = {}, at_index: int = -1, custom_title: String = "") -> Control:
	var child := CandyPanels.instantiate(panel_id)
	child.set_meta(META_PANEL_ID, panel_id)
	if custom_title != "":
		child.set_meta(META_CUSTOM_TITLE, custom_title)
	if child is CandyPanel:
		child.area_id = area_id
		child.window_id = window_id
		if not state.is_empty():
			child.set_state(state)
	_insert_tab(child, at_index)
	return child


#* Insert a panel (new or from another Tab Panel) as a selected tab at at_index (-1 = last):
func _insert_tab(child: Control, at_index: int) -> void:
	if child is CandyPanel:
		child.area_id = area_id
		child.window_id = window_id
	_tabs.add_child(child)
	if at_index >= 0 and at_index < _tabs.get_tab_count() - 1:
		_tabs.move_child(child, at_index)

	#? Child index can differ from tab index.
	var index := _tabs.get_tab_idx_from_control(child)
	#? The title is stored on the child, so it follows reordering.
	_tabs.set_tab_title(index, _title_for(child))
	_tabs.current_tab = index
	_update_empty_state()
	_strip.refresh()


#* Remove a tab without freeing its panel, for another Tab Panel to take:
func take_tab(index: int) -> Control:
	if index < 0 or index >= _tabs.get_tab_count():
		return null
	var child := _tabs.get_tab_control(index)
	_tabs.remove_child(child)
	_update_empty_state()
	_strip.refresh()
	return child


#* Move a tab dropped on the strip, from this Tab Panel or another:
func _on_tab_dropped(from: CandyTabStrip, from_index: int, to_index: int) -> void:
	if from == _strip:
		if from_index < 0 or from_index >= _tabs.get_tab_count():
			return
		#? to_index counts the moved tab.
		if from_index < to_index:
			to_index -= 1
		var moved := _tabs.get_tab_control(from_index)
		_tabs.move_child(moved, to_index)
		_tabs.current_tab = _tabs.get_tab_idx_from_control(moved)
		_strip.refresh()
		return
	var source := from.get_parent() as CandyTabsPanel
	if source == null:
		return
	var child := source.take_tab(from_index)
	if child != null:
		_insert_tab(child, to_index)


#* Rename a tab ("" goes back to the panel's name):
func rename_tab(index: int, custom_title: String) -> void:
	if index < 0 or index >= _tabs.get_tab_count():
		return
	var child := _tabs.get_tab_control(index)
	if custom_title.strip_edges() == "":
		child.remove_meta(META_CUSTOM_TITLE)
	else:
		child.set_meta(META_CUSTOM_TITLE, custom_title)
	_tabs.set_tab_title(index, _title_for(child))
	_strip.refresh()


func _title_for(child: Control) -> String:
	var custom_title := str(child.get_meta(META_CUSTOM_TITLE, ""))
	if custom_title != "":
		return custom_title
	return CandyPanels.get_title(str(child.get_meta(META_PANEL_ID, "")))


func _has_custom_title(index: int) -> bool:
	if index < 0 or index >= _tabs.get_tab_count():
		return false
	return _tabs.get_tab_control(index).has_meta(META_CUSTOM_TITLE)


func _prompt_rename(index: int) -> void:
	if index < 0 or index >= _tabs.get_tab_count():
		return
	#? Keep the panel, not the index - tabs may move while the prompt is open.
	var child := _tabs.get_tab_control(index)
	_name_prompt.prompt(CandyLocale.t("Rename Tab"), _tabs.get_tab_title(index),
		func(_new_name: String) -> String:
			return "",  #/ Any name goes, even a taken one
		func(new_name: String) -> void:
			if is_instance_valid(child) and child.get_parent() == _tabs:
				rename_tab(_tabs.get_tab_idx_from_control(child), new_name))


func remove_tab(index: int) -> void:
	if index < 0 or index >= _tabs.get_tab_count():
		return
	var child := _tabs.get_tab_control(index)
	_tabs.remove_child(child)
	child.queue_free()
	_update_empty_state()
	_strip.refresh()


func get_tab_count() -> int:
	if _tabs == null:
		return 0
	return _tabs.get_tab_count()


func _clear_tabs() -> void:
	for i in range(_tabs.get_tab_count() - 1, -1, -1):
		var child := _tabs.get_tab_control(i)
		_tabs.remove_child(child)
		child.queue_free()


#& Menus

#* List the panels a tab can hold in menu, under heading if any:
func _fill_add_menu(menu: PopupMenu, heading: String = "") -> void:
	menu.clear()
	_add_panel_items(menu, heading)


func _add_panel_items(menu: PopupMenu, heading: String) -> void:
	if heading != "":
		menu.add_separator(heading)
	_add_ids = CandyPanels.get_selectable_ids()
	for i in _add_ids.size():
		menu.add_item(CandyPanels.get_title(_add_ids[i]), i)


func _on_add_selected(id: int) -> void:
	if id >= 0 and id < _add_ids.size():
		add_panel(_add_ids[id])


func _fill_strip_menu() -> void:
	_strip_popup.clear()
	_strip_popup.add_item(CandyLocale.t("Options"), STRIP_OPTIONS_ID)
	_add_panel_items(_strip_popup, CandyLocale.t("Add Tab"))


func _on_strip_menu_selected(id: int) -> void:
	if id == STRIP_OPTIONS_ID:
		open_panel_settings()
	else:
		_on_add_selected(id)


func _context_panel() -> CandyPanel:
	if _context_tab < 0 or _context_tab >= _tabs.get_tab_count():
		return null
	return _tabs.get_tab_control(_context_tab) as CandyPanel


func _rebuild_context_popup() -> void:
	_context_popup.clear()
	_context_actions = PackedStringArray()
	var child := _context_panel()
	var has_panel_settings := child != null and child.can_open_panel_settings()
	if child != null:
		_context_actions = child.get_area_actions()

	_context_popup.add_item(CandyLocale.t("Options"), ContextId.PANEL_SETTINGS)
	_context_popup.set_item_disabled(_context_popup.get_item_index(ContextId.PANEL_SETTINGS),
		not has_panel_settings)
	for i in _context_actions.size():
		_context_popup.add_item(_context_actions[i], ContextId.PANEL_ACTION_FIRST + i)
	if child != null:
		if _layout_menu == null:
			_layout_menu = CandyLayoutMenu.new()
			add_child(_layout_menu)
		var panel_id := str(child.get_meta(META_PANEL_ID, ""))
		_layout_menu.setup(CandyLayoutLibrary.PANELS, panel_id, _capture_layout, _apply_layout)
		_layout_menu.add_items(_context_popup, ContextId.SAVE_LAYOUT)
	_context_popup.add_separator()
	_fill_add_menu(_add_submenu)
	_context_popup.add_submenu_node_item(CandyLocale.t("Add Tab"), _add_submenu)
	_context_popup.add_item(CandyLocale.t("Rename Tab..."), ContextId.RENAME_TAB)
	_context_popup.add_item(CandyLocale.t("Reset Tab Name"), ContextId.RESET_TAB_NAME)
	_context_popup.set_item_disabled(_context_popup.get_item_index(ContextId.RESET_TAB_NAME),
		not _has_custom_title(_context_tab))
	_context_popup.add_separator()
	_context_popup.add_item(CandyLocale.t("Delete Tab"), ContextId.DELETE_TAB)


func _on_context_selected(id: int) -> void:
	var child := _context_panel()
	if _layout_menu != null and _layout_menu.handle_id(id):
		return
	match id:
		ContextId.PANEL_SETTINGS:
			if child != null:
				child.open_panel_settings()
		ContextId.RENAME_TAB:
			_prompt_rename(_context_tab)
		ContextId.RESET_TAB_NAME:
			rename_tab(_context_tab, "")
		ContextId.DELETE_TAB:
			remove_tab(_context_tab)
		_:
			var index := id - ContextId.PANEL_ACTION_FIRST
			if child != null and index >= 0 and index < _context_actions.size():
				child.run_area_action(_context_actions[index])


#* Return the right-clicked tab's panel's state, for its saved layouts:
func _capture_layout() -> Dictionary:
	var child := _context_panel()
	if child == null:
		return {}
	return child.get_state()


func _apply_layout(layout: Dictionary) -> void:
	var child := _context_panel()
	if child != null:
		child.set_state(layout)


#* Open the tab's menu on a right-click inside its panel:
func _input(event: InputEvent) -> void:
	if _tabs == null:
		return
	var current := _tabs.get_current_tab_control()
	if current == null or not CandyPopups.is_context_click(event, current):
		return
	_context_tab = _tabs.current_tab
	_rebuild_context_popup()
	CandyPopups.popup_at_point(_context_popup,
		Vector2i(current.get_screen_position() + current.get_local_mouse_position()), self)
	get_viewport().set_input_as_handled()	#/ Before the Area around this Tab Panel opens its own


func _on_strip_context_requested(index: int, screen_position: Vector2i) -> void:
	if index >= 0:
		_context_tab = index
		_rebuild_context_popup()
		CandyPopups.popup_at_point(_context_popup, screen_position, self)
	else:
		CandyPopups.popup_at_point(_strip_popup, screen_position, self)


#& Empty state

func _build_empty_state() -> void:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(box)

	var label := Label.new()
	label.text = CandyLocale.t("No tabs")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)

	var button := Button.new()
	button.text = CandyLocale.t("Add Panel")
	button.pressed.connect(_on_empty_add_pressed.bind(button))
	row.add_child(button)

	_empty_state = box


func _on_empty_add_pressed(button: Button) -> void:
	CandyPopups.popup_at(_add_popup, Rect2i(Vector2i(button.get_screen_position()), Vector2i(button.size)), self)


func _update_empty_state() -> void:
	if _empty_state != null and _tabs != null:
		_empty_state.visible = _tabs.get_tab_count() == 0


#& Tab side and settings

#* Put the strip on its side, and the panels beside it:
func _apply_tab_side() -> void:
	if _strip == null:
		return
	var side: Side = SIDE_TOP
	match _tab_side:
		"left":
			side = SIDE_LEFT
		"right":
			side = SIDE_RIGHT
	if _strip.side != side:
		_strip.side = side
	var strip_size := _strip.get_combined_minimum_size()
	#? Anchors and offsets, in Side order (left, top, right, bottom).
	match side:
		SIDE_LEFT:
			_place(_strip, [0, 0, 0, 1], [0, 0, strip_size.x, 0])
			_place(_tabs, [0, 0, 1, 1], [strip_size.x, 0, 0, 0])
		SIDE_RIGHT:
			_place(_strip, [1, 0, 1, 1], [-strip_size.x, 0, 0, 0])
			_place(_tabs, [0, 0, 1, 1], [0, 0, -strip_size.x, 0])
		_:
			_place(_strip, [0, 0, 1, 0], [0, 0, 0, strip_size.y])
			_place(_tabs, [0, 0, 1, 1], [0, strip_size.y, 0, 0])
	update_minimum_size()


static func _place(control: Control, anchors: Array, offsets: Array) -> void:
	#? Anchors push their opposite along (set_anchor_and_offset() doesn't: a left
	#? anchor of 1 would be held at the right anchor's old 0).
	for edge in 4:
		control.set_anchor(edge, float(anchors[edge]), false, true)
	for edge in 4:
		control.set_offset(edge, float(offsets[edge]))


func _get_minimum_size() -> Vector2:
	if _tabs == null:
		return Vector2.ZERO
	var content := _tabs.get_combined_minimum_size()
	var strip := _strip.get_combined_minimum_size()
	if _strip.side == SIDE_TOP:
		return Vector2(maxf(content.x, strip.x), content.y + strip.y)
	return Vector2(content.x + strip.x, maxf(content.y, strip.y))


func _build_settings_dialog() -> void:
	_settings_dialog = AcceptDialog.new()
	_settings_dialog.title = CandyLocale.t("Options")
	_settings_dialog.ok_button_text = CandyLocale.t("Close")
	add_child(_settings_dialog)

	var box := VBoxContainer.new()
	_settings_dialog.add_child(box)

	var side_row := HBoxContainer.new()
	box.add_child(side_row)
	var side_label := Label.new()
	side_label.text = CandyLocale.t("Tabs")
	side_label.tooltip_text = CandyLocale.t("Where the tabs are. On the left or right, their names are written sideways.")
	side_label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	side_row.add_child(side_label)
	_side_button = OptionButton.new()
	_side_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side_button.tooltip_text = side_label.tooltip_text
	for label in TAB_SIDE_LABELS:
		_side_button.add_item(CandyLocale.t(label))
	CandyPopups.attach_button_popup(_side_button)
	_side_button.item_selected.connect(func(index: int):
		_tab_side = TAB_SIDES[index]
		_apply_tab_side())
	side_row.add_child(_side_button)

	_min_size_fields = CandyMinSizeFields.new()
	box.add_child(_min_size_fields)

	_settings_dialog.visibility_changed.connect(func():
		if not _settings_dialog.visible:
			set_area_size_limits(_min_size_fields.get_limits()))


#* Whether this panel has settings (always, for the tab side):
func has_settings() -> bool:
	return true


func open_settings() -> void:
	_side_button.select(maxi(TAB_SIDES.find(_tab_side), 0))
	_min_size_fields.visible = fills_area
	_min_size_fields.set_limits(area_size_limits())
	_settings_dialog.reset_size()
	_settings_dialog.popup_centered()


#& State

func get_state() -> Dictionary:
	if _tabs == null:
		return _pending_state
	var tabs: Array = []
	for i in _tabs.get_tab_count():
		var child := _tabs.get_tab_control(i)
		var entry := {"panel": str(child.get_meta(META_PANEL_ID, ""))}
		if child.has_meta(META_CUSTOM_TITLE):
			entry["title"] = str(child.get_meta(META_CUSTOM_TITLE))
		if child is CandyPanel:
			entry["state"] = child.get_state()
		tabs.append(entry)
	return {"tabs": tabs, "current": _tabs.current_tab, "tab_side": _tab_side}


func set_state(state: Dictionary) -> void:
	_pending_state = state
	if _tabs != null:
		_restore(state)


func _restore(state: Dictionary) -> void:
	_tab_side = str(state.get("tab_side", "top"))
	if not TAB_SIDES.has(_tab_side):
		_tab_side = "top"
	_apply_tab_side()
	_clear_tabs()
	var tabs = state.get("tabs", [])
	if typeof(tabs) != TYPE_ARRAY:
		tabs = []
	for entry in tabs:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var panel_id := str(entry.get("panel", ""))
		if not CandyPanels.has_panel(panel_id):
			continue  #/ Empty, or a panel type that no longer exists
		var child_state = entry.get("state", {})
		if typeof(child_state) != TYPE_DICTIONARY:
			child_state = {}
		add_panel(panel_id, child_state, -1, str(entry.get("title", "")))
	var current := int(state.get("current", 0))
	if current >= 0 and current < _tabs.get_tab_count():
		_tabs.current_tab = current
	_update_empty_state()
	_strip.refresh()