#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyNavigatorPanel
extends CandyPanel

#^ Text zoom steps:
#? The state keeps the index: 100% (index 2) is the default.
const TEXT_SCALES := [0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0]
#^ Font sizes per kind, multiplied by the zoom:
const BASE_FONT_SIZES := {
	CandyDialogueModel.Kind.CONVERSATION: 16,
	CandyDialogueModel.Kind.BLOCK: 14,
	CandyDialogueModel.Kind.LINE: 12,
}

enum MenuId { RENAME, CUT, COPY, PASTE, DUPLICATE, DELETE, PANEL_SETTINGS, TEST_HERE }
#^ Menu items that do a shortcut's action, which show its keys:
const MENU_SHORTCUTS := {
	MenuId.TEST_HERE: "nav_test_here", MenuId.RENAME: "nav_rename", MenuId.CUT: "nav_cut",
	MenuId.COPY: "nav_copy", MenuId.PASTE: "nav_paste", MenuId.DUPLICATE: "nav_duplicate",
	MenuId.DELETE: "nav_delete",
}

#^ What the Navigator lists, in content button order, with labels and tooltips:
const CONTENTS := ["dialogue", "presets", "all"]
const CONTENT_LABELS := {"dialogue": "Dialogue", "presets": "Presets", "all": "All"}	#/ translatable: navigator content
const CONTENT_TOOLTIPS := {
	"dialogue": "Dialogue: the dialogue's conversations. Click to show the user and profile presets.",	#/ translatable
	"presets": "Presets: the user and profile presets. Click to show the presets and the dialogue.",	#/ translatable
	"all": "All: the user and profile presets, then the dialogue's conversations. Click to show the dialogue alone.",	#/ translatable
}

#^ The current view's dot: diameter, outline width, and its room in the toolbar:
const DOT_SIZE := 10.0
const DOT_RING_WIDTH := 1.5
const DOT_ROOM := 16.0

var _mode: int = CandyDialogue.DisplayMode.FULL
var _reference: String = CandyDialogue.DEFAULT_REFERENCE
var _content: String = "dialogue"
var _scale_index: int = 2
var _folded: Dictionary = {}

var _current_dot: Control
var _mode_button: OptionButton
var _content_button: Button
var _scale_label: Label
var _scroll: ScrollContainer
var _list: CandyNavigatorList
var _context_menu: PopupMenu
#^ The row the context menu was opened on ([] for none), for Test Here:
var _context_path: Array = []
var _name_prompt: CandyNamePrompt
var _pending_state: Dictionary = {}


func _ready() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.add_child(_build_toolbar())

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)

	_list = CandyNavigatorList.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.reference = _reference
	_list.scroll = _scroll
	_list.fold_toggled.connect(_on_fold_toggled)
	_list.context_menu_requested.connect(_on_context_menu_requested)
	#? Its right-click menu is the rows' (with Options), not the Area's.
	_list.set_meta(CandyPopups.OWN_CONTEXT_MENU, true)
	_list.gui_input.connect(_on_list_input)
	_scroll.add_child(_list)

	_context_menu = PopupMenu.new()
	_context_menu.add_item(CandyLocale.t("Test Here"), MenuId.TEST_HERE)
	_context_menu.set_item_tooltip(_context_menu.get_item_index(MenuId.TEST_HERE),
		CandyLocale.t("Export the dialogue and test it in the Godot editor from this line (a block or conversation: its first line)."))
	_context_menu.add_separator()
	_context_menu.add_item(CandyLocale.t("Rename"), MenuId.RENAME)
	_context_menu.add_separator()
	_context_menu.add_item(CandyLocale.t("Cut"), MenuId.CUT)
	_context_menu.add_item(CandyLocale.t("Copy"), MenuId.COPY)
	_context_menu.add_item(CandyLocale.t("Paste"), MenuId.PASTE)
	_context_menu.add_separator()
	_context_menu.add_item(CandyLocale.t("Duplicate"), MenuId.DUPLICATE)
	_context_menu.add_item(CandyLocale.t("Delete"), MenuId.DELETE)
	_context_menu.add_separator()
	_context_menu.add_item(CandyLocale.t("Options"), MenuId.PANEL_SETTINGS)
	_context_menu.id_pressed.connect(_on_context_menu_id)
	add_child(_context_menu)

	_name_prompt = CandyNamePrompt.new()
	add_child(_name_prompt)

	CandyDialogue.dialogue_changed.connect(refresh)
	CandyDialogue.selection_changed.connect(_on_selection_changed)
	#? The active line shows as "selected", other selected lines "also selected".
	CandyDialogue.active_changed.connect(_on_selection_changed)
	CandyDialogue.line_changed.connect(_on_line_changed)
	CandyDialogue.current_reference_changed.connect(func(_current: String): _update_current_dot())
	CandyProfiles.settings_changed.connect(_on_setting_changed)

	if not _pending_state.is_empty():
		_apply_state(_pending_state)
	refresh()
	_update_current_dot()


func _build_toolbar() -> Control:
	var bar := HBoxContainer.new()

	_current_dot = Control.new()
	_current_dot.custom_minimum_size = Vector2(DOT_ROOM, DOT_ROOM)
	_current_dot.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	_current_dot.draw.connect(_draw_current_dot)
	bar.add_child(_current_dot)

	_mode_button = OptionButton.new()
	_mode_button.focus_mode = Control.FOCUS_NONE
	_mode_button.tooltip_text = CandyLocale.t("What each line shows")
	_mode_button.add_item(CandyLocale.t("Full"), CandyDialogue.DisplayMode.FULL)
	_mode_button.add_item(CandyLocale.t("Short"), CandyDialogue.DisplayMode.SHORT)
	_mode_button.add_item(CandyLocale.t("Meta"), CandyDialogue.DisplayMode.META)
	_mode_button.add_item(CandyLocale.t("Custom"), CandyDialogue.DisplayMode.CUSTOM)
	_mode_button.set_item_tooltip(_mode_button.get_item_index(CandyDialogue.DisplayMode.FULL),
		CandyLocale.t("The command, and a summary of its data"))
	_mode_button.set_item_tooltip(_mode_button.get_item_index(CandyDialogue.DisplayMode.SHORT),
		CandyLocale.t("Only what each line does: the text of Spoken_Line and Comment lines, a condition's Description, the media a command plays..."))
	_mode_button.set_item_tooltip(_mode_button.get_item_index(CandyDialogue.DisplayMode.META),
		CandyLocale.t("The command, and its Meta Reference"))
	_mode_button.set_item_tooltip(_mode_button.get_item_index(CandyDialogue.DisplayMode.CUSTOM),
		CandyLocale.t("Full, Short or Meta, as chosen for each command in Settings > UI > Navigator Custom Mode"))
	_mode_button.item_selected.connect(func(index: int):
		_mode = _mode_button.get_item_id(index)
		refresh())
	bar.add_child(_mode_button)

	_content_button = Button.new()
	_content_button.focus_mode = Control.FOCUS_NONE
	_content_button.pressed.connect(_on_content_pressed)
	bar.add_child(_content_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(spacer)

	var smaller := Button.new()
	smaller.text = "A-"
	smaller.focus_mode = Control.FOCUS_NONE
	smaller.tooltip_text = CandyLocale.t("Smaller text")
	smaller.pressed.connect(_change_scale.bind(-1))
	bar.add_child(smaller)

	_scale_label = Label.new()
	_scale_label.custom_minimum_size.x = 48
	_scale_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(_scale_label)

	var bigger := Button.new()
	bigger.text = "A+"
	bigger.focus_mode = Control.FOCUS_NONE
	bigger.tooltip_text = CandyLocale.t("Larger text")
	bigger.pressed.connect(_change_scale.bind(1))
	bar.add_child(bigger)

	return bar


#* Draw the dot - full while this view is current, else its outline:
func _draw_current_dot() -> void:
	var center := _current_dot.size * 0.5
	if _is_current():
		var color := get_theme_color(&"current_dot", CandyThemeDefaults.NAVIGATOR)
		_current_dot.draw_circle(center, DOT_SIZE * 0.5, color, true, -1.0, true)
		return
	#? Outline's outer edge on the full disc's edge.
	var ring_color := get_theme_color(&"other_dot", CandyThemeDefaults.NAVIGATOR)
	_current_dot.draw_circle(center, (DOT_SIZE - DOT_RING_WIDTH) * 0.5, ring_color, false, DOT_RING_WIDTH, true)


func _is_current() -> bool:
	return CandyDialogue.current_reference == _reference


func _update_current_dot() -> void:
	if _current_dot == null:
		return
	if _is_current():
		_current_dot.tooltip_text = CandyLocale.t("Last used: the Dialogue Buttons panel and pasting act on this Navigator's selection (reference \"%s\").") % _reference
	else:
		_current_dot.tooltip_text = CandyLocale.t("Click this Navigator to have the Dialogue Buttons panel and pasting act on its selection (reference \"%s\").") % _reference
	_current_dot.queue_redraw()


#* Size the content button for its widest label, so it doesn't move under the mouse as it cycles:
func _fit_content_button() -> void:
	var font := _content_button.get_theme_font(&"font")
	var font_size := _content_button.get_theme_font_size(&"font_size")
	var widest := 0.0
	for key in CONTENTS:
		var label := CandyLocale.t(str(CONTENT_LABELS[key]), "navigator content")
		widest = maxf(widest, font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var style := _content_button.get_theme_stylebox(&"normal")
	_content_button.custom_minimum_size.x = ceilf(widest + style.get_minimum_size().x)


#* Cycle the content - Dialogue, Presets, All:
func _on_content_pressed() -> void:
	_content = str(CONTENTS[(CONTENTS.find(_content) + 1) % CONTENTS.size()])
	if _content == "dialogue":
		CandyPresets.save()
	refresh()


#* The conversations the content lists, in order:
func _listed_conversations() -> Array:
	match _content:
		"presets":
			return CandyDialogue.preset_conversation_names()
		"all":
			return CandyDialogue.preset_conversation_names() + CandyDialogue.conversation_names()
	return CandyDialogue.conversation_names()


func _change_scale(step: int) -> void:
	_scale_index = clampi(_scale_index + step, 0, TEXT_SCALES.size() - 1)
	refresh()


#& Rows

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		refresh()
		_update_current_dot()


func refresh() -> void:
	if _list == null:
		return
	_scale_label.text = "%d%%" % roundi(float(TEXT_SCALES[_scale_index]) * 100.0)
	_mode_button.select(_mode_button.get_item_index(_mode))
	_content_button.text = CandyLocale.t(str(CONTENT_LABELS[_content]), "navigator content")
	_fit_content_button()
	_content_button.tooltip_text = CandyLocale.t(str(CONTENT_TOOLTIPS[_content]))
	_list.set_rows(_build_rows())


func _build_rows() -> Array:
	var rows: Array = []
	#Ł Colors - the navigator_colors setting over the theme's (CandyNavigatorColors):
	var line_colors := CandyNavigatorColors.user_colors()
	var conversation_states := CandyNavigatorColors.for_header("conversation", line_colors, self)
	var block_states := CandyNavigatorColors.for_header("block", line_colors, self)
	var line_states: Dictionary = {}    #/ Line type -> its states
	var indents := CandyNavigatorColors.text_indents(line_colors)

	for conversation in _listed_conversations():
		var conversation_folded := _folded.has(_fold_key([conversation]))
		rows.append({
			"kind": CandyDialogue.Kind.CONVERSATION,
			"path": [conversation],
			"depth": 0,
			"text": conversation,
			"states": conversation_states,
			"text_indent": indents["conversation"],
			"font_size": _font_size(CandyDialogue.Kind.CONVERSATION),
			"foldable": true,
			"folded": conversation_folded,
		})
		if conversation_folded:
			continue

		for block in CandyDialogue.block_names(conversation):
			var block_folded := _folded.has(_fold_key([conversation, block]))
			rows.append({
				"kind": CandyDialogue.Kind.BLOCK,
				"path": [conversation, block],
				"depth": 1,
				"text": block,
				"states": block_states,
				"text_indent": indents["block"],
				"font_size": _font_size(CandyDialogue.Kind.BLOCK),
				"foldable": true,
				"folded": block_folded,
			})
			if block_folded:
				continue

			var lines := CandyDialogue.lines(conversation, block)
			for i in lines.size():
				var line: Dictionary = lines[i]
				var type := CandyDialogue.line_type(line)
				if not line_states.has(type):
					line_states[type] = CandyNavigatorColors.for_command(type, line_colors, self)
				rows.append({
					"kind": CandyDialogue.Kind.LINE,
					"path": [conversation, block, i],
					"depth": 2,
					"text": CandyDialogue.describe_line(line, i, _mode),
					#? A Comment's own Color tints its text.
					"states": CandyNavigatorColors.for_line(line, line_states[type]),
					"text_indent": indents["line"],
					"font_size": _font_size(CandyDialogue.Kind.LINE),
					"foldable": false,
					"folded": false,
				})
	return rows


func _font_size(kind: int) -> int:
	return int(round(float(BASE_FONT_SIZES[kind]) * float(TEXT_SCALES[_scale_index])))


func _fold_key(path: Array) -> String:
	return "/".join(PackedStringArray(path))


func _on_fold_toggled(path: Array) -> void:
	var key := _fold_key(path)
	if _folded.has(key):
		_folded.erase(key)
	else:
		_folded[key] = true
	refresh()


#* Update the selection, for this view's changes only:
func _on_selection_changed(changed_reference: String) -> void:
	if _list != null and changed_reference == _reference:
		_list.update_selection()


func _on_line_changed(path: Array) -> void:
	if _list == null or path.size() != 3:
		return
	var line := CandyDialogue.line_at(path)
	#? The line's own color may have changed too (a Comment's Color).
	var line_colors := CandyNavigatorColors.user_colors()
	var states := CandyNavigatorColors.for_line(line,
		CandyNavigatorColors.for_command(CandyDialogue.line_type(line), line_colors, self))
	_list.refresh_row(path, CandyDialogue.describe_line(line, int(path[2]), _mode), states)


func _on_setting_changed(key: String) -> void:
	if key == CandyNavigatorColors.SETTING:
		refresh()
	elif key == CandyDialogue.LINE_MODES_SETTING and _mode == CandyDialogue.DisplayMode.CUSTOM:
		refresh()


#& Context menu

func _on_context_menu_requested(screen_position: Vector2i, path: Array) -> void:
	_context_path = path
	#? The menu acts on this Navigator's selection.
	CandyDialogue.use_reference(_reference)
	var has_selection := not CandyDialogue.selection_of(_reference).is_empty()
	#? Presets are never exported.
	_context_menu.set_item_disabled(_context_menu.get_item_index(MenuId.TEST_HERE),
		path.is_empty() or CandyDialogue.is_preset_conversation(str(path[0])) or CandyTestRun.is_running())
	_context_menu.set_item_disabled(_context_menu.get_item_index(MenuId.RENAME), _rename_target().is_empty())
	_context_menu.set_item_disabled(_context_menu.get_item_index(MenuId.CUT), not has_selection)
	_context_menu.set_item_disabled(_context_menu.get_item_index(MenuId.COPY), not has_selection)
	_context_menu.set_item_disabled(_context_menu.get_item_index(MenuId.PASTE), not CandyDialogue.can_paste())
	_context_menu.set_item_disabled(_context_menu.get_item_index(MenuId.DUPLICATE), not has_selection)
	_context_menu.set_item_disabled(_context_menu.get_item_index(MenuId.DELETE), not has_selection)
	_context_menu.set_item_disabled(_context_menu.get_item_index(MenuId.PANEL_SETTINGS), not can_open_panel_settings())
	CandyShortcuts.show_keys_in(_context_menu, MENU_SHORTCUTS)
	CandyPopups.popup_at_point(_context_menu, screen_position, self)


func _on_context_menu_id(id: int) -> void:
	CandyDialogue.use_reference(_reference)
	match id:
		MenuId.TEST_HERE:
			_test_here()
		MenuId.RENAME:
			_start_rename()
		MenuId.CUT:
			CandyDialogue.cut_selection()
		MenuId.COPY:
			CandyDialogue.copy_selection()
		MenuId.PASTE:
			CandyDialogue.paste()
		MenuId.DUPLICATE:
			CandyDialogue.duplicate_selection()
		MenuId.DELETE:
			CandyDialogue.delete_selection()
		MenuId.PANEL_SETTINGS:
			open_panel_settings()


#& Shortcuts

#* Run the Navigator's shortcuts while its list has the focus:
func _on_list_input(event: InputEvent) -> void:
	var action := CandyShortcuts.navigator_action(event)
	if action == "":
		return
	_list.accept_event()
	CandyDialogue.use_reference(_reference)
	match action:
		"nav_cut":
			CandyDialogue.cut_selection()
		"nav_copy":
			CandyDialogue.copy_selection()
		"nav_paste":
			CandyDialogue.paste()
		"nav_duplicate":
			CandyDialogue.duplicate_selection()
		"nav_delete":
			CandyDialogue.delete_selection()
		"nav_rename":
			_start_rename()
		"nav_select_all":
			_select_all_lines()
		"nav_up":
			_list.step_selection(-1, false)
		"nav_down":
			_list.step_selection(1, false)
		"nav_extend_up":
			_list.step_selection(-1, true)
		"nav_extend_down":
			_list.step_selection(1, true)
		"nav_previous_block":
			_list.step_selection(-1, false, CandyDialogue.Kind.BLOCK)
		"nav_next_block":
			_list.step_selection(1, false, CandyDialogue.Kind.BLOCK)
		"nav_move_up":
			_move_lines(-1)
		"nav_move_down":
			_move_lines(1)
		"nav_test_here":
			var selected := CandyDialogue.selection_of(_reference)
			var path := CandyDialogue.active_path_of(_reference)
			if not CandyDialogue.is_line_path(path) and not selected.is_empty():
				path = selected[selected.size() - 1]
			_context_path = path
			if not path.is_empty() and not CandyDialogue.is_preset_conversation(str(path[0])) \
					and not CandyTestRun.is_running():
				_test_here()
	CandyShortcuts.triggered.emit(action, get_window())


#* Select every line of the blocks the selection touches (for a conversation, its blocks):
func _select_all_lines() -> void:
	var blocks: Array = []
	for path in CandyDialogue.selection_of(_reference):
		if path.size() == 1:
			for block in CandyDialogue.block_names(str(path[0])):
				blocks.append([str(path[0]), str(block)])
		elif not blocks.has([str(path[0]), str(path[1])]):
			blocks.append([str(path[0]), str(path[1])])
	var paths: Array = []
	for block in blocks:
		for i in CandyDialogue.lines(block[0], block[1]).size():
			paths.append([block[0], block[1], i])
	if paths.is_empty():
		return
	var active := CandyDialogue.active_path_of(_reference)
	CandyDialogue.set_selection(paths)
	if not paths.has(active):
		CandyDialogue.set_active_path(paths[0])


#* Move the selected lines one place up or down in their block:
func _move_lines(step: int) -> void:
	var paths := CandyDialogue.selected_paths_of_kind(CandyDialogue.Kind.LINE)
	if paths.is_empty() or CandyDialogue.selected_kind() != CandyDialogue.Kind.LINE:
		return
	var conversation := str(paths[0][0])
	var block := str(paths[0][1])
	#% Lines from several blocks don't move:
	for path in paths:
		if str(path[0]) != conversation or str(path[1]) != block:
			return
	var first := int(paths[0][2])
	var last := int(paths[paths.size() - 1][2])
	if step < 0:
		if first == 0:
			return
		CandyDialogue.move_lines(paths, conversation, block, first - 1)
	else:
		if last >= CandyDialogue.lines(conversation, block).size() - 1:
			return
		#? Index counted before the moved lines are taken out (move_lines()).
		CandyDialogue.move_lines(paths, conversation, block, last + 2)


#* Test from the right-clicked row:
func _test_here() -> void:
	if _context_path.is_empty():
		return
	var start := {"Scene": CandyTestRun.saved_start()["Scene"], "Conversation": str(_context_path[0]), "Block": "", "Line": ""}			#/ Test menu's scene; a conversation or block starts at its first line
	if _context_path.size() > 1:
		start["Block"] = str(_context_path[1])
	if _context_path.size() > 2:
		start["Line"] = str(_context_path[2])
	CandyTestRun.run(start)


#* What Rename acts on - a single selected conversation or block:
func _rename_target() -> Array:
	var selected := CandyDialogue.selection_of(_reference)
	if selected.size() != 1:
		return []
	var path: Array = selected[0]
	if path.size() >= 3:
		return []
	#% Preset conversations keep their names:
	if path.size() == 1 and CandyDialogue.is_preset_conversation(str(path[0])):
		return []
	return path


func _start_rename() -> void:
	var path := _rename_target()
	if path.is_empty():
		return

	if path.size() == 1:
		var conversation: String = path[0]
		_name_prompt.prompt(CandyLocale.t("Rename Conversation"), conversation,
			func(new_name: String) -> String:
				if new_name != conversation and CandyDialogue.has_conversation(new_name):
					return CandyLocale.t("A conversation called \"%s\" already exists.") % new_name
				return "",
			func(new_name: String) -> void:
				CandyDialogue.rename_conversation(conversation, new_name))
	else:
		var conversation: String = path[0]
		var block: String = path[1]
		_name_prompt.prompt(CandyLocale.t("Rename Block"), block,
			func(new_name: String) -> String:
				if new_name != block and CandyDialogue.has_block(conversation, new_name):
					return CandyLocale.t("A block called \"%s\" already exists in this conversation.") % new_name
				return "",
			func(new_name: String) -> void:
				CandyDialogue.rename_block(conversation, block, new_name))


#& Options

#* Options - the reference and the Area's minimum size:
func has_settings() -> bool:
	return true


func open_settings() -> void:
	CandyReferenceDialog.open_for_panel(self,
		CandyLocale.t("Navigators with the same reference share their selection, and the Dialogue Editors with this reference edit the line clicked in them."),
		_reference, _set_reference)


func _set_reference(reference: String) -> void:
	_reference = CandyDialogue.clean_reference(reference)
	if _list != null:
		_list.reference = _reference
		_list.update_selection()
	_update_current_dot()


#& Panel state

func get_state() -> Dictionary:
	if _list == null:
		return _pending_state
	return {"mode": _mode, "content": _content, "scale": _scale_index, "folded": _folded.keys(),
		"reference": _reference}


func set_state(state: Dictionary) -> void:
	_pending_state = state
	if _list != null:
		_apply_state(state)
		refresh()


func _apply_state(state: Dictionary) -> void:
	_mode = int(state.get("mode", CandyDialogue.DisplayMode.FULL))
	_content = str(state.get("content", "dialogue"))
	if not CONTENTS.has(_content):
		_content = "dialogue"
	_scale_index = clampi(int(state.get("scale", 2)), 0, TEXT_SCALES.size() - 1)
	_set_reference(str(state.get("reference", CandyDialogue.DEFAULT_REFERENCE)))
	_folded = {}
	var folded = state.get("folded", [])
	if folded is Array:
		for key in folded:
			_folded[str(key)] = true