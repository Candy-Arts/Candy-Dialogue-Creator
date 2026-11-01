#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAreaSplit
extends Container

#^ Gap between the two Areas when the theme sets neither CandyAreaSplit's "gap" nor "locked_gap":
#? "locked_gap" is for a split that can't be dragged, e.g. under the top bar.
const HANDLE_SIZE := 6.0
#^ Area names the menu lists before "+N more":
const AREA_NAMES_SHOWN := 3
#^ Between the two sizes of a stacked split's tooltip:
const STACKED_SIZE_SEPARATOR := "—"
#^ Ctrl-dragging - the step setting (pixels) and its default:
const RESIZE_STEP_SETTING := "layout_resize_step"
const DEFAULT_RESIZE_STEP := 16
#^ Alt-dragging - snap distance in pixels:
const SNAP_DISTANCE := 12.0
#^ The grip of a divider with show_grip, in pixels, and how strong its color is:
const GRIP_LENGTH := 48.0
const GRIP_THICKNESS := 3.0
const GRIP_ALPHA := 0.7
#^ Every split view, for Alt-dragging to find the others:
const SPLITS_GROUP := &"candy_area_splits"

#^ Divider dragged or reset:
signal ratio_changed
#^ The menu asks for a structural change (the host applies it):
#/   "wrap"    area: this split, argument: [Layout, new_area_first]
#/   "insert"  area: this split: a new Area between its two sides
#/   "swap"    area: this split
#/   "rotate"  area: this split
#/   "remove"  area: the child Area (side) to remove
#/   "replace" area: this split, argument: the Area layout to replace it with
signal edit_requested(action: String, area: CandyAreaData, argument: Variant)
#^ The divider hovered or dragged, or neither any more:
signal divider_hovered(hovered: bool)

enum MenuId {
	HEADING, ADD_LEFT, ADD_RIGHT, ADD_ABOVE, ADD_BELOW, INSERT_BETWEEN,
	SWAP, ROTATE, EQUALIZE,
	REMOVE_FIRST, REMOVE_SECOND,
	SAVE_LAYOUT,
}

var data: CandyAreaData
#^ Draw a grip on the divider even while it isn't hovered:
var show_grip := false
#^ The fixed size a double-click on the divider puts back (fixed size modes), -1 for none:
var double_click_size := -1.0

var _first: Control
var _second: Control
var _handle: Handle
#^ Edit Layout mode's button, over the middle of the divider:
var _area_button: CandyAreaButton = null
var _menu: PopupMenu = null
var _menu_enabled := false
var _title_of: Callable
var _can_remove: Callable
#^ Save / Load Area Layout (see enable_layouts()):
var _layout_menu: CandyLayoutMenu
var _capture: Callable
var _hovered := false
var _dragging := false
var _drag_offset := 0.0
#^ Room from hidden Areas beyond its share, and where it is (see set_area_growth()):
var _extra := Vector2.ZERO
var _grow := Vector2i.ZERO


func setup(p_data: CandyAreaData, first_view: Control, second_view: Control) -> void:
	data = p_data
	_first = first_view
	_second = second_view
	add_child(_first)
	add_child(_second)
	add_to_group(SPLITS_GROUP)
	_first.visibility_changed.connect(_on_side_visibility_changed)
	_second.visibility_changed.connect(_on_side_visibility_changed)

	_handle = Handle.new()
	_handle.split = self
	_handle.gui_input.connect(_on_handle_gui_input)
	_handle.mouse_entered.connect(_set_hovered.bind(true))
	_handle.mouse_exited.connect(_set_hovered.bind(false))
	_handle.draw.connect(_draw_handle)
	add_child(_handle)

	_configure_handle()


#* Give the split Area its menu:
#? title_of(panel_id) -> String names the Areas in the menu.
#? can_remove(child: CandyAreaData) -> bool says whether a side may be removed.
func enable_menu(title_of: Callable, can_remove: Callable) -> void:
	_menu_enabled = true
	_title_of = title_of
	_can_remove = can_remove
	if _menu == null:
		_menu = PopupMenu.new()
		_menu.id_pressed.connect(_on_menu_id_pressed)
		add_child(_menu)
		_build_menu()
	if _handle != null:
		_configure_handle()


#* Add Save / Load Area Layout to the menu:
#? kind: CandyLayoutLibrary.AREAS or LINE_AREAS.
#? capture(area) -> Dictionary: the layout to save. fits(layout) -> bool: hides saved ones that don't fit.
#! Call after enable_menu().
func enable_layouts(kind: String, capture: Callable, fits: Callable = Callable()) -> void:
	if _menu == null or _layout_menu != null:
		return
	_capture = capture
	_layout_menu = CandyLayoutMenu.new()
	_layout_menu.save_label = CandyLocale.t("Save Area Layout...")
	_layout_menu.load_label = CandyLocale.t("Load Area Layout")
	add_child(_layout_menu)
	_layout_menu.setup(kind, "", func() -> Dictionary: return _capture.call(data),
		func(layout: Dictionary): edit_requested.emit("replace", data, layout), fits)
	_menu.add_separator()
	_layout_menu.add_items(_menu, MenuId.SAVE_LAYOUT)


#* Save / Load Area Layout items, or null before enable_layouts():
func area_layout_menu() -> CandyLayoutMenu:
	return _layout_menu


#* Make the split Area's button, shown over the middle of the divider:
#? Over the content rather than beside it, so it takes no room.
func make_area_button() -> CandyAreaButton:
	if _area_button != null:
		return _area_button
	_area_button = CandyAreaButton.new()
	_area_button.setup(data, open_menu_under)
	add_child(_area_button)			#/ Last, so it's drawn above both sides
	queue_sort()
	return _area_button


#* Open the menu under a screen rectangle and return it:
func open_menu_under(anchor: Rect2i) -> PopupMenu:
	_refresh_menu()
	CandyPopups.popup_at(_menu, anchor, self)
	return _menu


func _configure_handle() -> void:
	if data.can_resize:
		if _axis() == 0:
			_handle.mouse_default_cursor_shape = Control.CURSOR_HSPLIT
		else:
			_handle.mouse_default_cursor_shape = Control.CURSOR_VSPLIT
	else:
		_handle.mouse_default_cursor_shape = Control.CURSOR_ARROW

	if data.can_resize or _menu_enabled:
		_handle.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	update_minimum_size()
	queue_sort()


#* Divider tooltip - "512 | 256", or stacked "512\n—\n256":
func size_tooltip() -> String:
	var axis := _axis()
	var first_size := roundi(_first.size[axis])
	var second_size := roundi(_second.size[axis])
	if axis == 0:
		return "%d | %d" % [first_size, second_size]
	return "%d\n%s\n%d" % [first_size, STACKED_SIZE_SEPARATOR, second_size]


func _axis() -> int:
	if data.layout == CandyAreaData.Layout.LEFT_RIGHT:
		return 0
	return 1


func _gap() -> float:
	var gap := _theme_gap(&"gap", HANDLE_SIZE)
	if data.can_resize or _menu_enabled:
		return gap
	return _theme_gap(&"locked_gap", gap)


func _theme_gap(constant_name: StringName, fallback: float) -> float:
	if has_theme_constant(constant_name, CandyThemeDefaults.AREA_SPLIT):
		return float(get_theme_constant(constant_name, CandyThemeDefaults.AREA_SPLIT))
	return fallback


func _get_minimum_size() -> Vector2:
	if data == null:
		return Vector2.ZERO
	if not _first.visible:
		return _second.get_combined_minimum_size()
	if not _second.visible:
		return _first.get_combined_minimum_size()
	var a := _first.get_combined_minimum_size()
	var b := _second.get_combined_minimum_size()
	if _axis() == 0:
		return Vector2(a.x + b.x + _gap(), maxf(a.y, b.y))
	return Vector2(maxf(a.x, b.x), a.y + b.y + _gap())


#* Give a hidden side's space to the other:
func _on_side_visibility_changed() -> void:
	visible = _first.visible or _second.visible			#/ Both hidden: hides too, so its parent split does the same
	_handle.visible = _first.visible and _second.visible
	update_minimum_size()
	queue_sort()


#* Handle highlight color:
func _highlight() -> Color:
	return get_theme_color(&"highlight", CandyThemeDefaults.AREA_SPLIT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and data != null:
		_layout_children()


#* The most it can use - its sides' maximum sizes (CandyAreaCap), INF where there's none:
func area_max_size() -> Vector2:
	if data == null:
		return Vector2(INF, INF)
	if not _first.visible:
		return CandyAreaCap.max_of(_second)
	if not _second.visible:
		return CandyAreaCap.max_of(_first)
	var a := CandyAreaCap.max_of(_first)
	var b := CandyAreaCap.max_of(_second)
	var result := Vector2(maxf(a.x, b.x), maxf(a.y, b.y))			#/ Across: the wider side
	var axis := _axis()
	result[axis] = a[axis] + b[axis] + _gap()			#/ Along: both, INF if either has no maximum
	return result


#* The range of the first child's size along the split axis: Vector2(least, most):
#? Minimum sizes come first, then maximum sizes: a capped side gives the rest to the other.
func _first_range(available: float) -> Vector2:
	var axis := _axis()
	var min_a: float = _first.get_combined_minimum_size()[axis]
	var min_b: float = _second.get_combined_minimum_size()[axis]
	var max_a: float = CandyAreaCap.max_of(_first)[axis]
	var max_b: float = CandyAreaCap.max_of(_second)[axis]
	var least := maxf(min_a, available - max_b)
	var most := minf(max_a, available - min_b)
	if least > most:
		#% Both capped with room to spare, or minimums too big - the first side's limits win:
		var fixed := maxf(min_a, minf(max_a, available - min_b))
		return Vector2(fixed, fixed)
	return Vector2(least, most)


#* Size of the first child along the split axis, within the sides' limits:
func _first_extent(total: float) -> float:
	var axis := _axis()
	var min_a: float = _first.get_combined_minimum_size()[axis]
	var min_b: float = _second.get_combined_minimum_size()[axis]
	var available := total - _gap()

	var wanted: float
	match data.size_mode:
		CandyAreaData.SizeMode.FIXED_FIRST:
			wanted = min_a
			if data.fixed_size > 0.0:
				wanted = data.fixed_size
		CandyAreaData.SizeMode.FIXED_SECOND:
			wanted = available - min_b
			if data.fixed_size > 0.0:
				wanted = available - data.fixed_size
		_:
			wanted = available * data.ratio

	var limits := _first_range(available)
	return clampf(wanted, limits.x, limits.y)


#* The room both sides share along the axis (its size, less the divider):
func room_along() -> float:
	return size[_axis()] - _gap()


func _layout_children() -> void:
	_layout_sides()
	_place_area_button()


#& Room left by hidden Areas

#* Take the room a hidden Area left, from the parent split (see _pass_growth()):
#? extra: how much bigger than its own share it is; grow: where that room is, per axis (-1 start, 1 end, 0 none).
func set_area_growth(extra: Vector2, grow: Vector2i) -> void:
	if extra == _extra and grow == _grow:
		return
	_extra = extra
	_grow = grow
	queue_sort()


#* Its size along its axis with no room from hidden Areas - what its ratio shares out:
func _nominal_total() -> float:
	var axis := _axis()
	if _grow[axis] == 0:
		return size[axis]
	return maxf(0.0, size[axis] - _extra[axis])


#* Tell a side how much room it got beyond its share along the axis, and where:
func _pass_growth(side: Control, extra_along: float, grow_along: int) -> void:
	var axis := _axis()
	var extra: Vector2 = _extra			#/ Across, the same as this split's
	var grow: Vector2i = _grow
	extra[axis] = 0.0
	grow[axis] = 0
	if absf(extra_along) >= 1.0:
		extra[axis] = extra_along
		grow[axis] = grow_along
	CandyAreaCap.pass_growth(side, extra, grow)


#* How much of a height its Areas use, given that height as their share:
#? Less than all of it when hidden Areas left room - stacked Areas move up, and the rest is left empty.
func used_height(height: float) -> float:
	if data == null:
		return height
	var shown_first := _first.visible
	var shown_second := _second.visible
	#¦ 1. Side by side - the taller side:
	if _axis() == 0:
		var result := 0.0
		if shown_first:
			result = CandyAreaCap.used_height_of(_first, height)
		if shown_second:
			result = maxf(result, CandyAreaCap.used_height_of(_second, height))
		return result
	#¦ 2. Stacked - both, one under the other:
	var first_share := roundf(_first_extent(height))
	var second_share := maxf(0.0, height - _gap() - first_share)
	if not shown_first:
		return CandyAreaCap.used_height_of(_second, second_share)
	if not shown_second:
		return CandyAreaCap.used_height_of(_first, first_share)
	return CandyAreaCap.used_height_of(_first, first_share) + _gap() \
		+ CandyAreaCap.used_height_of(_second, second_share)


#* The least height it can take, given that height as its share, when only its bottom Areas shrink:
func least_height(height: float) -> float:
	if data == null:
		return get_combined_minimum_size().y
	var shown_first := _first.visible
	var shown_second := _second.visible
	#¦ 1. Side by side - the taller side's:
	if _axis() == 0:
		var result := 0.0
		if shown_first:
			result = CandyAreaCap.least_height_of(_first, height)
		if shown_second:
			result = maxf(result, CandyAreaCap.least_height_of(_second, height))
		return result
	#¦ 2. Stacked - the upper side as it is, the lowest at its least:
	var first_share := roundf(_first_extent(height))
	var second_share := maxf(0.0, height - _gap() - first_share)
	if not shown_second:
		return CandyAreaCap.least_height_of(_first, first_share)
	var below := CandyAreaCap.least_height_of(_second, second_share)
	if not shown_first:
		return below
	return CandyAreaCap.used_height_of(_first, first_share) + _gap() + below


#* Change its bottom Areas' height by delta, given that height as its share - every other Area keeps its own:
#? Its ratios change (the Editor's bottom dragger). Side by side, every side reaches the bottom;
#? stacked, only the lowest side shown does. Check least_height() first: delta isn't limited here.
func give_bottom(height: float, delta: float) -> void:
	if data == null or is_zero_approx(delta):
		return
	#¦ 1. Side by side - both sides:
	if _axis() == 0:
		for side in [_first, _second]:
			if side.visible:
				CandyAreaCap.give_bottom_of(side, height, delta)
		return
	#¦ 2. Stacked - the lowest side shown, the other keeping its pixels:
	var gap := _gap()
	var first_share := roundf(_first_extent(height))
	var second_share := maxf(0.0, height - gap - first_share)
	var after := maxf(1.0, height + delta - gap)
	if _second.visible:
		CandyAreaCap.give_bottom_of(_second, second_share, delta)
		match data.size_mode:
			CandyAreaData.SizeMode.FIXED_SECOND:
				data.fixed_size = second_share + delta
			CandyAreaData.SizeMode.RATIO:
				data.ratio = clampf(first_share / after, 0.0, 1.0)
	elif _first.visible:
		CandyAreaCap.give_bottom_of(_first, first_share, delta)
		match data.size_mode:
			CandyAreaData.SizeMode.FIXED_FIRST:
				data.fixed_size = first_share + delta
			CandyAreaData.SizeMode.RATIO:
				data.ratio = clampf((first_share + delta) / after, 0.0, 1.0)
	queue_sort()


func _layout_sides() -> void:
	if _axis() == 1:
		_layout_stacked()
		return
	var axis := _axis()
	var gap := _gap()
	#Ł The sides' shares, as if no Area were hidden:
	var nominal := _nominal_total()
	var first_share := roundf(_first_extent(nominal))
	var second_share := maxf(0.0, nominal - gap - first_share)

	#% A hidden side: the other takes its room, by the side it was on, so its own Areas keep their sizes:
	if not _first.visible or not _second.visible:
		var shown := _first
		var shown_share := first_share
		var toward := 1
		if not _first.visible:
			shown = _second
			shown_share = second_share
			toward = -1
		_pass_growth(shown, size[axis] - shown_share, toward)
		fit_child_in_rect(shown, Rect2(Vector2.ZERO, size))
		return

	#Ł Room from a hidden Area outside goes to the side it's beside:
	var first_size := first_share
	if _grow[axis] < 0:
		first_size += size[axis] - nominal
	var limits := _first_range(size[axis] - gap)
	first_size = roundf(clampf(first_size, limits.x, limits.y))
	var second_size := maxf(0.0, size[axis] - gap - first_size)
	var first_toward: int = _grow[axis]
	var second_toward: int = _grow[axis]
	if first_toward == 0:
		first_toward = 1
	if second_toward == 0:
		second_toward = -1
	_pass_growth(_first, first_size - first_share, first_toward)
	_pass_growth(_second, second_size - second_share, second_toward)

	fit_child_in_rect(_first, Rect2(0, 0, first_size, size.y))
	fit_child_in_rect(_handle, Rect2(first_size, 0, gap, size.y))
	fit_child_in_rect(_second, Rect2(first_size + gap, 0, second_size, size.y))


#* Lay out stacked sides: each keeps its share's height, and hidden Areas' room is left at the bottom:
#? Nothing grows down - widgets don't need to fill the page. A side that uses less than its share
#? (hidden Areas inside) is given only what it uses, so the side under it moves up.
func _layout_stacked() -> void:
	var gap := _gap()
	var nominal := _nominal_total()
	var first_share := roundf(_first_extent(nominal))
	var second_share := maxf(0.0, nominal - gap - first_share)
	var top := 0.0
	if _first.visible:
		var first_height: float = CandyAreaCap.used_height_of(_first, first_share)
		_pass_height(_first, first_height, first_share)
		fit_child_in_rect(_first, Rect2(0, 0, size.x, first_height))
		top = first_height + gap
		if _second.visible:
			fit_child_in_rect(_handle, Rect2(0, first_height, size.x, gap))
	if _second.visible:
		var second_height: float = CandyAreaCap.used_height_of(_second, second_share)
		_pass_height(_second, second_height, second_share)
		fit_child_in_rect(_second, Rect2(0, top, size.x, second_height))


#* Tell a stacked side its share's height, when it's given less (what it uses):
func _pass_height(side: Control, height: float, share: float) -> void:
	var extra: Vector2 = _extra			#/ Across, the same as this split's
	var grow: Vector2i = _grow
	extra.y = 0.0
	grow.y = 0
	if absf(height - share) >= 1.0:
		extra.y = height - share
		grow.y = 1
	CandyAreaCap.pass_growth(side, extra, grow)


#* Center the button on the divider (on the top edge while a side is hidden):
func _place_area_button() -> void:
	if _area_button == null:
		return
	var button_size := _area_button.get_combined_minimum_size()
	var center := Vector2(size.x * 0.5, button_size.y * 0.5)
	if _handle.visible:
		center = _handle.position + _handle.size * 0.5
	var corner := (center - button_size * 0.5).round()
	corner = corner.clamp(Vector2.ZERO, (size - button_size).max(Vector2.ZERO))
	fit_child_in_rect(_area_button, Rect2(corner, button_size))


#& Mouse

func _on_handle_gui_input(event: InputEvent) -> void:
	if not data.can_resize:
		return
	var axis := _axis()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.double_click and data.size_mode == CandyAreaData.SizeMode.RATIO:
			_equalize()
		#% A fixed size with a size to go back to (the bottom dragger) - put it back, without a drag:
		elif event.pressed and event.double_click and double_click_size >= 0.0:
			data.fixed_size = double_click_size
			_dragging = false
			queue_sort()
			ratio_changed.emit()
			_handle.accept_event()
			return
		if _dragging and not event.pressed:
			ratio_changed.emit()
		_dragging = event.pressed
		_drag_offset = event.position[axis]
		_refresh_highlight()
		_handle.accept_event()

	elif event is InputEventMouseMotion and _dragging:
		var total: float = size[axis]
		var available := maxf(1.0, total - _gap())
		var pos: float = get_local_mouse_position()[axis] - _drag_offset
		pos = _adjusted_drag(pos, event)
		var limits := _first_range(available)
		pos = clampf(pos, limits.x, limits.y)

		#Ł Stored as a share of its size with nothing hidden (_layout_sides() adds the room back):
		var nominal_available := maxf(1.0, _nominal_total() - _gap())
		if _grow[axis] < 0:
			pos -= total - _nominal_total()
		#% Stacked, with hidden Areas above the divider - it's drawn under what they use, not under its share:
		if axis == 1 and _first.visible:
			var share := roundf(_first_extent(_nominal_total()))
			pos += share - CandyAreaCap.used_height_of(_first, share)
		match data.size_mode:
			CandyAreaData.SizeMode.FIXED_FIRST:
				data.fixed_size = pos
			CandyAreaData.SizeMode.FIXED_SECOND:
				data.fixed_size = nominal_available - pos
			_:
				data.ratio = clampf(pos / nominal_available, 0.0, 1.0)
		queue_sort()
		_handle.accept_event()


#* Apply modifier keys to the dragged size:
func _adjusted_drag(pos: float, event: InputEventWithModifiers) -> float:
	if event.alt_pressed:			#/ Snap to another divider
		var lined_up := _snap_to_dividers(pos)
		if not is_nan(lined_up):
			return lined_up
	if event.ctrl_pressed:			#/ Round to the step
		var step := float(maxi(1, int(CandyProfiles.get_setting(RESIZE_STEP_SETTING, DEFAULT_RESIZE_STEP))))
		return roundf(pos / step) * step
	return pos


#* Size that lines this divider up with the closest same-direction divider:
func _snap_to_dividers(pos: float) -> float:
	var axis := _axis()
	var origin: float = get_global_rect().position[axis]
	var half_gap := _gap() * 0.5
	var best := NAN
	var best_distance := SNAP_DISTANCE
	for node in get_tree().get_nodes_in_group(SPLITS_GROUP):
		var other := node as CandyAreaSplit
		if other == null or other == self or other.data == null or other._handle == null:
			continue
		if other.get_viewport() != get_viewport() or not other.is_visible_in_tree():
			continue
		#% A divider inside this split moves with it:
		if other._axis() != axis or is_ancestor_of(other):
			continue
		var center: float = other._handle.get_global_rect().get_center()[axis]			#/ By centers, since widths differ
		var candidate := center - origin - half_gap
		var distance := absf(candidate - pos)
		if distance <= best_distance:
			best = candidate
			best_distance = distance
	return best			#/ NAN when none is within SNAP_DISTANCE


func _equalize() -> void:
	data.ratio = 0.5
	queue_sort()
	ratio_changed.emit()


func _set_hovered(value: bool) -> void:
	_hovered = value
	_refresh_highlight()


func _is_highlighted() -> bool:
	return _hovered or _dragging


func _refresh_highlight() -> void:
	_handle.queue_redraw()
	divider_hovered.emit(_is_highlighted())


func _draw_handle() -> void:
	if _is_highlighted():
		_handle.draw_rect(Rect2(Vector2.ZERO, _handle.size), Color(_highlight(), 0.6))
		return
	#% A divider with nothing to tell it apart (the Editor's bottom dragger) - a grip in its middle:
	if show_grip:
		var length := minf(GRIP_LENGTH, _handle.size[1 - _axis()])
		var thickness := minf(GRIP_THICKNESS, _handle.size[_axis()])
		var grip := Rect2(Vector2.ZERO, Vector2(length, thickness))
		if _axis() == 0:
			grip.size = Vector2(thickness, length)
		grip.position = ((_handle.size - grip.size) * 0.5).round()
		_handle.draw_rect(grip, Color(_highlight(), GRIP_ALPHA))


#& Menu

#* Build the menu once (keeps the Load submenu attached):
func _build_menu() -> void:
	_menu.add_separator("", MenuId.HEADING)
	_menu.add_item(CandyLocale.t("Add Area on the Left"), MenuId.ADD_LEFT)
	_menu.add_item(CandyLocale.t("Add Area on the Right"), MenuId.ADD_RIGHT)
	_menu.add_item(CandyLocale.t("Add Area Above"), MenuId.ADD_ABOVE)
	_menu.add_item(CandyLocale.t("Add Area Below"), MenuId.ADD_BELOW)
	_menu.add_item(CandyLocale.t("Insert Area Between"), MenuId.INSERT_BETWEEN)
	_menu.add_separator()
	_menu.add_item("", MenuId.SWAP)			#/ "" texts: set by _refresh_menu()
	_menu.add_item("", MenuId.ROTATE)
	_menu.add_item(CandyLocale.t("Equal Sizes"), MenuId.EQUALIZE)
	_menu.add_separator()
	_menu.add_item("", MenuId.REMOVE_FIRST)
	_menu.add_item("", MenuId.REMOVE_SECOND)


func _refresh_menu() -> void:
	_set_item_text(MenuId.HEADING, CandyLocale.t("Area: %s") % _names_of(data))
	var remove_first := CandyLocale.t("Remove Top Side (%s)")
	var remove_second := CandyLocale.t("Remove Bottom Side (%s)")
	if data.layout == CandyAreaData.Layout.LEFT_RIGHT:
		remove_first = CandyLocale.t("Remove Left Side (%s)")
		remove_second = CandyLocale.t("Remove Right Side (%s)")
		_set_item_text(MenuId.SWAP, CandyLocale.t("Swap Left and Right"))
		_set_item_text(MenuId.ROTATE, CandyLocale.t("Stack Top and Bottom"))
	else:
		_set_item_text(MenuId.SWAP, CandyLocale.t("Swap Top and Bottom"))
		_set_item_text(MenuId.ROTATE, CandyLocale.t("Place Side by Side"))
	_menu.set_item_disabled(_menu.get_item_index(MenuId.EQUALIZE),
		data.size_mode != CandyAreaData.SizeMode.RATIO or not data.can_resize)

	_set_item_text(MenuId.REMOVE_FIRST, remove_first % _names_of(data.first))
	_set_item_text(MenuId.REMOVE_SECOND, remove_second % _names_of(data.second))
	_menu.set_item_disabled(_menu.get_item_index(MenuId.REMOVE_FIRST), not _removable(data.first))
	_menu.set_item_disabled(_menu.get_item_index(MenuId.REMOVE_SECOND), not _removable(data.second))


func _set_item_text(id: int, item_text: String) -> void:
	_menu.set_item_text(_menu.get_item_index(id), item_text)


func _removable(child: CandyAreaData) -> bool:
	if not _can_remove.is_valid():
		return true
	return bool(_can_remove.call(child))


#* Names of the Areas inside a part of the tree ("Navigator, Preview +2 more"):
func _names_of(area: CandyAreaData) -> String:
	var leaves: Array[CandyAreaData] = []
	area.collect_leaves(leaves)
	var titles := PackedStringArray()
	for leaf in leaves:
		if titles.size() >= AREA_NAMES_SHOWN:
			break
		titles.append(_title(leaf.panel_id))
	var text := ", ".join(titles)
	var extra := leaves.size() - titles.size()
	if extra > 0:
		text = CandyLocale.t("{names} +{count} more").format({"names": text, "count": extra})
	return text


func _title(panel_id: String) -> String:
	if _title_of.is_valid():
		return str(_title_of.call(panel_id))
	return panel_id


func _on_menu_id_pressed(id: int) -> void:
	if _layout_menu != null and _layout_menu.handle_id(id):
		return
	match id:
		MenuId.ADD_LEFT:
			edit_requested.emit("wrap", data, [CandyAreaData.Layout.LEFT_RIGHT, true])
		MenuId.ADD_RIGHT:
			edit_requested.emit("wrap", data, [CandyAreaData.Layout.LEFT_RIGHT, false])
		MenuId.ADD_ABOVE:
			edit_requested.emit("wrap", data, [CandyAreaData.Layout.TOP_BOTTOM, true])
		MenuId.ADD_BELOW:
			edit_requested.emit("wrap", data, [CandyAreaData.Layout.TOP_BOTTOM, false])
		MenuId.INSERT_BETWEEN:
			edit_requested.emit("insert", data, null)
		MenuId.SWAP:
			edit_requested.emit("swap", data, null)
		MenuId.ROTATE:
			edit_requested.emit("rotate", data, null)
		MenuId.EQUALIZE:
			_equalize()
		MenuId.REMOVE_FIRST:
			edit_requested.emit("remove", data.first, null)
		MenuId.REMOVE_SECOND:
			edit_requested.emit("remove", data.second, null)


#& Divider

#^ The divider. Its tooltip shows the sides' sizes:
class Handle extends Control:
	var split: CandyAreaSplit

	func _get_tooltip(_at_position: Vector2) -> String:
		if split == null:
			return ""
		return split.size_tooltip()

	#* Centered tooltip, so a stacked split's dash sits between its sizes:
	func _make_custom_tooltip(for_text: String) -> Object:
		var label := Label.new()
		label.theme_type_variation = &"TooltipLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = for_text
		return label