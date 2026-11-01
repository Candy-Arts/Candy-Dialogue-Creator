#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyBBCodeEdit
extends Control

#^ Text changed by the user, undo / redo, or setting `text`:
signal text_changed
signal caret_changed
#^ The focus left the editor and its popup:
signal focus_left

#^ Godot's own BBCode tags (any other [name] is text, unless in custom_tags):
const BUILT_IN_TAGS: Array[String] = ["b", "i", "u", "s", "code", "char", "p", "br", "hr", "center", "left",
	"right", "fill", "indent", "url", "hint", "img", "font", "font_size", "opentype_features", "lang",
	"table", "cell", "ul", "ol", "lb", "rb", "lrm", "rlm", "lre", "rle", "lro", "rlo", "pdf", "alm", "lri",
	"rli", "fsi", "pdi", "zwj", "zwnj", "wj", "shy", "color", "bgcolor", "fgcolor", "outline_size",
	"outline_color", "dropcap", "wave", "tornado", "shake", "fade", "rainbow", "pulse"]
#^ Tags with no closing tag:
const STANDALONE_TAGS: Array[String] = ["lb", "rb", "br", "hr", "char", "lrm", "rlm", "lre", "rle", "lro",
	"rlo", "pdf", "alm", "lri", "rli", "fsi", "pdi", "zwj", "zwnj", "wj", "shy"]
#^ Tags standing for [ and ] - never hidden, or the text would lose them:
const CHARACTER_TAGS: Array[String] = ["lb", "rb"]
#^ Fallback types for theme items:
const BOX_TYPE := &"TextEdit"
const FONT_TYPE := &"RichTextLabel"
#^ Tag styles (see _resolve_look()), same look, only the first is hidden:
#? Character tags and empty tag pairs (_empty_pairs()) take the second.
const TAG_STYLE := 0
const SHOWN_TAG_STYLE := 1
#^ Marker style (see tag_markers):
const MARKER_STYLE := 2
#^ Minimum WCAG contrast of a marker with the background:
const MARKER_CONTRAST := 3.0
const DEFAULT_MARKER_CHARACTER := "◊"
const DEFAULT_MARKER_COLOR := Color(0.6, 0.3, 0.9)
#^ Tag color - the text color at this alpha:
const TAG_ALPHA := 0.45
#^ Typing (or deleting) within this time is one undo step:
const MERGE_TIME_MS := 1500
const MAX_UNDO := 500
const CARET_WIDTH := 2.0
const BLINK_TIME := 0.55
const WHEEL_ROWS := 3
const MULTI_CLICK_MS := 400
const BOLD_STRENGTH := 0.7
const ITALIC_SLANT := 0.2
#^ Popup's gap from the text, and room for the caret after its text:
const POPUP_GAP := 2.0
const POPUP_CARET_ROOM := 16.0
#^ Highlight of the text the popup shows - caret color at this alpha:
const POPUP_MARK_ALPHA := 0.12
#^ Popup z_index, above the controls around the editor:
const POPUP_Z_INDEX := 1

enum MenuItem {UNDO, REDO, CUT, COPY, PASTE, SELECT_ALL}
#^ Which hidden tags show as markers:
enum TagMarkers {OFF, ON, SMART}
#^ Actions whose keys the menu shows beside its items:
const MENU_ACTIONS := {
	MenuItem.UNDO: "ui_undo", MenuItem.REDO: "ui_redo", MenuItem.CUT: "ui_cut", MenuItem.COPY: "ui_copy",
	MenuItem.PASTE: "ui_paste", MenuItem.SELECT_ALL: "ui_text_select_all",
}

#^ The BBCode. Setting it clears the undo history:
var text: String:
	get:
		return "\n".join(_lines)
	set(value):
		_load_text(value)

#^ Hide the tags; the tags at the caret show in a popup:
var hide_tags := false:
	set(value):
		hide_tags = value
		_look_changed()
		if _popup != null:
			_popup.visible = false
			_queue_popup_update()

#^ With hidden tags, which show as markers:
var tag_markers := TagMarkers.ON:
	set(value):
		tag_markers = value
		_look_changed()

#^ Marker character (its first character):
var marker_character := DEFAULT_MARKER_CHARACTER:
	set(value):
		marker_character = value
		_look_changed()

#^ Marker color, adjusted to contrast with the background (MARKER_CONTRAST):
var marker_color := DEFAULT_MARKER_COLOR:
	set(value):
		marker_color = value
		_look_changed()

#^ Off - read, select and copy only:
var editable := true:
	set(value):
		editable = value
		if _popup_edit != null:
			_popup_edit.editable = value
		_look_changed()

#^ Shown faint while the text is empty:
var placeholder_text := "":
	set(value):
		placeholder_text = value
		queue_redraw()

#^ Custom tags, written [name]...[/name]:
#?   {name: {"color": Color or "#rrggbb", "bold": bool, "italic": bool}}, keys optional.
#? A built-in tag listed here gets that look on top of its own.
var custom_tags: Dictionary = {}:
	set(value):
		custom_tags = value
		_look_changed()

#^ Added below every row:
var line_spacing := 2.0:
	set(value):
		line_spacing = value
		_look_changed()
#^ Indent per [indent], [ul] or [ol] level, in pixels:
var indent_width := 24.0:
	set(value):
		indent_width = value
		_look_changed()
#^ Tab width, in spaces:
var tab_size := 4:
	set(value):
		tab_size = value
		_look_changed()

static var _tag_regex: RegEx = null

var _ts: TextServer
#^ One String and one paragraph (_build_para()) per line:
var _lines := PackedStringArray([""])
var _paras: Array[Dictionary] = []
#^ Top of each paragraph, from the top of the text:
var _para_top := PackedFloat32Array()
var _content_height := 0.0
var _needs_build := true
var _built_width := -1.0

#^ Resolved fonts and colors (_resolve_look()), the styles, and each tag stack's style:
var _look: Dictionary = {}
var _styles: Array[Dictionary] = []
var _stack_styles: Dictionary = {}
#^ Text margins (the box's content margins):
var _margin_left := 0.0
var _margin_right := 0.0
var _margin_top := 0.0
var _margin_bottom := 0.0

var _caret := Vector2i.ZERO
var _anchor := Vector2i.ZERO
#^ The x the caret keeps moving up and down, -1 for none:
var _wanted_x := -1.0
var _caret_shown := true

var _undo: Array[Dictionary] = []
var _undo_index := 0

#^ Draws the text, clipped to the box's content (the editor draws the box):
var _canvas: Control
var _scroll_bar: VScrollBar
var _blink_timer: Timer
var _menu: PopupMenu
var _dragging := false
var _click_count := 0
var _last_click_ms := 0
var _last_click_position := Vector2.ZERO
#^ The editor is moving the focus to or from its popup (not leaving):
var _moving_focus := false

#^ Popup - the BBCode of the tag group at the caret (_group_at()):
#? From _popup_from to _popup_to, when _popup_shown. While edited (_popup_editing) it keeps its group
#? and writes each change to the text at once - one undo step per focus (_popup_session).
var _popup: PanelContainer
var _popup_edit: TextEdit
var _popup_shown := false
var _popup_editing := false
var _popup_from := Vector2i.ZERO
var _popup_to := Vector2i.ZERO
var _popup_session := 0
var _popup_original := ""
var _popup_caret := Vector2i.ZERO
var _popup_queued := false
#^ Tag groups of the whole text (_text_groups()), until it changes:
var _groups: Array = []
var _groups_dirty := true


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_IBEAM
	clip_contents = true
	_ts = TextServerManager.get_primary_interface()
	if _tag_regex == null:
		_tag_regex = RegEx.create_from_string("\\[(/?)([A-Za-z_][A-Za-z0-9_]*)([= ][^\\[\\]]*)?\\]")
	_canvas = Control.new()
	_canvas.clip_contents = true
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_text)
	add_child(_canvas, false, Node.INTERNAL_MODE_FRONT)
	_scroll_bar = VScrollBar.new()
	_scroll_bar.focus_mode = Control.FOCUS_NONE
	_scroll_bar.mouse_default_cursor_shape = Control.CURSOR_ARROW
	_scroll_bar.value_changed.connect(func(_value: float) -> void:
		_canvas.queue_redraw()
		_queue_popup_update())
	add_child(_scroll_bar, false, Node.INTERNAL_MODE_FRONT)
	_blink_timer = Timer.new()
	_blink_timer.wait_time = BLINK_TIME
	_blink_timer.timeout.connect(_blink)
	add_child(_blink_timer, false, Node.INTERNAL_MODE_FRONT)
	_menu = PopupMenu.new()
	_menu.add_item(CandyLocale.t("Undo"), MenuItem.UNDO)
	_menu.add_item(CandyLocale.t("Redo"), MenuItem.REDO)
	_menu.add_separator()
	_menu.add_item(CandyLocale.t("Cut"), MenuItem.CUT)
	_menu.add_item(CandyLocale.t("Copy"), MenuItem.COPY)
	_menu.add_item(CandyLocale.t("Paste"), MenuItem.PASTE)
	_menu.add_separator()
	_menu.add_item(CandyLocale.t("Select All"), MenuItem.SELECT_ALL)
	_menu.id_pressed.connect(_on_menu_pressed)
	add_child(_menu, false, Node.INTERNAL_MODE_FRONT)
	_popup = PanelContainer.new()
	_popup.visible = false
	_popup.top_level = true
	_popup.z_index = POPUP_Z_INDEX
	_popup.mouse_default_cursor_shape = Control.CURSOR_ARROW
	#? Height follows its text, wrapped lines included.
	_popup.minimum_size_changed.connect(_queue_popup_update)
	_popup_edit = TextEdit.new()
	_popup_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_popup_edit.scroll_fit_content_height = true
	_popup_edit.text_changed.connect(_apply_popup_text)
	_popup_edit.gui_input.connect(_on_popup_input)
	_popup_edit.focus_entered.connect(_on_popup_focus_entered)
	_popup_edit.focus_exited.connect(_on_popup_focus_exited)
	_popup.add_child(_popup_edit)
	add_child(_popup, false, Node.INTERNAL_MODE_FRONT)
	#? Follow the editor when a container scrolls it (the popup floats).
	set_notify_transform(true)
	set_process(false)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			if not _needs_build:
				_place_children()
				if _text_width() != _built_width:
					_relayout()
				else:
					_update_scroll_bar()
			queue_redraw()
			_canvas.queue_redraw()
			_queue_popup_update()
		NOTIFICATION_THEME_CHANGED:
			_look_changed()
		NOTIFICATION_TRANSFORM_CHANGED:
			_queue_popup_update()
		NOTIFICATION_FOCUS_ENTER:
			_restart_blink()
			queue_redraw()
			_canvas.queue_redraw()
			_queue_popup_update()
		NOTIFICATION_FOCUS_EXIT:
			_blink_timer.stop()
			queue_redraw()
			_canvas.queue_redraw()
			_queue_popup_update()
			_on_focus_exited()


#& Public

func get_selected_text() -> String:
	if not has_selection():
		return ""
	return _get_range(_selection_start(), _selection_end_for_change())


func has_selection() -> bool:
	return _caret != _anchor


func select_all() -> void:
	_anchor = Vector2i.ZERO
	_caret = Vector2i(_lines[_lines.size() - 1].length(), _lines.size() - 1)
	_caret_moved()


func get_caret() -> Vector2i:
	return _caret


#* Move the caret and scroll to it:
func set_caret(position_value: Vector2i, keep_selection := false) -> void:
	_ensure_built()
	_move_caret(_snap(_clamp_position(position_value)), keep_selection)


#* Replace the selection, if any, with new_text, as the user would:
func insert_text_at_caret(new_text: String) -> void:
	_insert(new_text, "")


#* Type an insert (see CandyInserts), one undo step:
func insert_around(left: String, middle: String, right: String) -> void:
	if not editable:
		return
	#¦ 1. Selection - wrap it, middle (if not empty) replaces its spaces:
	if has_selection():
		var from := _selection_start()
		var selected := _get_range(from, _selection_end_for_change())
		var inner := selected
		if not middle.is_empty():
			inner = selected.replace(" ", middle)
		_edit(from, _selection_end_for_change(), left + inner + right, "")
		return
	#¦ 2. No selection - caret between left and right, even after a hidden tag (typing takes its formatting):
	var at := _caret
	_edit(at, at, left + right, "")
	_caret = _end_of(at, left)
	_anchor = _caret
	if _undo_index > 0:
		_undo[_undo_index - 1]["caret_after"] = _caret
	_caret_moved()


func copy() -> void:
	if has_selection():
		DisplayServer.clipboard_set(get_selected_text())


func cut() -> void:
	if has_selection() and editable:
		copy()
		_insert("", "")


func paste() -> void:
	var pasted := DisplayServer.clipboard_get().replace("\r\n", "\n").replace("\r", "\n")
	if not pasted.is_empty():
		_insert(pasted, "")


func undo() -> void:
	if _undo_index == 0 or not editable:
		return
	_leave_popup()
	_undo_index -= 1
	var step := _undo[_undo_index]
	_replace(step["from"], _end_of(step["from"], step["inserted"]), step["removed"])
	_caret = _clamp_position(step["caret_before"])
	_anchor = _clamp_position(step["anchor_before"])
	_settle()
	_after_edit()


func redo() -> void:
	if _undo_index >= _undo.size() or not editable:
		return
	_leave_popup()
	var step := _undo[_undo_index]
	_undo_index += 1
	_replace(step["from"], _end_of(step["from"], step["removed"]), step["inserted"])
	_caret = _clamp_position(step["caret_after"])
	_anchor = _caret
	_settle()
	_after_edit()


func clear_undo_history() -> void:
	_undo.clear()
	_undo_index = 0


#* Whether the editor or its popup has the focus:
func has_focus_within() -> bool:
	return has_focus() or _popup_edit.has_focus()


#* Right-click menu, to add items to (its own ids are MenuItem's):
func get_menu() -> PopupMenu:
	return _menu


func get_v_scroll_bar() -> VScrollBar:
	return _scroll_bar


#* Tag popup, to style it:
func get_tag_popup() -> PanelContainer:
	return _popup


#* Tag popup's field, to style or watch it:
func get_popup_edit() -> TextEdit:
	return _popup_edit


#& Text

func _load_text(value: String) -> void:
	_leave_popup()
	_lines = value.replace("\r\n", "\n").split("\n")
	_groups_dirty = true
	_paras.clear()
	_needs_build = true
	clear_undo_history()
	_caret = Vector2i.ZERO
	_anchor = Vector2i.ZERO
	_wanted_x = -1.0
	if _scroll_bar != null:
		_scroll_bar.value = 0.0
	_redraw()
	_queue_popup_update()
	text_changed.emit()


func _get_range(from: Vector2i, to: Vector2i) -> String:
	if from.y == to.y:
		return _lines[from.y].substr(from.x, to.x - from.x)
	var parts := PackedStringArray([_lines[from.y].substr(from.x)])
	for index in range(from.y + 1, to.y):
		parts.append(_lines[index])
	parts.append(_lines[to.y].substr(0, to.x))
	return "\n".join(parts)


#* Where `inserted` ends when written at `from`:
func _end_of(from: Vector2i, inserted: String) -> Vector2i:
	var pieces := inserted.split("\n")
	if pieces.size() == 1:
		return Vector2i(from.x + inserted.length(), from.y)
	return Vector2i(pieces[pieces.size() - 1].length(), from.y + pieces.size() - 1)


#* Replace text between two positions (no undo, see _edit()), restyle, and return the new end:
func _replace(from: Vector2i, to: Vector2i, new_text: String) -> Vector2i:
	_ensure_built()
	var before := _lines[from.y].substr(0, from.x)
	var after := _lines[to.y].substr(to.x)
	var pieces := new_text.split("\n")
	pieces[0] = before + pieces[0]
	var last := pieces.size() - 1
	var end := Vector2i(pieces[last].length(), from.y + last)
	pieces[last] = pieces[last] + after
	_groups_dirty = true
	for index in range(to.y, from.y - 1, -1):
		_lines.remove_at(index)
		_paras.remove_at(index)
	for index in pieces.size():
		_lines.insert(from.y + index, pieces[index])
		_paras.insert(from.y + index, {})
	_restyle_from(from.y, from.y + last)
	return end


#* Make a user change, recorded for undo, caret after it:
func _edit(from: Vector2i, to: Vector2i, new_text: String, kind: String) -> void:
	var removed := _get_range(from, to)
	if removed == new_text:
		return
	var caret_before := _caret
	var anchor_before := _anchor
	var end := _replace(from, to, new_text)
	var now := Time.get_ticks_msec()
	var merged := false
	#Ł Merge typing / deleting in a row (MERGE_TIME_MS) or one popup session into the last step:
	if not kind.is_empty() and _undo_index > 0 and _undo_index == _undo.size():
		var last := _undo[_undo_index - 1]
		if last["kind"] == kind and (kind == "popup" or now - int(last["time"]) < MERGE_TIME_MS):
			match kind:
				"type":
					if removed.is_empty() and last["end"] == from:
						last["inserted"] = str(last["inserted"]) + new_text
						last["end"] = end
						merged = true
				"back":
					if new_text.is_empty() and last["from"] == to:
						last["removed"] = removed + str(last["removed"])
						last["from"] = from
						last["end"] = from
						merged = true
				"delete":
					if new_text.is_empty() and last["from"] == from:
						last["removed"] = str(last["removed"]) + removed
						merged = true
				"popup":
					if last["session"] == _popup_session and last["from"] == from and last["end"] == to:
						last["inserted"] = new_text
						last["end"] = end
						merged = true
			if merged:
				last["time"] = now
				last["caret_after"] = end
	if not merged:
		_undo.resize(_undo_index)
		_undo.append({
			"from": from, "removed": removed, "inserted": new_text, "end": end, "kind": kind,
			"time": now, "caret_before": caret_before, "anchor_before": anchor_before,
			"caret_after": end, "session": _popup_session,
		})
		if _undo.size() > MAX_UNDO:
			_undo.pop_front()
		_undo_index = _undo.size()
	_caret = end
	_anchor = end
	_after_edit()


#* Like _edit(), but with hidden tags keep the tags in the range (_kept_tags()):
func _edit_keeping_tags(from: Vector2i, to: Vector2i, new_text: String, kind: String) -> void:
	if not hide_tags:
		_edit(from, to, new_text, kind)
		return
	var kept := _kept_tags(from, to)
	if kept.is_empty():
		_edit(from, to, new_text, kind)
	else:
		#Ł Kept tags after new_text:
		_edit(from, to, new_text + kept, "")
	#Ł Caret after new_text:
	_caret = _snap(_end_of(from, new_text))
	_anchor = _caret
	if _undo_index > 0:
		_undo[_undo_index - 1]["caret_after"] = _caret
	_caret_moved()


func _after_edit() -> void:
	_wanted_x = -1.0
	_scroll_to_caret()
	_restart_blink()
	_redraw()
	_queue_popup_update()
	text_changed.emit()
	caret_changed.emit()


#* Type new_text at the caret, over the selection if any:
func _insert(new_text: String, kind: String) -> void:
	if not editable:
		return
	if has_selection():
		_edit_keeping_tags(_selection_start(), _selection_end_for_change(), new_text, kind)
	else:
		#? Caret stays after a just-typed hidden tag until it moves (typing [b] goes on in bold).
		_edit(_caret, _caret, new_text, kind)


#* Delete the character (or word) before the caret, or the selection:
func _backspace(by_word: bool) -> void:
	if not editable:
		return
	if has_selection():
		_insert("", "")
		return
	var para := _paras[_caret.y]
	var vis := _vis(para, _caret.x)
	#% Word - hidden tags are kept:
	if by_word:
		var from := _word_left(_caret)
		if from != _caret:
			_edit_keeping_tags(from, _caret, "", "")
		return
	#% Right after a just-typed tag - delete its last character:
	if hide_tags and _caret.x > 0 and _caret != _snap(_caret):
		_edit(Vector2i(_caret.x - 1, _caret.y), _caret, "", "back")
	elif vis > 0 and para["markers"].has(vis - 1):
		_delete_marker(_caret.y, para["markers"][vis - 1])
	elif vis > 0:
		var column: int = para["char_src"][vis - 1]
		_edit(Vector2i(column, _caret.y), Vector2i(column + 1, _caret.y), "", "back")
	elif _caret.y > 0:
		_edit(Vector2i(_lines[_caret.y - 1].length(), _caret.y - 1), Vector2i(0, _caret.y), "", "back")


func _delete(by_word: bool) -> void:
	if not editable:
		return
	if has_selection():
		_insert("", "")
		return
	var para := _paras[_caret.y]
	var vis := _vis(para, _caret.x)
	if by_word:
		var to := _word_right(_caret)
		if to != _caret:
			_edit_keeping_tags(_caret, _cluster_end(to), "", "")
		return
	var caret_before := _caret
	if vis < int(para["vis_length"]) and para["markers"].has(vis):
		_delete_marker(_caret.y, para["markers"][vis])
		return
	if vis < int(para["vis_length"]):
		var column: int = para["char_src"][vis]
		_edit(Vector2i(column, _caret.y), Vector2i(column + 1, _caret.y), "", "delete")
	elif _caret.y < _lines.size() - 1:
		_edit(Vector2i(_lines[_caret.y].length(), _caret.y), Vector2i(0, _caret.y + 1), "", "delete")
	#Ł The caret stays (the deleted text was after it):
	_caret = caret_before
	_anchor = caret_before
	_redraw()


#* Delete a marker's tag and its partner, on any line, keeping the text between:
func _delete_marker(line_index: int, tag: Dictionary) -> void:
	var from := Vector2i(tag["start"], line_index)
	var to := Vector2i(tag["end"], line_index)
	var tags := _all_tags()
	var partners := _partners(tags)
	var partner: Dictionary = {}
	for index in tags.size():
		if tags[index]["from"] == from and partners.has(index):
			partner = tags[partners[index]]
	#% No partner - delete the tag alone:
	if partner.is_empty():
		_edit(from, to, "", "")
		return
	var opening_from := from
	var opening_to := to
	var closing_from: Vector2i = partner["from"]
	var closing_to: Vector2i = partner["to"]
	var deleting_opening := true
	if _is_before(closing_from, from):
		opening_from = partner["from"]
		opening_to = partner["to"]
		closing_from = from
		closing_to = to
		deleting_opening = false
	var inner := _get_range(opening_to, closing_from)
	_edit(opening_from, closing_to, inner, "")
	#Ł Caret where the marker was:
	_caret = opening_from
	if not deleting_opening:
		_caret = _end_of(opening_from, inner)
	_anchor = _caret
	if _undo_index > 0:
		_undo[_undo_index - 1]["caret_after"] = _caret
	_caret_moved()


#* Tags in a range that deleting the range keeps:
func _kept_tags(from: Vector2i, to: Vector2i) -> String:
	var found: Array[Dictionary] = []
	for line_index in range(from.y, to.y + 1):
		var start := 0
		if line_index == from.y:
			start = from.x
		var end := _lines[line_index].length()
		if line_index == to.y:
			end = to.x
		for tag in _line_tags(_lines[line_index]):
			if tag["start"] >= start and tag["end"] <= end:
				found.append(tag)
	#Ł Drop pairs fully inside and standalone tags (part of the deleted text):
	var dropped: Dictionary = {}
	var open: Array[int] = []
	for index in found.size():
		var tag := found[index]
		if tag["closing"]:
			for open_index in range(open.size() - 1, -1, -1):
				if found[open[open_index]]["name"] == tag["name"]:
					dropped[open[open_index]] = true
					dropped[index] = true
					open.remove_at(open_index)
					break
		elif STANDALONE_TAGS.has(tag["name"]):
			dropped[index] = true
		else:
			open.append(index)
	var kept := ""
	for index in found.size():
		if not dropped.has(index):
			kept += str(found[index]["text"])
	return kept


#* Tags of a line, in order - {"start", "end", "name", "closing", "text"}:
func _line_tags(line_text: String) -> Array[Dictionary]:
	var tags: Array[Dictionary] = []
	for found in _tag_regex.search_all(line_text):
		var closing := found.get_string(1) == "/"
		var tag_name := found.get_string(2)
		if not _is_tag(tag_name) or (closing and not found.get_string(3).is_empty()):
			continue
		tags.append({"start": found.get_start(), "end": found.get_end(), "name": tag_name,
			"closing": closing, "text": found.get_string()})
	return tags


#& Styles

func _look_changed() -> void:
	_needs_build = true
	_groups_dirty = true
	_redraw()


func _redraw() -> void:
	queue_redraw()
	if _canvas != null:
		_canvas.queue_redraw()


#* Theme item of the own type, else of the fallback type:
func _theme_font(item: StringName) -> Font:
	#% By name (a type name doesn't reach a variation's base type):
	if has_theme_font(item):
		return get_theme_font(item)
	return get_theme_font(item, FONT_TYPE)


func _theme_font_size(item: StringName) -> int:
	if has_theme_font_size(item):
		return get_theme_font_size(item)
	return get_theme_font_size(item, FONT_TYPE)


func _theme_color(item: StringName) -> Color:
	if has_theme_color(item):
		return get_theme_color(item)
	return get_theme_color(item, BOX_TYPE)


func _theme_stylebox(item: StringName) -> StyleBox:
	if has_theme_stylebox(item):
		return get_theme_stylebox(item)
	return get_theme_stylebox(item, BOX_TYPE)


#* The box behind the text (read_only while not editable):
func _box() -> StyleBox:
	if editable:
		return _theme_stylebox(&"normal")
	return _theme_stylebox(&"read_only")


#* Resolve fonts, colors and sizes from the theme:
func _resolve_look() -> void:
	var box := _box()
	_margin_left = box.get_margin(SIDE_LEFT)
	_margin_right = box.get_margin(SIDE_RIGHT)
	_margin_top = box.get_margin(SIDE_TOP)
	_margin_bottom = box.get_margin(SIDE_BOTTOM)
	var normal := _theme_font(&"normal_font")
	var bold := _theme_font(&"bold_font")
	var italic := _theme_font(&"italics_font")
	var bold_italic := _theme_font(&"bold_italics_font")
	var real_bold := bold != normal
	var real_italic := italic != normal
	if not real_bold:
		bold = _variation(normal, true, false)
	if not real_italic:
		italic = _variation(normal, false, true)
	if bold_italic == normal or bold_italic == bold or bold_italic == italic:
		if real_bold:
			bold_italic = _variation(bold, false, true)
		else:
			bold_italic = _variation(normal, true, true)
	var mono := _theme_font(&"mono_font")
	var base_size := _theme_font_size(&"normal_font_size")
	var main_color := _theme_color(&"font_color")
	if not editable:
		main_color = _theme_color(&"font_readonly_color")
	var faint := Color(main_color, main_color.a * TAG_ALPHA)
	var space_width := normal.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, base_size).x
	var caret := _theme_color(&"caret_color")
	_look = {
		"fonts": {
			"normal": normal, "bold": bold, "italic": italic, "bold_italic": bold_italic,
			"mono": mono, "mono_bold": _variation(mono, true, false),
			"mono_italic": _variation(mono, false, true), "mono_bold_italic": _variation(mono, true, true),
		},
		"size": base_size,
		"text_color": main_color,
		"placeholder_color": _theme_color(&"font_placeholder_color"),
		"selection_color": _theme_color(&"selection_color"),
		"caret_color": caret,
		"popup_mark_color": Color(caret, POPUP_MARK_ALPHA),
		"space_width": space_width,
		"tab_stops": PackedFloat32Array([maxf(1.0, space_width * tab_size)]),
	}
	#Ł Clear the styles (the text must be built again):
	_styles.clear()
	_stack_styles.clear()
	_styles.append(_make_style(normal, base_size, faint, Color.TRANSPARENT, false, false, HORIZONTAL_ALIGNMENT_LEFT, 0))
	_styles.append(_styles[TAG_STYLE].duplicate())
	_styles.append(_make_style(normal, base_size, _marker_look(box), Color.TRANSPARENT, false, false,
		HORIZONTAL_ALIGNMENT_LEFT, 0))


#* marker_color, contrasting with the box's background if it has one:
func _marker_look(box: StyleBox) -> Color:
	var flat := box as StyleBoxFlat
	if flat == null or flat.bg_color.a == 0.0:
		return marker_color
	return contrasting(marker_color, flat.bg_color, MARKER_CONTRAST)


#* Lighten or darken a color just enough to reach a WCAG contrast ratio:
static func contrasting(color: Color, background: Color, ratio: float) -> Color:
	if contrast_ratio(color, background) >= ratio:
		return color
	#@ Step 1 - Toward the end with more room (black on light, white on dark):
	var target := Color.WHITE
	if contrast_ratio(Color.BLACK, background) > contrast_ratio(Color.WHITE, background):
		target = Color.BLACK
	#@ Step 2 - Step toward it, alpha kept, until the ratio is reached or as far as it can:
	var adjusted := color
	for step in range(1, 21):
		adjusted = color.lerp(target, step / 20.0)
		adjusted.a = color.a
		if contrast_ratio(adjusted, background) >= ratio:
			break
	return adjusted


#* WCAG contrast ratio of two colors, 1 to 21:
static func contrast_ratio(color: Color, background: Color) -> float:
	#Ł Translucent color over the background:
	var shown := background.lerp(Color(color, 1.0), color.a)
	var first := _relative_luminance(shown)
	var second := _relative_luminance(background)
	return (maxf(first, second) + 0.05) / (minf(first, second) + 0.05)


static func _relative_luminance(color: Color) -> float:
	var linear := color.srgb_to_linear()
	return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b


func _variation(base: Font, embolden: bool, slant: bool) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = base
	if embolden:
		variation.variation_embolden = BOLD_STRENGTH
	if slant:
		variation.variation_transform = Transform2D(Vector2(1.0, ITALIC_SLANT), Vector2(0.0, 1.0), Vector2.ZERO)
	return variation


func _make_style(font: Font, size_value: int, color: Color, background: Color, underline: bool, strike: bool,
		align: int, indent: int) -> Dictionary:
	return {
		"font": font, "size": size_value, "color": color, "background": background,
		"underline": underline, "strike": strike, "align": align, "indent": indent,
	}


#* Style id of the text after a tag stack:
#? stack: open tags, outermost first, each "name\tvalue".
func _style_id(stack: PackedStringArray) -> int:
	var key := "\n".join(stack)
	if _stack_styles.has(key):
		return _stack_styles[key]
	var bold := false
	var italic := false
	var mono := false
	var underline := false
	var strike := false
	var color: Color = _look["text_color"]
	var background := Color.TRANSPARENT
	var size_value: int = _look["size"]
	var align := HORIZONTAL_ALIGNMENT_LEFT
	var indent := 0
	for entry in stack:
		var tag_name := entry.get_slice("\t", 0)
		var value := entry.get_slice("\t", 1)
		match tag_name:
			"b":
				bold = true
			"i":
				italic = true
			"u":
				underline = true
			"s":
				strike = true
			"code":
				mono = true
			"url":
				underline = true
			"color":
				color = Color.from_string(value, color)
			"bgcolor":
				background = Color.from_string(value, background)
			"font_size":
				if value.is_valid_int():
					size_value = clampi(int(value), 1, 512)
			"center":
				align = HORIZONTAL_ALIGNMENT_CENTER
			"right":
				align = HORIZONTAL_ALIGNMENT_RIGHT
			"left", "fill":
				align = HORIZONTAL_ALIGNMENT_LEFT
			"indent", "ul", "ol":
				indent += 1
		var own: Variant = custom_tags.get(tag_name)
		if own is Dictionary:
			var own_color: Variant = own.get("color", Color.TRANSPARENT)
			if own_color is String:
				own_color = Color.from_string(own_color, Color.TRANSPARENT)
			if own_color is Color and own_color.a > 0.0:
				color = own_color
			if _is_on(own.get("bold", false)):
				bold = true
			if _is_on(own.get("italic", false)):
				italic = true
	var fonts: Dictionary = _look["fonts"]
	var font_key := ""
	if mono:
		font_key = "mono_"
	if bold and italic:
		font_key += "bold_italic"
	elif bold:
		font_key += "bold"
	elif italic:
		font_key += "italic"
	elif mono:
		font_key = "mono"
	else:
		font_key = "normal"
	_styles.append(_make_style(fonts[font_key], size_value, color, background, underline, strike, align, indent))
	var id := _styles.size() - 1
	_stack_styles[key] = id
	return id


func _is_on(value: Variant) -> bool:
	if value is bool:
		return value
	var spelled := str(value).to_lower()
	return spelled == "1" or spelled == "true"


func _is_tag(tag_name: String) -> bool:
	return BUILT_IN_TAGS.has(tag_name) or custom_tags.has(tag_name)


#* Split a line into tags and text:
func _parse(line_text: String, start_stack: PackedStringArray) -> Dictionary:
	var stack := start_stack.duplicate()
	var styles := PackedInt32Array()
	styles.resize(line_text.length())
	var current := _style_id(stack)
	var start_style := current
	var first_text := -1
	var cursor := 0
	var tags := _line_tags(line_text)
	for tag in tags:
		var tag_name: String = tag["name"]
		var tag_start: int = tag["start"]
		if tag_start > cursor and first_text < 0:
			first_text = current
		_fill(styles, cursor, tag_start, current)
		if CHARACTER_TAGS.has(tag_name):
			_fill(styles, tag_start, tag["end"], SHOWN_TAG_STYLE)
		else:
			_fill(styles, tag_start, tag["end"], TAG_STYLE)
		cursor = tag["end"]
		if tag["closing"]:
			for index in range(stack.size() - 1, -1, -1):
				if stack[index].get_slice("\t", 0) == tag_name:
					stack.remove_at(index)
					break
		elif not STANDALONE_TAGS.has(tag_name):
			var tag_text: String = tag["text"]
			var value := tag_text.substr(tag_name.length() + 1, tag_text.length() - tag_name.length() - 2)
			if value.begins_with("="):
				value = value.substr(1)
			stack.append(tag_name + "\t" + value.strip_edges())
		current = _style_id(stack)
	if cursor < line_text.length() and first_text < 0:
		first_text = current
	_fill(styles, cursor, line_text.length(), current)
	#Ł Align / indent from the first text character, or for tags only, the start's align with a smaller indent:
	var align: int
	var indent: int
	if first_text >= 0:
		align = _styles[first_text]["align"]
		indent = _styles[first_text]["indent"]
	else:
		align = _styles[start_style]["align"]
		indent = mini(_styles[start_style]["indent"], _styles[current]["indent"])
	return {"styles": styles, "end": stack, "align": align, "indent": indent, "end_style": current, "tags": tags}	#/ "styles" per character, "end": tags still open


#* Tag pairs of a line with only tags between them (character tags count as text):
func _empty_pairs(tags: Array[Dictionary]) -> Array[Vector2i]:
	var pairs: Array[Vector2i] = []
	var open: Array[int] = []
	for index in tags.size():
		var tag := tags[index]
		if tag["closing"]:
			for open_index in range(open.size() - 1, -1, -1):
				if tags[open[open_index]]["name"] == tag["name"]:
					#% In `[b][i][/i][/b]`, both pairs:
					if _only_tags_between(tags, open[open_index], index):
						pairs.append(Vector2i(open[open_index], index))
					open.remove_at(open_index)
					break
		elif not STANDALONE_TAGS.has(tag["name"]):
			open.append(index)
	return pairs		#/ Vector2i(opening, closing) indexes in tags


func _only_tags_between(tags: Array[Dictionary], opening: int, closing: int) -> bool:
	var cursor: int = tags[opening]["end"]
	for index in range(opening + 1, closing):
		if tags[index]["start"] > cursor or CHARACTER_TAGS.has(tags[index]["name"]):
			return false
		cursor = tags[index]["end"]
	return tags[closing]["start"] <= cursor


#* Tags of a line that show as markers (tag_markers) - { start column = tag }:
func _marked_tags(tags: Array[Dictionary], line_length: int) -> Dictionary:
	var marked: Dictionary = {}
	if not hide_tags or tag_markers == TagMarkers.OFF:
		return marked
	if tag_markers == TagMarkers.ON:
		for tag in tags:
			if not CHARACTER_TAGS.has(tag["name"]):
				marked[tag["start"]] = tag
		return marked
	for pair in _empty_pairs(tags):
		marked[tags[pair.x]["start"]] = tags[pair.x]
		marked[tags[pair.y]["start"]] = tags[pair.y]
	#Ł Tags before the line's first character, and after its last:
	var cursor := 0
	for tag in tags:
		if tag["start"] != cursor or CHARACTER_TAGS.has(tag["name"]):
			break
		marked[tag["start"]] = tag
		cursor = tag["end"]
	cursor = line_length
	for index in range(tags.size() - 1, -1, -1):
		var tag := tags[index]
		if tag["end"] != cursor or CHARACTER_TAGS.has(tag["name"]):
			break
		marked[tag["start"]] = tag
		cursor = tag["start"]
	return marked


#* Marker text - one character, so a marker is one visible character:
func _marker_text() -> String:
	var stripped := marker_character.strip_edges()
	if stripped.is_empty():
		return DEFAULT_MARKER_CHARACTER
	return stripped.substr(0, 1)


func _fill(styles: PackedInt32Array, from: int, to: int, id: int) -> void:
	for index in range(from, to):
		styles[index] = id


#& Layout

func _ensure_built() -> void:
	if not _needs_build:
		return
	_needs_build = false
	_resolve_look()
	_paras.clear()
	_paras.resize(_lines.size())
	var stack := PackedStringArray()
	for index in _lines.size():
		_build_para(index, stack)
		stack = _paras[index]["end"]
	_place_children()
	_built_width = _text_width()
	_update_tops()
	_caret = _clamp_position(_caret)
	_anchor = _clamp_position(_anchor)
	_settle()


#* Rebuild paragraphs from `first`, as far as the change reaches:
func _restyle_from(first: int, last_changed: int) -> void:
	var stack := PackedStringArray()
	if first > 0:
		stack = _paras[first - 1]["end"]
	var index := first
	while index < _paras.size():
		var para := _paras[index]
		#% Stop at a paragraph after last_changed whose start tags are unchanged:
		if index > last_changed and not para.is_empty() and para["start"] == stack:
			break
		_build_para(index, stack)
		stack = _paras[index]["end"]
		index += 1
	_update_tops()


#* Build one line's paragraph:
func _build_para(index: int, start_stack: PackedStringArray) -> void:
	var line_text := _lines[index]
	var parsed := _parse(line_text, start_stack)
	var styles: PackedInt32Array = parsed["styles"]
	var marked := _marked_tags(parsed["tags"], line_text.length())
	var marker := _marker_text()
	var char_src := PackedInt32Array()
	var char_end := PackedInt32Array()
	var markers: Dictionary = {}
	var vis_of := PackedInt32Array()
	vis_of.resize(line_text.length() + 1)
	var vis_styles := PackedInt32Array()
	var pieces := PackedStringArray()
	var piece_start := -1
	var column := 0
	while column < line_text.length():
		vis_of[column] = char_src.size()
		var is_hidden := hide_tags and styles[column] == TAG_STYLE
		if is_hidden and piece_start >= 0:
			pieces.append(line_text.substr(piece_start, column - piece_start))
			piece_start = -1
		if is_hidden and marked.has(column):
			#? The whole tag is one character; positions inside it are before it.
			var tag: Dictionary = marked[column]
			var tag_end: int = tag["end"]
			markers[char_src.size()] = tag
			pieces.append(marker)
			for inside in range(column + 1, tag_end):
				vis_of[inside] = char_src.size()
			char_src.append(column)
			char_end.append(tag_end)
			vis_styles.append(MARKER_STYLE)
			column = tag_end
			continue
		if is_hidden:
			column += 1
			continue
		if piece_start < 0:
			piece_start = column
		char_src.append(column)
		char_end.append(column + 1)
		vis_styles.append(styles[column])
		column += 1
	if piece_start >= 0:
		pieces.append(line_text.substr(piece_start))
	vis_of[line_text.length()] = char_src.size()
	var vis_text := "".join(pieces)
	#Ł Paragraph ("rows" and "height" added by _layout_para()):
	#? "start" / "end": tags open at its start / end. "styles": per column.
	#? "char_src" / "char_end": columns of each visible character (a marker: its whole tag).
	#? "markers": marker tags by visible index. "vis_of": visible characters before each column.
	var para := {
		"start": start_stack, "end": parsed["end"], "styles": styles, "align": parsed["align"],
		"indent": parsed["indent"], "end_style": parsed["end_style"], "char_src": char_src,
		"char_end": char_end, "markers": markers, "vis_of": vis_of, "vis_text": vis_text,
		"vis_length": vis_text.length(), "vis_styles": vis_styles, "shaped": null,
	}
	if not vis_text.is_empty():
		var shaped := TextParagraph.new()
		shaped.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
		var run_start := 0
		for vis in range(1, vis_text.length() + 1):
			if vis == vis_text.length() or vis_styles[vis] != vis_styles[run_start]:
				var style := _styles[vis_styles[run_start]]
				shaped.add_string(vis_text.substr(run_start, vis - run_start), style["font"], style["size"])
				run_start = vis
		shaped.tab_align(_look["tab_stops"])
		para["shaped"] = shaped
	_paras[index] = para
	_layout_para(para)


#* Break a paragraph into rows at the current width:
func _layout_para(para: Dictionary) -> void:
	var indent_px: float = indent_width * int(para["indent"])
	var width := maxf(20.0, _text_width() - indent_px)
	var align: int = para["align"]
	para["indent_px"] = indent_px
	#Ł Rows - "range" in visible characters, "top" in the paragraph, "x" the alignment offset:
	var rows: Array[Dictionary] = []
	var top := 0.0
	var shaped: TextParagraph = para["shaped"]
	if shaped == null:
		var style := _styles[para["end_style"]]
		var font: Font = style["font"]
		var height: float = font.get_height(style["size"]) + line_spacing
		rows.append({"rid": RID(), "range": Vector2i.ZERO, "top": 0.0, "ascent": font.get_ascent(style["size"]),
			"height": height, "x": _align_offset(align, width, 0.0), "width": 0.0})
		top = height
	else:
		shaped.width = width
		for line_index in shaped.get_line_count():
			var ascent := shaped.get_line_ascent(line_index)
			var height := ascent + shaped.get_line_descent(line_index) + line_spacing
			var line_width := shaped.get_line_width(line_index)
			rows.append({"rid": shaped.get_line_rid(line_index), "range": shaped.get_line_range(line_index),
				"top": top, "ascent": ascent, "height": height, "x": _align_offset(align, width, line_width),
				"width": line_width})
			top += height
	para["rows"] = rows
	para["height"] = top


func _align_offset(align: int, width: float, line_width: float) -> float:
	match align:
		HORIZONTAL_ALIGNMENT_CENTER:
			return maxf(0.0, floorf((width - line_width) / 2.0))
		HORIZONTAL_ALIGNMENT_RIGHT:
			return maxf(0.0, width - line_width)
	return 0.0


#* Re-break every paragraph after a width change (no reshaping):
func _relayout() -> void:
	_built_width = _text_width()
	for para in _paras:
		_layout_para(para)
	_update_tops()


func _update_tops() -> void:
	_para_top.resize(_paras.size())
	var top := 0.0
	for index in _paras.size():
		_para_top[index] = top
		top += float(_paras[index]["height"])
	_content_height = top
	_update_scroll_bar()


func _text_width() -> float:
	return maxf(40.0, size.x - _margin_left - _margin_right - _scroll_bar_width())


func _scroll_bar_width() -> float:
	return _scroll_bar.get_combined_minimum_size().x


#* Place the canvas over the box's content, the scroll bar inside the box on the right:
func _place_children() -> void:
	var width := _scroll_bar_width()
	var inner_height := maxf(0.0, size.y - _margin_top - _margin_bottom)
	_scroll_bar.position = Vector2(size.x - width - _margin_right, _margin_top)
	_scroll_bar.size = Vector2(width, inner_height)
	_canvas.position = Vector2(_margin_left, _margin_top)
	_canvas.size = Vector2(maxf(0.0, size.x - _margin_left - _margin_right), inner_height)


func _update_scroll_bar() -> void:
	_scroll_bar.max_value = _content_height
	_scroll_bar.page = maxf(0.0, size.y - _margin_top - _margin_bottom)
	_scroll_bar.visible = _scroll_bar.max_value > _scroll_bar.page


#* Paragraph at y (from the text's top), clamped to the first / last:
func _para_at(y: float) -> int:
	var low := 0
	var high := _paras.size() - 1
	while low < high:
		var middle := floori((low + high + 1) / 2.0)
		if _para_top[middle] <= y:
			low = middle
		else:
			high = middle - 1
	return low


#* Row holding a visible index (at a break, the next row):
func _row_index(para: Dictionary, vis: int) -> int:
	var rows: Array = para["rows"]
	for index in rows.size():
		var row_range: Vector2i = rows[index]["range"]
		if vis < row_range.y:
			return index
	return rows.size() - 1


#& Positions

#* Visible index of a column (visible characters before it):
func _vis(para: Dictionary, column: int) -> int:
	var vis_of: PackedInt32Array = para["vis_of"]
	return vis_of[clampi(column, 0, vis_of.size() - 1)]


#* Column of a visible index - right after the previous visible character (before hidden tags):
func _src(para: Dictionary, vis: int) -> int:
	if vis <= 0:
		return 0
	var char_end: PackedInt32Array = para["char_end"]
	return char_end[mini(vis, char_end.size()) - 1]


#* Snap a position before hidden tags (with hide_tags):
func _snap(position_value: Vector2i) -> Vector2i:
	if not hide_tags or _paras.is_empty():
		return position_value
	var para := _paras[position_value.y]
	return Vector2i(_src(para, _vis(para, position_value.x)), position_value.y)	#/ Typing there takes the formatting on its left


func _settle() -> void:
	if hide_tags and not _needs_build:
		_caret = _snap(_caret)
		_anchor = _snap(_anchor)


#* Column after the hidden tags at a position (next visible character or line end):
func _cluster_end(position_value: Vector2i) -> Vector2i:
	var para := _paras[position_value.y]
	var vis := _vis(para, position_value.x)
	if vis < int(para["vis_length"]):
		return Vector2i(maxi(position_value.x, para["char_src"][vis]), position_value.y)
	return Vector2i(_lines[position_value.y].length(), position_value.y)


func _clamp_position(position_value: Vector2i) -> Vector2i:
	var line := clampi(position_value.y, 0, _lines.size() - 1)
	return Vector2i(clampi(position_value.x, 0, _lines[line].length()), line)


func _is_before(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)


func _selection_start() -> Vector2i:
	if _is_before(_anchor, _caret):
		return _anchor
	return _caret


func _selection_end() -> Vector2i:
	if _is_before(_anchor, _caret):
		return _caret
	return _anchor


#* Selection end for copying or replacing:
func _selection_end_for_change() -> Vector2i:
	var end := _selection_end()
	#% Hidden tags - after the tags that follow (a word takes its closing tags):
	if hide_tags:
		return _cluster_end(end)
	return end


#* Caret rectangle at a position (x from the control's left, y from the text's top):
func _caret_rect(position_value: Vector2i) -> Rect2:
	_ensure_built()
	var para := _paras[position_value.y]
	var vis := _vis(para, position_value.x)
	var row: Dictionary = para["rows"][_row_index(para, vis)]
	var x: float = row["x"]
	if para["shaped"] != null:
		var carets := _ts.shaped_text_get_carets(row["rid"], vis)
		var rect: Rect2 = carets.get("leading_rect", Rect2())
		if rect.size == Vector2.ZERO:
			rect = carets.get("trailing_rect", Rect2())
		x += rect.position.x
	return Rect2(_margin_left + float(para["indent_px"]) + x, _para_top[position_value.y] + float(row["top"]),
		CARET_WIDTH, row["height"])


#* Position at a point (x from the control's left, y from the text's top):
func _position_at(x: float, y: float) -> Vector2i:
	_ensure_built()
	var index := _para_at(y)
	var para := _paras[index]
	var rows: Array = para["rows"]
	var local_y := y - _para_top[index]
	var row_number := rows.size() - 1
	for row_index in rows.size():
		if local_y < float(rows[row_index]["top"]) + float(rows[row_index]["height"]):
			row_number = row_index
			break
	if para["shaped"] == null:
		return Vector2i(0, index)
	var row: Dictionary = rows[row_number]
	var row_range: Vector2i = row["range"]
	var vis := _ts.shaped_text_hit_test_position(row["rid"],
		x - _margin_left - float(para["indent_px"]) - float(row["x"]))
	vis = clampi(vis, row_range.x, row_range.y)
	#% Row break - its end is the next row's start, keep the caret before it:
	if row_number < rows.size() - 1 and vis >= row_range.y:
		vis = maxi(row_range.x, row_range.y - 1)
	return Vector2i(_src(para, vis), index)


func _position_at_point(point: Vector2) -> Vector2i:
	return _position_at(point.x, point.y - _margin_top + _scroll_bar.value)


func _line_end(line_index: int) -> Vector2i:
	return Vector2i(_src_end(_paras[line_index], line_index), line_index)


#* Column where a line's visible text ends (before trailing hidden tags):
func _src_end(para: Dictionary, line_index: int) -> int:
	if not hide_tags:
		return _lines[line_index].length()
	return _src(para, para["vis_length"])


func _text_end() -> Vector2i:
	return _line_end(_lines.size() - 1)


func _char_left(position_value: Vector2i) -> Vector2i:
	var para := _paras[position_value.y]
	var vis := _vis(para, position_value.x)
	if vis > 0:
		return Vector2i(_src(para, vis - 1), position_value.y)
	if position_value.y > 0:
		return _line_end(position_value.y - 1)
	return Vector2i.ZERO


func _char_right(position_value: Vector2i) -> Vector2i:
	var para := _paras[position_value.y]
	var vis := _vis(para, position_value.x)
	if vis < int(para["vis_length"]):
		return Vector2i(_src(para, vis + 1), position_value.y)
	if position_value.y < _lines.size() - 1:
		return Vector2i(0, position_value.y + 1)
	return _line_end(position_value.y)


#* Character class - 0 = space, 1 = word (letters, digits, _), 2 = other:
func _char_class(character: String) -> int:
	if character == " " or character == "\t":
		return 0
	if character == "_" or character.is_valid_int() or character.to_upper() != character.to_lower():
		return 1
	return 2		#/ Moving by word stops at a tag's brackets


func _word_left(position_value: Vector2i) -> Vector2i:
	var para := _paras[position_value.y]
	var vis := _vis(para, position_value.x)
	if vis == 0:
		return _char_left(position_value)
	var line: String = para["vis_text"]
	while vis > 0 and _char_class(line[vis - 1]) == 0:
		vis -= 1
	if vis > 0:
		var kind := _char_class(line[vis - 1])
		while vis > 0 and _char_class(line[vis - 1]) == kind:
			vis -= 1
	return Vector2i(_src(para, vis), position_value.y)


func _word_right(position_value: Vector2i) -> Vector2i:
	var para := _paras[position_value.y]
	var vis := _vis(para, position_value.x)
	var line: String = para["vis_text"]
	if vis >= line.length():
		return _char_right(position_value)
	while vis < line.length() and _char_class(line[vis]) == 0:
		vis += 1
	if vis < line.length():
		var kind := _char_class(line[vis])
		while vis < line.length() and _char_class(line[vis]) == kind:
			vis += 1
	return Vector2i(_src(para, vis), position_value.y)


#* Word (or run of spaces or other characters) at a position:
func _word_bounds(position_value: Vector2i) -> Array[Vector2i]:
	var para := _paras[position_value.y]
	var line: String = para["vis_text"]
	if line.is_empty():
		return [position_value, position_value]
	var vis := mini(_vis(para, position_value.x), line.length() - 1)
	var kind := _char_class(line[vis])
	var start := vis
	var end := vis + 1
	while start > 0 and _char_class(line[start - 1]) == kind:
		start -= 1
	while end < line.length() and _char_class(line[end]) == kind:
		end += 1
	return [Vector2i(_src(para, start), position_value.y), Vector2i(_src(para, end), position_value.y)]


func _row_start(position_value: Vector2i) -> Vector2i:
	_ensure_built()
	var para := _paras[position_value.y]
	var row_range: Vector2i = para["rows"][_row_index(para, _vis(para, position_value.x))]["range"]
	return Vector2i(_src(para, row_range.x), position_value.y)


func _row_end(position_value: Vector2i) -> Vector2i:
	_ensure_built()
	var para := _paras[position_value.y]
	var rows: Array = para["rows"]
	var row_number := _row_index(para, _vis(para, position_value.x))
	var row_range: Vector2i = rows[row_number]["range"]
	if row_number == rows.size() - 1:
		return _line_end(position_value.y)
	return Vector2i(_src(para, maxi(row_range.x, row_range.y - 1)), position_value.y)


#* Move rows up (negative) or down, keeping the caret's x:
func _move_vertical(rows_delta: int, extend: bool) -> void:
	_ensure_built()
	var rect := _caret_rect(_caret)
	if _wanted_x < 0.0:
		_wanted_x = rect.position.x
	var index := _caret.y
	var row_number := _row_index(_paras[index], _vis(_paras[index], _caret.x))
	var steps := absi(rows_delta)
	var moved := 0
	while moved < steps:
		if rows_delta < 0:
			if row_number > 0:
				row_number -= 1
			elif index > 0:
				index -= 1
				row_number = (_paras[index]["rows"] as Array).size() - 1
			else:
				break
		else:
			if row_number < (_paras[index]["rows"] as Array).size() - 1:
				row_number += 1
			elif index < _paras.size() - 1:
				index += 1
				row_number = 0
			else:
				break
		moved += 1
	#% Past the first or last row - to the text's start or end:
	if moved == 0:
		if rows_delta < 0:
			_move_caret(Vector2i.ZERO, extend)
		else:
			_move_caret(_text_end(), extend)
		return
	var row: Dictionary = _paras[index]["rows"][row_number]
	var target := _position_at(_wanted_x, _para_top[index] + float(row["top"]) + float(row["height"]) / 2.0)
	_move_caret(target, extend, true)


func _move_caret(target: Vector2i, extend: bool, keep_x := false) -> void:
	_caret = target
	if not extend:
		_anchor = target
	if not keep_x:
		_wanted_x = -1.0
	_caret_moved()


func _caret_moved() -> void:
	_scroll_to_caret()
	_restart_blink()
	_redraw()
	_queue_popup_update()
	caret_changed.emit()


func _scroll_to_caret() -> void:
	var rect := _caret_rect(_caret)
	var view_height := size.y - _margin_top - _margin_bottom
	var scroll := _scroll_bar.value
	if rect.position.y < scroll:
		scroll = rect.position.y
	elif rect.end.y > scroll + view_height:
		scroll = rect.end.y - view_height
	_scroll_bar.value = scroll


func _row_height() -> float:
	_ensure_built()
	var font: Font = _look["fonts"]["normal"]
	return font.get_height(_look["size"]) + line_spacing


#& Focus

#* Editor lost the focus - left unless it went to the popup:
func _on_focus_exited() -> void:
	if not _focus_stays_inside():
		focus_left.emit()


#* Popup lost the focus:
func _on_popup_focus_exited() -> void:
	#Ł Write its changes first (TextEdit reports them at frame end):
	_apply_popup_text()
	_popup_editing = false
	_queue_popup_update()
	if not _focus_stays_inside():
		focus_left.emit()


#* Whether the focus only moves between the editor and its popup:
func _focus_stays_inside() -> bool:
	#% The editor moving it:
	if _moving_focus:
		return true
	if not is_inside_tree():
		return false
	#% A click inside either:
	var mouse_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if not mouse_down:
		return false
	var mouse := get_global_mouse_position()
	return get_global_rect().has_point(mouse) or (_popup.visible and _popup.get_global_rect().has_point(mouse))


#* Take the focus back from the popup:
func _return_focus() -> void:
	_moving_focus = true
	grab_focus()
	_moving_focus = false


#& Popup

#* Tag group around a position (what the popup shows), [from, to] or []:
func _group_at(position_value: Vector2i) -> Array:
	for group in _text_groups():
		#% Group edges count as inside:
		if not _is_before(position_value, group[0]) and not _is_before(group[1], position_value):
			return group
	return []


#* Every tag group of the text, in order - [from, to]:
func _text_groups() -> Array:
	if not _groups_dirty:
		return _groups
	_groups_dirty = false
	var tags := _all_tags()
	var partners := _partners(tags)
	var spans: Array = []
	#@ Step 1 - A pair spans to its partner, on any lines; an unpaired or standalone tag is alone:
	for index in tags.size():
		if not partners.has(index):
			spans.append([tags[index]["from"], tags[index]["to"]])
		elif partners[index] > index:
			spans.append([tags[index]["from"], tags[partners[index]]["to"]])
	spans.sort_custom(func(a: Array, b: Array) -> bool: return _is_before(a[0], b[0]))
	_groups = []
	#@ Step 2 - Merge spans that touch (the outermost pair takes those inside):
	for span in spans:
		if not _groups.is_empty() and not _is_before(_groups[_groups.size() - 1][1], span[0]):
			var last: Array = _groups[_groups.size() - 1]
			if _is_before(last[1], span[1]):
				last[1] = span[1]
		else:
			_groups.append([span[0], span[1]])
	return _groups


#* Every tag of the text (_line_tags()), with "from" and "to" positions:
func _all_tags() -> Array[Dictionary]:
	var tags: Array[Dictionary] = []
	for line_index in _lines.size():
		for tag in _line_tags(_lines[line_index]):
			tag["from"] = Vector2i(tag["start"], line_index)
			tag["to"] = Vector2i(tag["end"], line_index)
			tags.append(tag)
	return tags


#* Paired tags - { index = partner's index }, both ways, on any lines:
func _partners(tags: Array[Dictionary]) -> Dictionary:
	var partners: Dictionary = {}
	var open: Array[int] = []
	for index in tags.size():
		var tag := tags[index]
		if tag["closing"]:
			for open_index in range(open.size() - 1, -1, -1):
				if tags[open[open_index]]["name"] == tag["name"]:
					partners[open[open_index]] = index
					partners[index] = open[open_index]
					open.remove_at(open_index)
					break
		elif not STANDALONE_TAGS.has(tag["name"]):
			open.append(index)
	return partners


func _queue_popup_update() -> void:
	if _popup_queued or _popup == null:
		return
	_popup_queued = true
	_update_popup.call_deferred()


#* Show the popup over the tag group at the caret, or hide it:
func _update_popup() -> void:
	_popup_queued = false
	if not is_inside_tree():
		return
	_ensure_built()
	if not _popup_editing:
		_popup_shown = false
		if hide_tags and has_focus() and not has_selection():
			var group := _group_at(_caret)
			if not group.is_empty():
				_popup_from = group[0]
				_popup_to = group[1]
				_popup_shown = true
		if not _popup_shown:
			if _popup.visible:
				_popup.visible = false
				_redraw()
			return
		var group_text := _get_range(_popup_from, _popup_to)
		if _popup_edit.text != group_text:
			_popup_edit.text = group_text
	_place_popup()
	_redraw()


#* Place the popup above the group (below if no room), inside the window:
func _place_popup() -> void:
	var font := _popup_edit.get_theme_font(&"font")
	var font_size := _popup_edit.get_theme_font_size(&"font_size")
	var text_width := 0.0
	for popup_line in _popup_edit.text.split("\n"):
		text_width = maxf(text_width, font.get_string_size(popup_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var panel_box := _popup.get_theme_stylebox(&"panel")
	var panel_width := panel_box.get_minimum_size().x
	var edit_padding := _popup_edit.get_theme_stylebox(&"normal").get_minimum_size().x
	var view := get_viewport_rect()
	#Ł As wide as its longest line, up to the editor's width:
	var room := clampf(size.x - _scroll_bar_width() - 4.0, 60.0, maxf(60.0, view.size.x))
	var width := minf(room, text_width + edit_padding + panel_width + POPUP_CARET_ROOM)
	_popup_edit.custom_minimum_size = Vector2(maxf(0.0, width - panel_width), 0.0)
	var height := _popup.get_combined_minimum_size().y
	var start := _caret_rect(_popup_from)
	var end := _caret_rect(_popup_to)
	var scroll := _scroll_bar.value
	var group_top := start.position.y + _margin_top - scroll
	var group_bottom := end.end.y + _margin_top - scroll
	if not _popup_editing and (group_bottom < 0.0 or group_top > size.y):
		_popup.visible = false
		return
	#Ł top_level - placed in the canvas, not in the editor:
	var origin := get_global_position()
	var y := origin.y + group_top - height - POPUP_GAP
	if y < view.position.y:
		y = origin.y + group_bottom + POPUP_GAP
	y = clampf(y, view.position.y, maxf(view.position.y, view.end.y - height))
	var x := clampf(origin.x + start.position.x - panel_box.get_margin(SIDE_LEFT), view.position.x,
		maxf(view.position.x, view.end.x - width))
	_popup.position = Vector2(x, y)
	_popup.size = Vector2(width, height)
	_popup.visible = true


#* Give the popup's field the focus, its caret where the editor's was:
func edit_tags() -> bool:
	if not has_focus():
		return false
	_update_popup()
	if not _popup.visible:
		return false		#/ No popup (no tags at the caret, or tags not hidden)
	_moving_focus = true
	_popup_edit.grab_focus()
	_moving_focus = false
	var line := clampi(_caret.y - _popup_from.y, 0, _popup_edit.get_line_count() - 1)
	var column := _caret.x
	if _caret.y == _popup_from.y:
		column = _caret.x - _popup_from.x
	_popup_edit.set_caret_line(line)
	_popup_edit.set_caret_column(clampi(column, 0, _popup_edit.get_line(line).length()))
	return true


#* Take the focus back from the popup's field, keeping its changes:
func leave_tags() -> void:
	_leave_popup()


#* Take the focus back before the text changes another way (undo, redo, new text):
func _leave_popup() -> void:
	if _popup_edit != null and _popup_edit.has_focus():
		_return_focus()		#/ The group may move: the popup finds it again


func _on_popup_focus_entered() -> void:
	_popup_editing = true
	_popup_session += 1
	_popup_original = _popup_edit.text
	_popup_caret = _caret
	_redraw()


#* Write the field's text over the group (one undo step per session):
func _apply_popup_text() -> void:
	#! Only while edited: TextEdit also reports text set by the editor, a frame late:
	if not _popup_editing or not _popup_shown or not editable:
		return
	var new_text := _popup_edit.text
	_edit(_popup_from, _popup_to, new_text, "popup")
	_popup_to = _end_of(_popup_from, new_text)
	var caret := _popup_caret
	if _is_before(caret, _popup_from):
		caret = _popup_from
	if _is_before(_popup_to, caret):
		caret = _popup_to
	_caret = _snap(_clamp_position(caret))
	_anchor = _caret
	if _undo_index > 0 and _undo[_undo_index - 1]["kind"] == "popup":
		_undo[_undo_index - 1]["caret_after"] = _caret
	_redraw()


#* Escape - restore the group, drop its undo step, return the focus:
func _on_popup_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var key := event as InputEventKey
	if key.is_action_pressed("ui_cancel"):
		if _popup_edit.text != _popup_original:
			_popup_edit.text = _popup_original
			_apply_popup_text()
			var last := _undo_index - 1
			if last >= 0 and _undo[last]["kind"] == "popup" and _undo[last]["session"] == _popup_session \
					and _undo[last]["inserted"] == _undo[last]["removed"]:
				_undo.remove_at(last)
				_undo_index = last
				text_changed.emit()
		_popup_edit.accept_event()
		_return_focus()


#& Input

func _gui_input(event: InputEvent) -> void:
	_ensure_built()
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed:
			match button.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					_scroll_bar.value -= _row_height() * WHEEL_ROWS * maxf(button.factor, 0.1)
					accept_event()
				MOUSE_BUTTON_WHEEL_DOWN:
					_scroll_bar.value += _row_height() * WHEEL_ROWS * maxf(button.factor, 0.1)
					accept_event()
				MOUSE_BUTTON_LEFT:
					_on_left_press(button)
					accept_event()
				MOUSE_BUTTON_RIGHT:
					_open_menu(button.position)
					accept_event()
		elif button.button_index == MOUSE_BUTTON_LEFT:
			_dragging = false
			set_process(false)
	elif event is InputEventMouseMotion and _dragging:
		_drag_to(event.position)
	elif event is InputEventKey and event.pressed:
		if _on_key(event):
			accept_event()


func _process(delta: float) -> void:
	if not _dragging or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_dragging = false
		set_process(false)
		return
	#Ł Dragging past the top or bottom scrolls, faster further away:
	var mouse := get_local_mouse_position()
	if mouse.y < 0.0:
		_scroll_bar.value += mouse.y * delta * 10.0
		_drag_to(mouse)
	elif mouse.y > size.y:
		_scroll_bar.value += (mouse.y - size.y) * delta * 10.0
		_drag_to(mouse)


func _on_left_press(button: InputEventMouseButton) -> void:
	grab_focus()
	var target := _position_at_point(button.position)
	var now := Time.get_ticks_msec()
	if now - _last_click_ms < MULTI_CLICK_MS and button.position.distance_to(_last_click_position) < 6.0:
		_click_count += 1
	else:
		_click_count = 1
	_last_click_ms = now
	_last_click_position = button.position
	if _click_count == 2:
		var bounds := _word_bounds(target)
		_anchor = bounds[0]
		_move_caret(bounds[1], true)
		return
	if _click_count >= 3:
		_anchor = Vector2i(0, target.y)
		_move_caret(_line_end(target.y), true)
		return
	_move_caret(target, button.shift_pressed)
	_dragging = true
	set_process(true)


func _drag_to(point: Vector2) -> void:
	var target := _position_at_point(point)
	if target != _caret:
		_move_caret(target, true)


#* Handle a key, through ui_text_* actions (platform keys):
func _on_key(key: InputEventKey) -> bool:
	if _is(key, "ui_redo", true):
		redo()
		return true
	if _is(key, "ui_undo", true):
		undo()
		return true
	if _is(key, "ui_copy", true):
		copy()
		return true
	if _is(key, "ui_cut", true):
		cut()
		return true
	if _is(key, "ui_paste", true):
		paste()
		return true
	if _is(key, "ui_text_select_all", true):
		select_all()
		return true
	if _is(key, "ui_text_backspace_word"):
		_backspace(true)
		return true
	if _is(key, "ui_text_backspace"):
		_backspace(false)
		return true
	if _is(key, "ui_text_delete_word"):
		_delete(true)
		return true
	if _is(key, "ui_text_delete"):
		_delete(false)
		return true
	if _is(key, "ui_text_newline") or _is(key, "ui_text_newline_blank") or _is(key, "ui_text_newline_above"):
		_insert("\n", "")
		return true
	if _is(key, "ui_text_indent", true):
		_insert("\t", "type")
		return true
	if _is(key, "ui_text_dedent"):
		return true
	var extend := key.shift_pressed
	if _is(key, "ui_text_scroll_up"):
		_scroll_bar.value -= _row_height()
		return true
	if _is(key, "ui_text_scroll_down"):
		_scroll_bar.value += _row_height()
		return true
	if _is(key, "ui_text_caret_document_start"):
		_move_caret(Vector2i.ZERO, extend)
		return true
	if _is(key, "ui_text_caret_document_end"):
		_move_caret(_text_end(), extend)
		return true
	if _is(key, "ui_text_caret_word_left"):
		_move_caret(_word_left(_caret), extend)
		return true
	if _is(key, "ui_text_caret_word_right"):
		_move_caret(_word_right(_caret), extend)
		return true
	if _is(key, "ui_text_caret_line_start"):
		_move_caret(_row_start(_caret), extend)
		return true
	if _is(key, "ui_text_caret_line_end"):
		_move_caret(_row_end(_caret), extend)
		return true
	if _is(key, "ui_text_caret_left"):
		if has_selection() and not extend:
			_move_caret(_selection_start(), false)
		else:
			_move_caret(_char_left(_caret), extend)
		return true
	if _is(key, "ui_text_caret_right"):
		if has_selection() and not extend:
			_move_caret(_selection_end(), false)
		else:
			_move_caret(_char_right(_caret), extend)
		return true
	if _is(key, "ui_text_caret_up"):
		_move_vertical(-1, extend)
		return true
	if _is(key, "ui_text_caret_down"):
		_move_vertical(1, extend)
		return true
	if _is(key, "ui_text_caret_page_up"):
		_move_vertical(-_page_rows(), extend)
		return true
	if _is(key, "ui_text_caret_page_down"):
		_move_vertical(_page_rows(), extend)
		return true
	if key.unicode >= 32 and not key.is_command_or_control_pressed():
		_insert(char(key.unicode), "type")
		return true
	return false		#/ Key not used


func _is(key: InputEventKey, action: StringName, exact := false) -> bool:
	return InputMap.has_action(action) and key.is_action_pressed(action, true, exact)


func _page_rows() -> int:
	return maxi(1, int((size.y - _margin_top - _margin_bottom) / _row_height()) - 1)


func _open_menu(point: Vector2) -> void:
	grab_focus()
	var target := _position_at_point(point)
	var inside := has_selection() and not _is_before(target, _selection_start()) and _is_before(target, _selection_end())
	if not inside:
		_move_caret(target, false)
	_menu.set_item_disabled(_menu.get_item_index(MenuItem.UNDO), _undo_index == 0 or not editable)
	_menu.set_item_disabled(_menu.get_item_index(MenuItem.REDO), _undo_index >= _undo.size() or not editable)
	_menu.set_item_disabled(_menu.get_item_index(MenuItem.CUT), not has_selection() or not editable)
	_menu.set_item_disabled(_menu.get_item_index(MenuItem.COPY), not has_selection())
	_menu.set_item_disabled(_menu.get_item_index(MenuItem.PASTE), not editable)
	for item in MENU_ACTIONS:
		_menu.set_item_accelerator(_menu.get_item_index(item), _action_key(MENU_ACTIONS[item]))
	_menu.reset_size()
	_menu.popup(Rect2i(Vector2i(get_screen_position() + point), Vector2i.ZERO))


#* First key of an action, with modifiers (KEY_NONE for none):
func _action_key(action: StringName) -> Key:
	if not InputMap.has_action(action):
		return KEY_NONE
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key == null:
			continue
		if key.keycode != KEY_NONE:
			return key.get_keycode_with_modifiers()
		return key.get_physical_keycode_with_modifiers()
	return KEY_NONE


func _on_menu_pressed(id: int) -> void:
	match id:
		MenuItem.UNDO:
			undo()
		MenuItem.REDO:
			redo()
		MenuItem.CUT:
			cut()
		MenuItem.COPY:
			copy()
		MenuItem.PASTE:
			paste()
		MenuItem.SELECT_ALL:
			select_all()


func _blink() -> void:
	_caret_shown = not _caret_shown
	_canvas.queue_redraw()


func _restart_blink() -> void:
	_caret_shown = true
	if is_inside_tree() and has_focus():
		_blink_timer.start()


#& Drawing

#* Draw the box, and its focus outline (the canvas draws the text):
func _draw() -> void:
	_ensure_built()
	draw_style_box(_box(), Rect2(Vector2.ZERO, size))
	if has_focus_within():
		draw_style_box(_theme_stylebox(&"focus"), Rect2(Vector2.ZERO, size))


#* Draw the text on the canvas, in the editor's coordinates:
func _draw_text() -> void:
	_ensure_built()
	#Ł Editor's coordinates (the canvas only clips to the box's content):
	_canvas.draw_set_transform(-_canvas.position)
	var scroll := _scroll_bar.value
	var origin_y := _margin_top - scroll
	var bottom := scroll - _margin_top + size.y
	var selecting := has_selection()
	var selection_from := _selection_start()
	var selection_to := _selection_end()
	var marking := _popup.visible and _popup_shown
	if _lines.size() == 1 and _lines[0].is_empty() and not placeholder_text.is_empty():
		_draw_placeholder(origin_y)
	for index in range(_para_at(maxf(0.0, scroll - _margin_top)), _paras.size()):
		if _para_top[index] > bottom:
			break
		var para := _paras[index]
		var origin := Vector2(_margin_left + float(para["indent_px"]), origin_y + _para_top[index])
		if marking and index >= _popup_from.y and index <= _popup_to.y:
			_draw_range(index, origin, _popup_from, _popup_to, _look["popup_mark_color"])
		if selecting and index >= selection_from.y and index <= selection_to.y:
			_draw_range(index, origin, selection_from, selection_to, _look["selection_color"])
		if para["shaped"] != null:
			_draw_para(para, origin)
	if has_focus() and _caret_shown and editable:
		var rect := _caret_rect(_caret)
		rect.position.y += origin_y
		_canvas.draw_rect(rect, _look["caret_color"])


func _draw_placeholder(origin_y: float) -> void:
	var font: Font = _look["fonts"]["normal"]
	var font_size: int = _look["size"]
	_canvas.draw_multiline_string(font, Vector2(_margin_left, origin_y + font.get_ascent(font_size)), placeholder_text,
		HORIZONTAL_ALIGNMENT_LEFT, _text_width(), font_size, -1, _look["placeholder_color"])


#* Draw a background between two positions (selection or popup group):
func _draw_range(index: int, origin: Vector2, from: Vector2i, to: Vector2i, color: Color) -> void:
	var para := _paras[index]
	var start := 0
	if index == from.y:
		start = _vis(para, from.x)
	var end: int = para["vis_length"]
	if index == to.y:
		end = _vis(para, to.x)
	var rows: Array = para["rows"]
	for row_number in rows.size():
		var row: Dictionary = rows[row_number]
		var row_origin := origin + Vector2(row["x"], row["top"])
		var row_range: Vector2i = row["range"]
		var first := maxi(start, row_range.x)
		var last := mini(end, row_range.y)
		if para["shaped"] != null and last > first:
			for span in _ts.shaped_text_get_selection(row["rid"], first, last):
				_canvas.draw_rect(Rect2(row_origin.x + span.x, row_origin.y, span.y - span.x, row["height"]), color)
		#% The line break shows as a space after the line:
		if index < to.y and row_number == rows.size() - 1:
			_canvas.draw_rect(Rect2(row_origin.x + float(row["width"]), row_origin.y, _look["space_width"],
				row["height"]), color)


#* Draw a paragraph glyph by glyph, in each character's color:
func _draw_para(para: Dictionary, origin: Vector2) -> void:
	var styles: PackedInt32Array = para["vis_styles"]
	var last_style := styles.size() - 1
	var canvas_item := _canvas.get_canvas_item()
	for row: Dictionary in para["rows"]:
		var row_origin := origin + Vector2(row["x"], row["top"])
		var baseline := row_origin.y + float(row["ascent"])
		var glyphs := _ts.shaped_text_get_glyphs(row["rid"])
		var x := row_origin.x
		#Ł Glyph by glyph (a TextParagraph draws in one color only):
		for glyph: Dictionary in glyphs:
			var advance: float = float(glyph["advance"]) * int(glyph["repeat"])
			var style := _styles[styles[clampi(int(glyph["start"]), 0, last_style)]]
			var background: Color = style["background"]
			if background.a > 0.0:
				_canvas.draw_rect(Rect2(x, row_origin.y, advance, row["height"]), background)
			x += advance
		x = row_origin.x
		for glyph: Dictionary in glyphs:
			var style := _styles[styles[clampi(int(glyph["start"]), 0, last_style)]]
			var color: Color = style["color"]
			var font_rid: RID = glyph["font_rid"]
			var glyph_size: int = glyph["font_size"]
			var glyph_advance: float = glyph["advance"]
			for _repeat in int(glyph["repeat"]):
				var glyph_position := Vector2(x, baseline) + (glyph["offset"] as Vector2)
				if font_rid.is_valid():
					_ts.font_draw_glyph(font_rid, canvas_item, glyph_size, glyph_position, glyph["index"], color)
				elif (int(glyph["flags"]) & TextServer.GRAPHEME_IS_VIRTUAL) == 0:
					_ts.draw_hex_code_box(canvas_item, glyph_size, glyph_position, glyph["index"], color)
				if font_rid.is_valid() and (style["underline"] or style["strike"]):
					var thickness := maxf(1.0, _ts.font_get_underline_thickness(font_rid, glyph_size))
					if style["underline"]:
						var under_y := baseline + _ts.font_get_underline_position(font_rid, glyph_size)
						_canvas.draw_line(Vector2(x, under_y), Vector2(x + glyph_advance, under_y), color, thickness)
					if style["strike"]:
						var strike_y := baseline - _ts.font_get_ascent(font_rid, glyph_size) * 0.3
						_canvas.draw_line(Vector2(x, strike_y), Vector2(x + glyph_advance, strike_y), color, thickness)
				x += glyph_advance
