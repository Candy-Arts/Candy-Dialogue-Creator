#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDialogueEditorPanel
extends CandyPanel

var _header: Label
var _breadcrumb: Label
var _edit_toggle: Button
var _filter_bar: CandyFilterBar
#^ The host's tabs, above the separator:
var _tabs_box: Control
var _host: CandyLineLayoutHost
var _empty_label: Label

#^ The line layouts drawn - its own, or the outer Editor's:
var line_layouts := CandyLineLayoutSet.new()
#^ Whether line_layouts belong to another Editor (use_layouts()):
var _shared_layouts := false

var _bound_type: String = ""
var _reference: String = CandyDialogue.DEFAULT_REFERENCE
var _tabs: Dictionary = {}          #/ Line type -> selected tab index
var _editing: bool = false
var _pending_state: Dictionary = {}
#^ Set by show_fixed() - the path shown instead of the active line, and the empty text:
var _fixed := false
var _fixed_path: Array = []
var _empty_text := CandyLocale.t("Select a line in the Dialogue Navigator.")
var _shown_path: Array = []


func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var header_row := HBoxContainer.new()
	root.add_child(header_row)

	#Ł Breadcrumb beside the title, both bottom-aligned so their text lines up:
	var titles := HBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_row.add_child(titles)

	_header = Label.new()
	_header.theme_type_variation = CandyThemeDefaults.EDITOR_TITLE
	_header.size_flags_vertical = Control.SIZE_FILL
	_header.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	titles.add_child(_header)

	_breadcrumb = Label.new()
	_breadcrumb.theme_type_variation = CandyThemeDefaults.BREADCRUMB
	_breadcrumb.clip_text = true
	_breadcrumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_breadcrumb.size_flags_vertical = Control.SIZE_FILL
	_breadcrumb.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	titles.add_child(_breadcrumb)

	_edit_toggle = Button.new()
	_edit_toggle.text = CandyLocale.t("Edit Layout")
	_edit_toggle.toggle_mode = true
	_edit_toggle.focus_mode = Control.FOCUS_NONE
	_edit_toggle.tooltip_text = CandyLocale.t("Split areas, choose widgets and manage tabs for this line type")
	_edit_toggle.toggled.connect(_on_edit_toggled)
	header_row.add_child(_edit_toggle)

	var separator := HSeparator.new()
	root.add_child(separator)

	_empty_label = Label.new()
	_empty_label.text = _empty_text
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_empty_label)

	if not _shared_layouts:
		line_layouts.stored.connect(_on_layouts_stored)

	_host = CandyLineLayoutHost.new()
	_host.layouts = line_layouts
	_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_host.tab_selected.connect(_on_tab_selected)
	_host.options_requested.connect(open_panel_settings)
	root.add_child(_host)

	#Ł Tabs above the separator; the filter bar on top of the host:
	_tabs_box = _host.take_tabs()
	root.add_child(_tabs_box)
	root.move_child(_tabs_box, separator.get_index())

	_filter_bar = CandyFilterBar.new()
	_filter_bar.layouts = line_layouts
	_filter_bar.filters_applied.connect(_apply_filters)
	_host.add_bar(_filter_bar)

	CandyDialogue.active_changed.connect(_on_active_changed)
	CandyDialogue.dialogue_changed.connect(refresh)
	CandyDialogue.line_changed.connect(_on_line_changed)
	#? Media player types come from the project's folders.
	CandyResources.resources_scanned.connect(refresh)
	CandyShortcuts.triggered.connect(_on_shortcut)
	refresh()


#* Whether this Editor follows the view used last (never when embedded):
func is_current() -> bool:
	return not _fixed and _reference == CandyDialogue.current_reference and is_visible_in_tree()


#* Previous Tab / Next Tab shortcuts:
func _on_shortcut(action_id: String, _window: Window) -> void:
	if _bound_type == "" or not is_current():
		return
	var step := 0
	if action_id == "editor_next_tab":
		step = 1
	elif action_id == "editor_previous_tab":
		step = -1
	var count := line_layouts.tab_count(_bound_type)
	if step == 0 or count < 2:
		return
	_host.select_tab(wrapi(_host.tab_index + step, 0, count))


#* Draw with another Editor's line layouts:
#! Call before the panel enters the tree.
func use_layouts(layouts: CandyLineLayoutSet) -> void:
	line_layouts = layouts
	_shared_layouts = true


#* Save the window layout (it holds the panel's line layouts) into the profile:
func _on_layouts_stored() -> void:
	CandyLayout.save_layout()


#* Edit line_path whatever the selection (an empty path shows empty_text):
func show_fixed(line_path: Array, empty_text: String) -> void:
	_fixed = true
	_fixed_path = line_path.duplicate()
	_empty_text = empty_text
	if _empty_label != null:
		_empty_label.text = empty_text
	refresh()


func refresh() -> void:
	if _host == null:
		return

	var path := CandyDialogue.active_path_of(_reference)
	if _fixed:
		path = _fixed_path
	_shown_path = path.duplicate()
	if not CandyDialogue.is_line_path(path) or not CandyDialogue.exists(path):
		_show_empty()
		return

	var line := CandyDialogue.line_at(path)
	var type := CandyDialogue.line_type(line)
	if type == "":
		_show_empty()
		return

	_empty_label.visible = false
	_host.visible = true
	_tabs_box.visible = true
	_edit_toggle.visible = true
	_header.text = CandyLocale.command_title(CandySchemas.get_title(type))
	_breadcrumb.text = "%s  ›  %s  ›  %s" % [path[0], path[1], CandyLocale.t("line %d") % int(path[2])]
	#Ł Nested command - add the commands on the way to it:
	for step in path.slice(3):
		if CandySchemas.has_schema(str(step)):
			_breadcrumb.text += "  ›  %s" % CandyLocale.command_title(CandySchemas.get_title(str(step)))

	_bound_type = type
	_host.show_line(type, path, int(_tabs.get(type, 0)))
	#? Read the tab back - the host may have clamped it.
	_filter_bar.bind(type, _host.tab_index)


#* Refresh when its own view's active line changes (not when fixed):
func _on_active_changed(changed_reference: String) -> void:
	if not _fixed and changed_reference == _reference:
		refresh()


func _on_line_changed(path: Array) -> void:
	if path == _shown_path:
		refresh()


func _apply_filters() -> void:
	if _bound_type != "":
		_host.bind_line()


func _on_edit_toggled(pressed: bool) -> void:
	_editing = pressed
	_host.set_editing(pressed)


#* Each tab has its own filters:
func _on_tab_selected(index: int) -> void:
	if _bound_type != "":
		_tabs[_bound_type] = index
		_filter_bar.bind(_bound_type, index)


func _show_empty() -> void:
	_bound_type = ""
	_header.text = CandyLocale.t("Dialogue Editor")
	if _fixed:
		_header.text = " "
	_breadcrumb.text = " "
	_empty_label.visible = true
	_host.visible = false
	_tabs_box.visible = false
	_edit_toggle.visible = false


#& Options

#* Options - the reference, and the Area's minimum size:
func has_settings() -> bool:
	return true


func open_settings() -> void:
	CandyReferenceDialog.open_for_panel(self,
		CandyLocale.t("The line this Editor edits: the one clicked last in the Dialogue Navigators with the same reference."),
		_reference, _set_reference)


func _set_reference(reference: String) -> void:
	reference = CandyDialogue.clean_reference(reference)
	if reference == _reference:
		return
	_reference = reference
	refresh()


#& Panel state

func get_state() -> Dictionary:
	if _host == null:
		return _pending_state
	return {"tabs": _tabs.duplicate(), "editing": _editing, "line_layouts": line_layouts.get_data(),
		"reference": _reference}


func set_state(state: Dictionary) -> void:
	_pending_state = state
	var tabs = state.get("tabs", {})
	if tabs is Dictionary:
		_tabs = tabs.duplicate()
	else:
		_tabs = {}
	_editing = bool(state.get("editing", false))
	_reference = CandyDialogue.clean_reference(str(state.get("reference", CandyDialogue.DEFAULT_REFERENCE)))
	if not _shared_layouts:
		line_layouts.set_data(state.get("line_layouts", {}))
	if _host != null:
		_edit_toggle.set_pressed_no_signal(_editing)
		_host.set_editing(_editing)
		refresh()