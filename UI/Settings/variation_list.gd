#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationList
extends ScrollContainer

signal row_pressed(id: String)
signal disable_pressed(id: String)
signal fold_pressed(id: String)
signal hide_pressed(id: String)

const ROW_HEIGHT := 28
const INDENT := 18
const OVERSCAN := 2

#^ Lines between the rows:
var show_guides := false:
	set(value):
		show_guides = value
		if _content != null:
			_content.queue_redraw()

#^ Highlighted row, in pickable lists:
var selected_id: String = "":
	set(value):
		selected_id = value
		_update_visible()

var _rows: Array = []
var _content: Control
var _active: Dictionary = {}     #/ Row index -> Row
var _pool: Array = []
var _row_height := ROW_HEIGHT


class Row extends HBoxContainer:
	var index: int = -1
	var fold_button: Button
	var label: Label
	var hide_button: Button
	var disable_button: Button
	var spacer: Control


func _init() -> void:
	theme_type_variation = CandyThemeDefaults.WIDGET_LIST


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content = Control.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.draw.connect(_draw_rows)
	add_child(_content)
	#Ł Redraw the hover background as the mouse moves over the content:
	_content.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseMotion and _pickable():
			_content.queue_redraw())
	mouse_exited.connect(_content.queue_redraw)
	get_v_scroll_bar().value_changed.connect(func(_value: float): _update_visible())
	get_v_scroll_bar().visibility_changed.connect(_update_visible)
	resized.connect(_update_visible)
	_content.resized.connect(_update_visible)


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_row_height()


func set_rows(rows: Array) -> void:
	_rows = rows
	_update_row_height()


func _update_row_height() -> void:
	if _content == null:
		return
	_row_height = ROW_HEIGHT
	if _has_buttons():
		var font_height := get_theme_font("font", "Button").get_height(get_theme_font_size("font_size", "Button"))
		var button_height := font_height + get_theme_stylebox("normal", "Button").get_minimum_size().y
		_row_height = maxi(ROW_HEIGHT, ceili(button_height) + get_theme_constant(&"row_gap"))
	_content.custom_minimum_size.y = _rows.size() * _row_height
	for index in _active.keys():
		_release(index)
	_update_visible()


func _has_buttons() -> bool:
	for data in _rows:
		if bool(data.get("foldable", false)) or bool(data.get("hideable", false)):
			return true
		if bool(data.get("disableable", true)):
			return true
	return false


#* Get the rows' width (less the scrollbar and its gap while it shows):
func _row_width() -> float:
	var width := _content.size.x
	if get_v_scroll_bar().visible:
		width -= get_theme_constant(&"scrollbar_gap")
	return maxf(0.0, width)


#* Check whether rows are picked from this list:
func _pickable() -> bool:
	return not row_pressed.get_connections().is_empty()


#* Get the Tree's inner margins, which a pickable list's rows keep - [left, right]:
func _row_margins() -> Array:
	if not _pickable():
		return [0, 0]
	return [get_theme_constant(&"inner_item_margin_left", &"Tree"),
		get_theme_constant(&"inner_item_margin_right", &"Tree")]


#* Get the row under the mouse, or -1:
func _hovered_index() -> int:
	if not _pickable() or not get_global_rect().has_point(get_global_mouse_position()):
		return -1
	var y := _content.get_local_mouse_position().y
	if y < 0.0:
		return -1
	var index := int(y / _row_height)
	if index >= _rows.size():
		return -1
	return index


func _draw_rows() -> void:
	var width := _row_width()
	var hovered := _hovered_index()
	for index in _active.keys():
		var is_selected := selected_id != "" and str(_rows[index].get("id", "")) == selected_id
		var style_name := &""
		if is_selected and index == hovered:
			style_name = &"hovered_selected"
		elif is_selected:
			style_name = &"selected"
		elif index == hovered:
			style_name = &"hovered"
		if style_name != &"" and has_theme_stylebox(style_name, &"Tree"):
			var rect := Rect2(0, index * _row_height, width, _row_height)
			_content.draw_style_box(get_theme_stylebox(style_name, &"Tree"), rect)

	if not show_guides:
		return
	var color := get_theme_color(&"line_color")
	for index in _active.keys():
		if index == 0:
			continue
		var y := float(index * _row_height)
		var x := float(INDENT * int(_rows[index].get("indent", 0)))
		_content.draw_line(Vector2(x, y), Vector2(width, y), color)


func row_count() -> int:
	return _rows.size()


func _update_visible() -> void:
	if _content == null:
		return
	@warning_ignore("integer_division")
	var first := maxi(0, int(scroll_vertical / _row_height) - OVERSCAN)
	var visible_count := int(size.y / _row_height) + OVERSCAN * 2 + 1
	var last := mini(_rows.size() - 1, first + visible_count)

	for index in _active.keys():
		if index < first or index > last:
			_release(index)

	for index in range(first, last + 1):
		var row: Row = _active.get(index)
		if row == null:
			row = _take()
			_active[index] = row
		_apply(row, index)
	_content.queue_redraw()


func _take() -> Row:
	if not _pool.is_empty():
		var pooled: Row = _pool.pop_back()
		pooled.visible = true
		return pooled
	return _build_row()


func _release(index: int) -> void:
	var row: Row = _active.get(index)
	if row == null:
		return
	row.visible = false
	_active.erase(index)
	_pool.append(row)


#* Build a pooled row:
func _build_row() -> Row:
	var row := Row.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	_content.add_child(row)

	#? Buttons read the row's current index, so recycled rows need no reconnecting.
	row.fold_button = Button.new()
	row.fold_button.custom_minimum_size.x = 26
	row.fold_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.fold_button.focus_mode = Control.FOCUS_NONE
	row.fold_button.pressed.connect(func(): _emit(fold_pressed, row))
	row.add_child(row.fold_button)

	row.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_emit(row_pressed, row))

	row.label = Label.new()
	row.label.clip_text = true
	row.label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(row.label)

	row.hide_button = Button.new()
	row.hide_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.hide_button.focus_mode = Control.FOCUS_NONE
	row.hide_button.pressed.connect(func(): _emit(hide_pressed, row))
	row.add_child(row.hide_button)

	row.disable_button = Button.new()
	row.disable_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.disable_button.focus_mode = Control.FOCUS_NONE
	row.disable_button.pressed.connect(func(): _emit(disable_pressed, row))
	row.add_child(row.disable_button)

	return row


func _apply(row: Row, index: int) -> void:
	var data: Dictionary = _rows[index]
	row.index = index
	var margins := _row_margins()
	var indent: int = INDENT * int(data.get("indent", 0)) + margins[0]
	row.position = Vector2(indent, index * _row_height)
	row.size = Vector2(maxf(0.0, _row_width() - indent - margins[1]), _row_height)

	row.label.text = str(data.get("text", ""))
	var disabled := bool(data.get("disabled", false))
	var is_hidden := bool(data.get("hidden", false))
	if str(data.get("id", "")) == selected_id and selected_id != "":
		row.label.theme_type_variation = CandyThemeDefaults.HIGHLIGHT
	elif disabled or is_hidden or bool(data.get("muted", false)):
		row.label.theme_type_variation = CandyThemeDefaults.NOTE
	else:
		row.label.theme_type_variation = &""

	row.fold_button.visible = bool(data.get("foldable", false))
	if row.fold_button.visible:
		if bool(data.get("folded", false)):
			row.fold_button.text = "+"
		else:
			row.fold_button.text = "-"

	row.hide_button.visible = bool(data.get("hideable", false))
	if row.hide_button.visible:
		if is_hidden:
			row.hide_button.text = CandyLocale.t("Show")
		else:
			row.hide_button.text = CandyLocale.t("Hide")

	row.disable_button.visible = bool(data.get("disableable", true))
	if row.disable_button.visible:
		if disabled:
			row.disable_button.text = CandyLocale.t("Enable")
		else:
			row.disable_button.text = CandyLocale.t("Disable")


func _emit(target: Signal, row: Row) -> void:
	if row.index < 0 or row.index >= _rows.size():
		return
	target.emit(str(_rows[row.index].get("id", "")))