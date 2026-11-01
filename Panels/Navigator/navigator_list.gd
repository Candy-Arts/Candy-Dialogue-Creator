#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyNavigatorList
extends Control

signal fold_toggled(path: Array)
#^ path - the row right-clicked ([] under the last row):
signal context_menu_requested(screen_position: Vector2i, path: Array)

const DRAG_SOURCE := "candy_navigator"
const SEPARATION := 4.0
const OVERSCAN := 3
const INDICATOR_HEIGHT := 3.0
const AUTOSCROLL_MARGIN := 28.0
const AUTOSCROLL_SPEED := 700.0
#^ When the theme doesn't set CandyNavigator's scrollbar_gap:
const DEFAULT_SCROLLBAR_GAP := 6

#^ Set by the panel, needed for the visible range and auto-scrolling:
var scroll: ScrollContainer: set = _set_scroll
#^ Set by the panel - the view it selects in:
var reference: String = CandyDialogue.DEFAULT_REFERENCE

var _rows: Array = []
var _total_height: float = 0.0
var _active: Dictionary = {}          #/ row index -> CandyNavigatorRow
var _pool: Array[CandyNavigatorRow] = []
var _font: Font

var _anchor: int = -1
#^ Row waiting for mouse-up to become the only selection:
#? So clicking a selected row doesn't collapse a multi-row drag before it starts.
var _pending_click: int = -1
#^ The row the keyboard selected last (see step_selection()):
var _keyboard_index: int = -1
var _drop: Dictionary = {}
var _scroll_remainder: float = 0.0
var _hover_index: int = -1
var _pressed_index: int = -1
#^ The widest frame of any row, set by set_rows():
var _frame_room: float = 0.0


func _ready() -> void:
	clip_contents = true
	#? Clicking takes the focus (shortcuts), committing a field being typed in.
	focus_mode = Control.FOCUS_CLICK
	set_process(false)


#* Set the rows to show:
func set_rows(rows: Array) -> void:
	_rows = rows
	_font = get_theme_font("font", "Label")

	#Ł Room for each row's frame: above the first, below the last, left of every row, and between rows beyond SEPARATION:
	var y := 0.0
	var previous_frame := 0.0
	_frame_room = 0.0
	for i in _rows.size():
		var row: Dictionary = _rows[i]
		var frame := float(CandyNavigatorRow.frame_width(row))
		row["height"] = CandyNavigatorRow.row_height(_font, int(row["font_size"]))
		if i == 0:
			y = frame
		else:
			y += SEPARATION + _extra_frame_room(previous_frame) + _extra_frame_room(frame)
		row["y"] = y
		y += float(row["height"])
		previous_frame = frame
		_frame_room = maxf(_frame_room, frame)
	_total_height = y + previous_frame
	custom_minimum_size.y = _total_height

	for index in _active.keys():
		_release(index)
	_update_visible()


#* Room a frame needs between rows beyond SEPARATION:
func _extra_frame_room(frame: float) -> float:
	return maxf(0.0, frame - float(CandyNavigatorColors.FRAME_WIDTH))


#* Repaint one row in place, for edits that don't change the structure:
func refresh_row(path: Array, text: String, states: Dictionary = {}) -> void:
	for i in _rows.size():
		if _rows[i]["path"] == path:
			_rows[i]["text"] = text
			#? states replaces the row's colors.
			if not states.is_empty():
				_rows[i]["states"] = states
			if _active.has(i):
				_active[i].update_row(_rows[i], _font)
			return


func update_selection() -> void:
	for index in _active:
		_active[index].set_state(_row_state(index))


func _row_state(index: int) -> String:
	var path: Array = _rows[index]["path"]
	if index == _pressed_index:
		return "pressed"
	if CandyDialogue.is_selected(path, reference):
		if path == _primary_path():
			return "selected"
		return "secondary"
	if index == _hover_index:
		return "hover"
	return "normal"


#* Path of the row shown as "selected":
func _primary_path() -> Array:
	var active := CandyDialogue.active_path_of(reference)
	if CandyDialogue.is_selected(active, reference):
		return active
	#Ł Else the conversation or block selected last (Test Here's too):
	var selected := CandyDialogue.selection_of(reference)
	for i in range(selected.size() - 1, -1, -1):
		var path: Array = selected[i]
		if not CandyDialogue.is_line_path(path):
			return path
	return []


#* Repaint the rows whose state depends on the mouse:
func _set_pointer(hover_index: int, pressed_index: int) -> void:
	if hover_index == _hover_index and pressed_index == _pressed_index:
		return
	var changed := [_hover_index, _pressed_index, hover_index, pressed_index]
	_hover_index = hover_index
	_pressed_index = pressed_index
	for index in changed:
		if _active.has(index):
			_active[index].set_state(_row_state(index))


#& Virtualization

func _set_scroll(value: ScrollContainer) -> void:
	if scroll != null and is_instance_valid(scroll):
		scroll.get_v_scroll_bar().value_changed.disconnect(_on_scrolled)
		scroll.resized.disconnect(_update_visible)
	scroll = value
	if scroll != null:
		scroll.get_v_scroll_bar().value_changed.connect(_on_scrolled)
		scroll.resized.connect(_update_visible)


func _on_scrolled(_value: float) -> void:
	_update_visible()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_update_visible()
		NOTIFICATION_DRAG_END:
			_clear_drop()
			_set_pointer(_hover_index, -1)
		NOTIFICATION_MOUSE_EXIT:
			_set_pointer(-1, _pressed_index)


func _update_visible() -> void:
	if _rows.is_empty() or not is_inside_tree():
		return

	var top := 0.0
	var bottom := size.y
	if scroll != null:
		top = float(scroll.scroll_vertical)
		bottom = top + scroll.size.y

	var first := maxi(0, _index_at(top) - OVERSCAN)
	var last := mini(_rows.size() - 1, _index_at(bottom) + OVERSCAN)

	for index in _active.keys():
		if index < first or index > last:
			_release(index)

	for index in range(first, last + 1):
		var node: CandyNavigatorRow = _active.get(index)
		if node == null:
			if not _pool.is_empty():
				node = _pool.pop_back()
			if node == null:
				node = CandyNavigatorRow.new()
				add_child(node)
			node.visible = true
			_active[index] = node
		var row: Dictionary = _rows[index]
		node.update_row(row, _font)
		var indent := CandyNavigatorRow.row_indent(int(row["depth"]))
		node.position = Vector2(_row_x() + indent, row["y"])
		node.size = Vector2(maxf(0.0, _row_width() - indent), row["height"])
		node.set_state(_row_state(index))


#* Rows' left edge: the widest frame's width, so frames aren't clipped:
func _row_x() -> float:
	return _frame_room


#* Rows' width: short of the scrollbar gap on the right, and the frame room on the left:
func _row_width() -> float:
	var gap := DEFAULT_SCROLLBAR_GAP
	if has_theme_constant(&"scrollbar_gap", CandyThemeDefaults.NAVIGATOR):
		gap = get_theme_constant(&"scrollbar_gap", CandyThemeDefaults.NAVIGATOR)
	return maxf(0.0, size.x - float(gap) - _row_x())


func _release(index: int) -> void:
	var node: CandyNavigatorRow = _active.get(index)
	if node == null:
		return
	node.visible = false
	_active.erase(index)
	_pool.append(node)


#& Pointer input

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_pointer(_row_at(event.position.y), _pressed_index)
		return
	if not (event is InputEventMouseButton):
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		var under := _row_at(event.position.y)
		if event.pressed:
			_set_pointer(under, under)
		else:
			_set_pointer(under, -1)

	if event.pressed:
		var index := _row_at(event.position.y)
		CandyDialogue.use_reference(reference)

		if event.button_index == MOUSE_BUTTON_LEFT:
			if index >= 0 and _hits_fold_arrow(index, event.position.x):
				fold_toggled.emit(_rows[index]["path"])
				accept_event()
				return

			var ctrl: bool = event.ctrl_pressed or event.meta_pressed
			if index < 0:
				CandyDialogue.set_selection([])
			elif not ctrl and not event.shift_pressed and CandyDialogue.is_selected(_rows[index]["path"], reference):
				#% Maybe a drag of the whole selection - decide on release. The editor follows now:
				_pending_click = index
				_set_active(_rows[index]["path"])
			else:
				_click_row(index, event.shift_pressed, ctrl)
			accept_event()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if index >= 0 and not CandyDialogue.is_selected(_rows[index]["path"], reference):
				_click_row(index, false, false)
			var path: Array = []
			if index >= 0:
				path = _rows[index]["path"]
			context_menu_requested.emit(Vector2i(get_screen_position() + event.position), path)
			accept_event()

	elif event.button_index == MOUSE_BUTTON_LEFT and _pending_click >= 0:
		#% Released without dragging - select only the clicked row:
		var index := _pending_click
		_pending_click = -1
		CandyDialogue.use_reference(reference)
		if index < _rows.size():
			_click_row(index, false, false)
		accept_event()


func _click_row(index: int, shift: bool, ctrl: bool) -> void:
	var path: Array = _rows[index]["path"]
	_keyboard_index = index

	if shift and _anchor >= 0 and _anchor < _rows.size():
		#% Range, across blocks and conversations too (operations use the most granular kind):
		var from := mini(_anchor, index)
		var to := maxi(_anchor, index)
		var paths: Array = []
		for i in range(from, to + 1):
			if i != index:
				paths.append(_rows[i]["path"])
		#? Clicked row last - it's the primary one (_primary_path()).
		paths.append(path)
		CandyDialogue.set_selection(paths)
		_set_active(path)
		return

	if ctrl:
		CandyDialogue.toggle_selected(path)
	else:
		CandyDialogue.set_selection([path])
	_anchor = index
	if CandyDialogue.is_selected(path, reference):
		_set_active(path)
	elif path == CandyDialogue.active_path_of(reference):
		#% Ctrl-clicked off - the line selected last before it takes over:
		_set_active_to_last_selected()


#& Keyboard

#* Select the row step rows away, like a click:
#? extend: Shift held. kind: only rows of that kind count (-1: any).
func step_selection(step: int, extend: bool, kind: int = -1) -> void:
	if _rows.is_empty():
		return
	var index := _current_index()
	if index < 0:
		if step > 0:
			index = -1
		else:
			index = _rows.size()
	var target := index + step
	#Ł Skip rows of other kinds:
	while target >= 0 and target < _rows.size() and kind >= 0 and int(_rows[target]["kind"]) != kind:
		target += signi(step)
	if target < 0 or target >= _rows.size():
		return
	CandyDialogue.use_reference(reference)
	if extend and _anchor < 0:
		_anchor = maxi(index, 0)
	_click_row(target, extend, false)
	_keyboard_index = target
	ensure_row_visible(target)


#* The row the keyboard moves from:
func _current_index() -> int:
	#? The last one it moved to if still selected, else the active line, else the last selected row.
	if _keyboard_index >= 0 and _keyboard_index < _rows.size() \
			and CandyDialogue.is_selected(_rows[_keyboard_index]["path"], reference):
		return _keyboard_index
	var active := CandyDialogue.active_path_of(reference)
	var selected := CandyDialogue.selection_of(reference)
	var last_selected: Array = []
	if not selected.is_empty():
		last_selected = selected[selected.size() - 1]
	for i in _rows.size():
		if _rows[i]["path"] == active:
			return i
	for i in _rows.size():
		if _rows[i]["path"] == last_selected:
			return i
	return -1


#* Scroll a row into view:
func ensure_row_visible(index: int) -> void:
	if scroll == null or index < 0 or index >= _rows.size():
		return
	var top := float(_rows[index]["y"])
	var bottom := top + float(_rows[index]["height"])
	if top < scroll.scroll_vertical:
		scroll.scroll_vertical = int(top)
	elif bottom > scroll.scroll_vertical + scroll.size.y:
		scroll.scroll_vertical = int(bottom - scroll.size.y)


#* Make a line the active path (only lines are editable):
func _set_active(path: Array) -> void:
	if path.size() == 3:
		CandyDialogue.set_active_path(path)


func _set_active_to_last_selected() -> void:
	var selected := CandyDialogue.selection_of(reference)
	for i in range(selected.size() - 1, -1, -1):
		var path: Array = selected[i]
		if path.size() == 3:
			CandyDialogue.set_active_path(path)
			return


func _hits_fold_arrow(index: int, x: float) -> bool:
	var row: Dictionary = _rows[index]
	if not row["foldable"]:
		return false
	var start := _row_x() + CandyNavigatorRow.row_indent(int(row["depth"])) + CandyNavigatorRow.arrow_start(row)
	return x >= start and x <= start + CandyNavigatorRow.ARROW_WIDTH


#& Drag and drop

func _get_drag_data(at_position: Vector2) -> Variant:
	var index := _row_at(at_position.y)
	if index < 0:
		return null
	#Ł Drag started - cancel the pending click, drag the whole selection:
	_pending_click = -1
	CandyDialogue.use_reference(reference)
	if not CandyDialogue.is_selected(_rows[index]["path"], reference):
		_click_row(index, false, false)

	var kind := CandyDialogue.selected_kind()
	var paths := CandyDialogue.selected_paths_of_kind(kind)
	if kind == CandyDialogue.Kind.CONVERSATION:
		var movable: Array = []
		for path in paths:
			if not CandyDialogue.is_preset_conversation(str(path[0])):
				movable.append(path)
		paths = movable  #/ Preset conversations can't be moved
	if paths.is_empty():
		return null

	var preview := PanelContainer.new()
	var label := Label.new()
	label.text = _drag_text(kind, paths.size())
	preview.add_child(label)
	set_drag_preview(preview)

	set_process(true)  #/ Auto-scroll
	return {"source": DRAG_SOURCE, "kind": kind, "paths": paths, "reference": reference}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.get("source") == DRAG_SOURCE):
		return false
	_drop = _resolve_drop(int(data["kind"]), at_position.y)
	queue_redraw()
	return not _drop.is_empty()


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var target := _resolve_drop(int(data["kind"]), at_position.y)
	if target.is_empty():
		return
	var paths: Array = data["paths"]
	#? Keep the moved items selected in the source Navigator's view.
	CandyDialogue.use_reference(str(data.get("reference", reference)))
	match int(data["kind"]):
		CandyDialogue.Kind.LINE:
			CandyDialogue.move_lines(paths, target["conversation"], target["block"], int(target["index"]))
		CandyDialogue.Kind.BLOCK:
			CandyDialogue.move_blocks(paths, target["conversation"], int(target["index"]))
		CandyDialogue.Kind.CONVERSATION:
			CandyDialogue.move_conversations(paths, int(target["index"]))
	_clear_drop()


func _clear_drop() -> void:
	_drop = {}
	_scroll_remainder = 0.0
	set_process(false)
	queue_redraw()


#* Turn a mouse position into an insertion point between two rows:
func _resolve_drop(kind: int, y: float) -> Dictionary:
	var slot := _slot_at(y)
	var previous: Dictionary = {}
	if slot > 0:
		previous = _rows[slot - 1]

	match kind:
		CandyDialogue.Kind.LINE:
			if previous.is_empty():
				return {}
			var path: Array = previous["path"]
			match int(previous["kind"]):
				CandyDialogue.Kind.LINE:
					return {"slot": slot, "conversation": path[0], "block": path[1], "index": int(path[2]) + 1}
				CandyDialogue.Kind.BLOCK:
					return {"slot": slot, "conversation": path[0], "block": path[1], "index": 0}			#/ Below a Block header: the top of that block
				_:
					return {}  #/ Between a conversation header and its first block

		CandyDialogue.Kind.BLOCK:
			if previous.is_empty():
				return {}
			var path: Array = previous["path"]
			var conversation: String = path[0]
			if int(previous["kind"]) == CandyDialogue.Kind.CONVERSATION:
				return {"slot": slot, "conversation": conversation, "index": 0}
			var index := CandyDialogue.block_names(conversation).find(path[1])
			return {"slot": slot, "conversation": conversation, "index": index + 1}

		CandyDialogue.Kind.CONVERSATION:
			#% Preset conversations stay put (first in All mode) - the slot after them is the dialogue's top, if a dialogue conversation follows:
			if previous.is_empty() or CandyDialogue.is_preset_conversation(str(previous["path"][0])):
				if slot >= _rows.size():
					return {}
				var next: Dictionary = _rows[slot]
				if int(next["kind"]) != CandyDialogue.Kind.CONVERSATION \
						or CandyDialogue.is_preset_conversation(str(next["path"][0])):
					return {}
				return {"slot": slot, "index": 0}
			var conversation: String = previous["path"][0]
			return {"slot": slot, "index": CandyDialogue.conversation_names().find(conversation) + 1}

	return {}


#& Drop indicator

func _draw() -> void:
	if _drop.is_empty():
		return
	var y := _slot_y(int(_drop["slot"]))
	var indent := _row_x() + CandyNavigatorRow.row_indent(_drop_depth())
	var accent := get_theme_color(&"drop_indicator", CandyThemeDefaults.NAVIGATOR)
	draw_rect(Rect2(indent, y - INDICATOR_HEIGHT * 0.5, _row_x() + _row_width() - indent, INDICATOR_HEIGHT), accent)
	draw_circle(Vector2(indent, y), INDICATOR_HEIGHT, accent)


func _drop_depth() -> int:
	if _drop.has("block"):
		return 2
	if _drop.has("conversation"):
		return 1
	return 0


#& Auto-scroll

func _process(delta: float) -> void:
	if scroll == null or not get_viewport().gui_is_dragging():
		_clear_drop()
		return

	var mouse := scroll.get_local_mouse_position()
	var speed := 0.0
	if mouse.y < AUTOSCROLL_MARGIN:
		speed = -AUTOSCROLL_SPEED * (1.0 - mouse.y / AUTOSCROLL_MARGIN)
	elif mouse.y > scroll.size.y - AUTOSCROLL_MARGIN:
		speed = AUTOSCROLL_SPEED * (1.0 - (scroll.size.y - mouse.y) / AUTOSCROLL_MARGIN)
	if speed == 0.0:
		return

	#? scroll_vertical is an int - carry the sub-pixel remainder.
	_scroll_remainder += speed * delta
	var whole := int(_scroll_remainder)
	if whole != 0:
		_scroll_remainder -= float(whole)
		scroll.scroll_vertical += whole
		queue_redraw()


#& Geometry

#* Row containing y (-1 in a gap or past the end):
func _row_at(y: float) -> int:
	var index := _index_at(y)
	if index < 0 or index >= _rows.size():
		return -1
	var row: Dictionary = _rows[index]
	var top := float(row["y"])
	if y >= top and y < top + float(row["height"]):
		return index
	return -1


#* First row whose bottom edge is below y (binary search):
func _index_at(y: float) -> int:
	var low := 0
	var high := _rows.size() - 1
	var result := _rows.size()
	while low <= high:
		var mid := int((low + high) / 2.0)
		var row: Dictionary = _rows[mid]
		if y < float(row["y"]) + float(row["height"]):
			result = mid
			high = mid - 1
		else:
			low = mid + 1
	return mini(result, _rows.size() - 1)


#* The insertion slot nearest to y (0 above the first row, rows.size() below the last):
func _slot_at(y: float) -> int:
	for i in _rows.size():
		var row: Dictionary = _rows[i]
		#% A row's top half inserts before it:
		if y < float(row["y"]) + float(row["height"]) * 0.5:
			return i
	return _rows.size()


func _slot_y(slot: int) -> float:
	if _rows.is_empty():
		return 0.0
	if slot >= _rows.size():
		var last: Dictionary = _rows[_rows.size() - 1]
		return float(last["y"]) + float(last["height"]) + SEPARATION * 0.5
	return float(_rows[slot]["y"]) - SEPARATION * 0.5


func _drag_text(kind: int, count: int) -> String:
	match kind:
		CandyDialogue.Kind.BLOCK:
			return CandyLocale.tn("%d block", "%d blocks", count) % count
		CandyDialogue.Kind.CONVERSATION:
			return CandyLocale.tn("%d conversation", "%d conversations", count) % count
	return CandyLocale.tn("%d line", "%d lines", count) % count