#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyTabStrip
extends Control

#^ Left-click on a tab:
signal tab_clicked(index: int)
signal tab_double_clicked(index: int)
#^ Right-click on a tab, or on empty space (index -1):
signal context_requested(index: int, screen_position: Vector2i)
#^ A tab of strip from (this one or another) dropped before to_index:
#? to_index counts this strip's tabs as they were before the drop.
signal tab_dropped(from: CandyTabStrip, from_index: int, to_index: int)

const DRAG_TYPE := "candy_tab"
#^ Theme type the strip is styled by:
const THEME_TYPE := &"TabContainer"

#^ The tabs shown. Set before the strip enters the tree:
var container: TabContainer
#^ SIDE_TOP, SIDE_LEFT or SIDE_RIGHT:
var side: Side = SIDE_TOP:
	set(value):
		side = value
		update_minimum_size()
		_update_layout()
		queue_redraw()
#^ Strips of one group (0 and up) trade tabs (-1 = drag within this strip only):
var rearrange_group := -1

#^ Each tab's place along the strip: x its start, y its length (0 when scrolled out):
var _spans: Array[Vector2] = []
#^ First and last tabs shown:
var _first := 0
var _last := -1
#^ Whether the tabs don't fit (shows the scroll arrows):
var _overflow := false
var _hovered := -1
#^ Scroll arrow under the mouse (-1 = decrement, 1 = increment, 0 = none):
var _hovered_arrow := 0
#^ Where a dragged tab would go, -1 when none is over the strip:
var _drop_index := -1
#^ Current tab last shown, scrolled into sight when it changes:
var _shown_current := -1
var _refresh_queued := false


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if container != null:
		container.tab_changed.connect(func(_index: int): refresh())
		container.child_order_changed.connect(refresh)
	refresh()


#* Show the container's tabs as they are now:
func refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	#? Deferred, so several changes draw once, on an up-to-date container.
	_refresh_now.call_deferred()


func _refresh_now() -> void:
	_refresh_queued = false
	if not is_inside_tree():
		return
	var current := _current()
	if current != _shown_current:
		_shown_current = current
		_scroll_into_sight(current)
	_update_layout()
	queue_redraw()


func _count() -> int:
	if container == null:
		return 0
	return container.get_tab_count()


func _current() -> int:
	if container == null:
		return -1
	return container.current_tab


func _is_vertical() -> bool:
	return side != SIDE_TOP


#& Sizes and layout

func _get_minimum_size() -> Vector2:
	var thickness := _thickness()
	var length := _arrows_length()
	if _is_vertical():
		return Vector2(thickness, length)
	return Vector2(length, thickness)


#* Return the strip's length, along the tabs:
func _length() -> float:
	if _is_vertical():
		return size.y
	return size.x


#* Return the strip's thickness, across the tabs:
func _thickness() -> float:
	var font := get_theme_font(&"font", THEME_TYPE)
	var font_size := get_theme_font_size(&"font_size", THEME_TYPE)
	var text_height := 0.0
	if font != null:
		text_height = font.get_height(font_size)
	var thickness := 0.0
	for style_name: StringName in [&"tab_selected", &"tab_unselected", &"tab_hovered"]:
		var style := get_theme_stylebox(style_name, THEME_TYPE)
		thickness = maxf(thickness, style.get_minimum_size().y + text_height)
	return ceilf(thickness)


func _style_for(index: int) -> StyleBox:
	if index == _current():
		return get_theme_stylebox(&"tab_selected", THEME_TYPE)
	if index == _hovered:
		return get_theme_stylebox(&"tab_hovered", THEME_TYPE)
	return get_theme_stylebox(&"tab_unselected", THEME_TYPE)


func _title(index: int) -> String:
	return container.get_tab_title(index)


func _tab_length(index: int) -> float:
	var font := get_theme_font(&"font", THEME_TYPE)
	var font_size := get_theme_font_size(&"font_size", THEME_TYPE)
	var text_width := font.get_string_size(_title(index), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return ceilf(_style_for(index).get_minimum_size().x + text_width)


#* Return the room the scroll arrows take along the strip:
func _arrows_length() -> float:
	var length := 0.0
	for icon_name: StringName in [&"decrement", &"increment"]:
		length += _along(_footprint(get_theme_icon(icon_name, THEME_TYPE)))
	return length


#* Place the tabs along the strip, from _first, as many as fit:
func _update_layout() -> void:
	var count := _count()
	_spans.resize(count)
	_spans.fill(Vector2.ZERO)
	_last = -1
	if count == 0:
		_first = 0
		_overflow = false
		return
	var start := 0.0
	var lengths: Array[float] = []
	var total := start
	for i in count:
		lengths.append(_tab_length(i))
		total += lengths[i]
	_overflow = total > _length()
	var room := _length()
	if _overflow:
		room -= _arrows_length()
	else:
		_first = 0
	_first = clampi(_first, 0, count - 1)
	var at := start
	for i in range(_first, count):
		#? The first tab shows even when it doesn't fit, cut short.
		if i > _first and at + lengths[i] > room:
			break
		_spans[i] = Vector2(at, lengths[i])
		_last = i
		at += lengths[i]


#* Scroll until the tab is in sight:
func _scroll_into_sight(index: int) -> void:
	if index < 0:
		return
	_update_layout()
	if index < _first:
		_first = index
		return
	while index > _last and _first < index:
		_first += 1
		_update_layout()


func _scroll(steps: int) -> void:
	if not _overflow:
		return
	if steps > 0 and _last >= _count() - 1:
		return
	_first = clampi(_first + steps, 0, maxi(_count() - 1, 0))
	_update_layout()
	queue_redraw()


#* Return the tab at a point, or -1:
func _tab_at(point: Vector2) -> int:
	var along := _along(point)
	for i in _spans.size():
		var span := _spans[i]
		if span.y > 0.0 and along >= span.x and along < span.x + span.y:
			return i
	return -1


#* Return where a tab dropped at point goes - before the tab under it, or after:
func _insert_index_at(point: Vector2) -> int:
	var along := _along(point)
	if _last < 0:
		return _count()
	for i in range(_first, _last + 1):
		var span := _spans[i]
		if along < span.x + span.y / 2.0:
			return i
	return _last + 1


func _along(point: Vector2) -> float:
	if _is_vertical():
		return point.y
	return point.x


#* Return the point at along / across the strip:
func _point(along: float, across: float) -> Vector2:
	if _is_vertical():
		return Vector2(across, along)
	return Vector2(along, across)


func _across(vector: Vector2) -> float:
	if _is_vertical():
		return vector.x
	return vector.y


#* Return the room an icon takes on the strip (turned on a side):
func _footprint(icon: Texture2D) -> Vector2:
	if icon == null:
		return Vector2.ZERO
	var icon_size := Vector2(icon.get_size())
	if _is_vertical():
		return Vector2(icon_size.y, icon_size.x)
	return icon_size


#* Return a scroll arrow's rect (decrement then increment, at the strip's end):
func _arrow_rect(increment: bool) -> Rect2:
	var increment_footprint := _footprint(get_theme_icon(&"increment", THEME_TYPE))
	var footprint := increment_footprint
	var at := _length() - _along(increment_footprint)
	if not increment:
		footprint = _footprint(get_theme_icon(&"decrement", THEME_TYPE))
		at -= _along(footprint)
	return Rect2(_point(at, (_thickness() - _across(footprint)) / 2.0), footprint)


func _arrow_at(point: Vector2) -> int:
	if not _overflow:
		return 0
	if _arrow_rect(false).has_point(point):
		return -1
	if _arrow_rect(true).has_point(point):
		return 1
	return 0


#& Drawing

#* Return the frame a flat tab is drawn in:
#? (0, 0) its top-left corner, x along the tab, y across.
func _frame(along: float, length: float) -> Transform2D:
	var thickness := _thickness()
	#? On a side, turned so the tab's top faces away from the panel.
	match side:
		SIDE_LEFT:
			return Transform2D(Vector2(0, -1), Vector2(1, 0), Vector2(0, along + length))
		SIDE_RIGHT:
			return Transform2D(Vector2(0, 1), Vector2(-1, 0), Vector2(thickness, along))
	return Transform2D(Vector2(1, 0), Vector2(0, 1), Vector2(along, 0))


func _draw() -> void:
	_update_layout()
	var thickness := _thickness()
	var background := get_theme_stylebox(&"tabbar_background", THEME_TYPE)
	if background != null:
		draw_set_transform_matrix(_frame(0.0, _length()))
		draw_style_box(background, Rect2(Vector2.ZERO, Vector2(_length(), thickness)))
	#Ł Current tab last, over its neighbors and the separator:
	var current := _current()
	for i in range(_first, _last + 1):
		if i != current:
			_draw_tab(i, thickness)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var current_shown := current >= _first and current <= _last
	_draw_separator(thickness, current_shown)
	if current_shown:
		_draw_tab(current, thickness)
	draw_set_transform_matrix(Transform2D.IDENTITY)

	if _overflow:
		_draw_arrows()
	if _drop_index >= 0:
		_draw_drop_mark(thickness)


func _draw_tab(index: int, thickness: float) -> void:
	var span := _spans[index]
	var style := _style_for(index)
	draw_set_transform_matrix(_frame(span.x, span.y))
	var tab_rect := Rect2(Vector2.ZERO, Vector2(span.y, thickness))
	draw_style_box(style, tab_rect)

	var font := get_theme_font(&"font", THEME_TYPE)
	var font_size := get_theme_font_size(&"font_size", THEME_TYPE)
	var color := get_theme_color(&"font_unselected_color", THEME_TYPE)
	if index == _current():
		color = get_theme_color(&"font_selected_color", THEME_TYPE)
	elif index == _hovered:
		color = get_theme_color(&"font_hovered_color", THEME_TYPE)
	var text := _title(index)
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var content_left := style.get_margin(SIDE_LEFT)
	var content_top := style.get_margin(SIDE_TOP)
	var content_width := span.y - content_left - style.get_margin(SIDE_RIGHT)
	var content_height := thickness - content_top - style.get_margin(SIDE_BOTTOM)
	var baseline := Vector2(
		roundf(content_left + (content_width - text_width) / 2.0),
		roundf(content_top + (content_height - font.get_height(font_size)) / 2.0 + font.get_ascent(font_size)))
	var outline_size := get_theme_constant(&"outline_size", THEME_TYPE)
	if outline_size > 0:
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size,
			get_theme_color(&"font_outline_color", THEME_TYPE))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


#* Draw the line between the tabs and the panel, cut under the current tab:
func _draw_separator(thickness: float, cut_under_current: bool) -> void:
	var width := float(get_theme_constant(&"separator_width", CandyThemeDefaults.TAB_STRIP))
	if width <= 0.0:
		return
	var color := get_theme_color(&"separator", CandyThemeDefaults.TAB_STRIP)
	#? On the right, the panel is on the strip's left.
	var across := thickness - width
	if side == SIDE_RIGHT:
		across = 0.0
	var pieces: Array[Vector2] = [Vector2(0.0, _length())]
	if cut_under_current:
		var span := _spans[_current()]
		pieces = [Vector2(0.0, span.x), Vector2(span.x + span.y, _length() - span.x - span.y)]
	for piece in pieces:
		if piece.y > 0.0:
			draw_rect(Rect2(_point(piece.x, across), _point(piece.y, width)), color)


func _draw_arrows() -> void:
	var can_decrement := _first > 0
	var can_increment := _last < _count() - 1
	_draw_arrow(false, can_decrement)
	_draw_arrow(true, can_increment)


func _draw_arrow(increment: bool, enabled: bool) -> void:
	var icon_name := &"decrement"
	var direction := -1
	if increment:
		icon_name = &"increment"
		direction = 1
	if enabled and _hovered_arrow == direction:
		icon_name = StringName(String(icon_name) + "_highlight")
	var modulate_color := Color.WHITE
	if not enabled:
		modulate_color = Color(1, 1, 1, 0.5)
	_draw_icon_centered(get_theme_icon(icon_name, THEME_TYPE), _arrow_rect(increment).get_center(), modulate_color)


func _draw_drop_mark(thickness: float) -> void:
	var along := 0.0
	if _drop_index <= _last and _drop_index >= _first:
		along = _spans[_drop_index].x
	elif _last >= 0:
		along = _spans[_last].x + _spans[_last].y
	_draw_icon_centered(get_theme_icon(&"drop_mark", THEME_TYPE), _point(along, thickness / 2.0),
		get_theme_color(&"drop_mark_color", THEME_TYPE))


#* Draw an icon centered on a point, turned a quarter clockwise on a side:
func _draw_icon_centered(icon: Texture2D, center: Vector2, color: Color) -> void:
	if icon == null:
		return
	var turn := Transform2D(Vector2(1, 0), Vector2(0, 1), center.round())
	if _is_vertical():
		turn = Transform2D(Vector2(0, 1), Vector2(-1, 0), center.round())
	draw_set_transform_matrix(turn)
	draw_texture(icon, (-Vector2(icon.get_size()) / 2.0).round(), color)
	draw_set_transform_matrix(Transform2D.IDENTITY)


#& Input

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_hovered(_tab_at(event.position), _arrow_at(event.position))
		return
	if not (event is InputEventMouseButton and event.pressed):
		return
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
			if _overflow:
				_scroll(-1)
				accept_event()
		MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
			if _overflow:
				_scroll(1)
				accept_event()
		MOUSE_BUTTON_LEFT:
			var arrow := _arrow_at(event.position)
			if arrow != 0:
				_scroll(arrow)
			else:
				var index := _tab_at(event.position)
				if index >= 0:
					if event.double_click:
						tab_double_clicked.emit(index)
					else:
						tab_clicked.emit(index)
			accept_event()
		MOUSE_BUTTON_RIGHT:
			context_requested.emit(_tab_at(event.position), Vector2i(get_screen_position() + event.position))
			accept_event()


func _set_hovered(index: int, arrow: int) -> void:
	if index == _hovered and arrow == _hovered_arrow:
		return
	_hovered = index
	_hovered_arrow = arrow
	_update_layout()
	queue_redraw()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_update_layout()
			queue_redraw()
		NOTIFICATION_THEME_CHANGED:
			update_minimum_size()
			_update_layout()
			queue_redraw()
		NOTIFICATION_MOUSE_EXIT:
			_drop_index = -1
			_set_hovered(-1, 0)
			queue_redraw()
		NOTIFICATION_DRAG_END:
			if _drop_index >= 0:
				_drop_index = -1
				queue_redraw()


#& Dragging

func _get_drag_data(at_position: Vector2) -> Variant:
	var index := _tab_at(at_position)
	if index < 0:
		return null
	var preview := Label.new()
	preview.text = _title(index)
	set_drag_preview(preview)
	return {"type": DRAG_TYPE, "strip": self, "index": index}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if _source_strip(data) == null:
		return false
	var index := _insert_index_at(at_position)
	if index != _drop_index:
		_drop_index = index
		queue_redraw()
	return true


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var from := _source_strip(data)
	_drop_index = -1
	queue_redraw()
	if from == null:
		return
	tab_dropped.emit(from, int(data.get("index", -1)), _insert_index_at(at_position))


#* Return the strip a dragged tab comes from, or null if it can't drop here:
func _source_strip(data: Variant) -> CandyTabStrip:
	if typeof(data) != TYPE_DICTIONARY or data.get("type", "") != DRAG_TYPE:
		return null
	var from: Variant = data.get("strip")
	if not is_instance_valid(from) or not (from is CandyTabStrip):
		return null
	if from != self and (rearrange_group < 0 or from.rearrange_group != rearrange_group):
		return null
	return from
