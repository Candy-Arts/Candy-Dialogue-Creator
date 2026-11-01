#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyNavigatorRow
extends Control

const INDENT := 14.0
const ARROW_WIDTH := 14.0
const ARROW_SIZE := 4.0
const PADDING_X := 4.0
const PADDING_Y := 3.0
const CORNER_RADIUS := 3
#^ Text outline width, when the state has an outline color:
const OUTLINE_SIZE := 3

var row: Dictionary = {}
var state := "normal"

var _bg_style := StyleBoxFlat.new()
var _border_style := StyleBoxFlat.new()
var _frame_style := StyleBoxFlat.new()
var _font: Font
var _font_size: int = 12


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  #/ The list handles all input
	_bg_style.set_corner_radius_all(CORNER_RADIUS)
	_border_style.set_corner_radius_all(CORNER_RADIUS)
	_border_style.draw_center = false
	_border_style.set_border_width_all(CandyNavigatorColors.BORDER_WIDTH)
	_frame_style.draw_center = false


#* The width of the frame a row draws around itself:
static func frame_width(p_row: Dictionary) -> int:
	var states = p_row.get("states", {})
	if states is Dictionary:
		return int(states.get("frame_width", CandyNavigatorColors.FRAME_WIDTH))
	return CandyNavigatorColors.FRAME_WIDTH


static func row_height(font: Font, font_size: int) -> float:
	var height: float
	if font != null:
		height = font.get_height(font_size)
	else:
		height = float(font_size) * 1.4
	return ceilf(height + PADDING_Y * 2.0)


#* How far in a row starts, under its conversation or block:
static func row_indent(depth: int) -> float:
	return INDENT * float(depth)


#* Where the text starts, from the row's left edge:
static func text_offset(p_row: Dictionary) -> float:
	if p_row.has("text_indent"):
		return float(p_row["text_indent"])
	#Ł Its kind's default:
	if p_row.get("foldable", false):
		return float(CandyNavigatorColors.DEFAULT_TEXT_INDENTS["conversation"])
	return float(CandyNavigatorColors.DEFAULT_TEXT_INDENTS["line"])


#* Where the fold arrow starts, right before the text:
static func arrow_start(p_row: Dictionary) -> float:
	return text_offset(p_row) - ARROW_WIDTH


#* Set the node up for a row:
func update_row(p_row: Dictionary, font: Font) -> void:
	row = p_row
	_font = font
	_font_size = int(p_row["font_size"])
	var widths = p_row.get("states", {}).get("widths", {})
	if not widths is Dictionary:
		widths = {}
	_border_style.border_width_left = int(widths.get("left", CandyNavigatorColors.BORDER_WIDTH))
	_border_style.border_width_top = int(widths.get("top", CandyNavigatorColors.BORDER_WIDTH))
	_border_style.border_width_right = int(widths.get("right", CandyNavigatorColors.BORDER_WIDTH))
	_border_style.border_width_bottom = int(widths.get("bottom", CandyNavigatorColors.BORDER_WIDTH))
	var frame := frame_width(p_row)
	_frame_style.set_border_width_all(frame)
	_frame_style.set_corner_radius_all(CORNER_RADIUS + frame)
	queue_redraw()


func set_state(value: String) -> void:
	if state == value:
		return
	state = value
	queue_redraw()


#* The current state's colors, falling back on normal:
func _look() -> Dictionary:
	var states = row.get("states", {})
	if states is Dictionary:
		if states.get(state) is Dictionary:
			return states[state]
		if states.get("normal") is Dictionary:
			return states["normal"]
	return {}


func _draw() -> void:
	if row.is_empty() or _font == null:
		return

	var look := _look()
	_bg_style.bg_color = look.get("bg", Color.TRANSPARENT)
	_border_style.border_color = look.get("border", Color.TRANSPARENT)
	_frame_style.border_color = look.get("frame", Color.TRANSPARENT)
	var text_color: Color = look.get("text", Color.WHITE)
	var outline_color: Color = look.get("outline", Color.TRANSPARENT)

	var rect := _row_rect()
	_bg_style.draw(get_canvas_item(), rect)
	if _border_style.border_color.a > 0.0:
		_border_style.draw(get_canvas_item(), rect)
	var frame := frame_width(row)
	if frame > 0 and _frame_style.border_color.a > 0.0:
		_frame_style.draw(get_canvas_item(), rect.grow(frame))

	if row["foldable"]:
		_draw_arrow(rect.position.x + arrow_start(row), rect.get_center().y, bool(row["folded"]), text_color)

	var x := rect.position.x + text_offset(row)
	var baseline := rect.position.y + PADDING_Y + _font.get_ascent(_font_size)
	var width := maxf(0.0, rect.end.x - x - PADDING_X)
	var text := str(row["text"])
	if outline_color.a > 0.0:
		draw_string_outline(_font, Vector2(x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT,
			width, _font_size, OUTLINE_SIZE, outline_color)
	draw_string(_font, Vector2(x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT,
		width, _font_size, text_color)


#* Where the row is drawn - the whole node (the frame goes around it):
func _row_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)


func _draw_arrow(x: float, center_y: float, folded: bool, color: Color) -> void:
	var center := Vector2(x + ARROW_WIDTH * 0.5, center_y)
	var points := PackedVector2Array()
	if folded:
		points.append(center + Vector2(-ARROW_SIZE * 0.5, -ARROW_SIZE))
		points.append(center + Vector2(-ARROW_SIZE * 0.5, ARROW_SIZE))
		points.append(center + Vector2(ARROW_SIZE * 0.8, 0))
	else:
		points.append(center + Vector2(-ARROW_SIZE, -ARROW_SIZE * 0.5))
		points.append(center + Vector2(ARROW_SIZE, -ARROW_SIZE * 0.5))
		points.append(center + Vector2(0, ARROW_SIZE * 0.8))
	draw_colored_polygon(points, color)
