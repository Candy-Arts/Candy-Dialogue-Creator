#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyColorSwatchButton
extends ColorPickerButton

#^ Segments per rounded corner of the checkered background:
const CORNER_SEGMENTS := 8


func _init() -> void:
	#? The checkered background is one small tiled texture.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _draw() -> void:
	var style := get_theme_stylebox(&"normal") as StyleBoxFlat
	if style == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	if color.a < 1.0:
		_draw_checkers(style, rect)
	var face: StyleBoxFlat = style.duplicate()
	face.bg_color = color
	face.draw_center = true
	face.draw(get_canvas_item(), rect)


#* Draw the checkered background in the face's shape:
func _draw_checkers(style: StyleBoxFlat, rect: Rect2) -> void:
	var checkers := get_theme_icon(&"bg")
	if checkers == null or checkers.get_width() <= 0 or checkers.get_height() <= 0:
		return
	var inset := maxf(float(style.get_border_width_min()) * 0.5, 0.5)	#/ Halfway under the border, so it never shows past the rounded edge
	var inner := rect.grow(-inset)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return
	#? A StyleBoxFlat never rounds past half its shorter side.
	var limit := minf(rect.size.x, rect.size.y) * 0.5
	var left := inner.position.x
	var top := inner.position.y
	var right := inner.end.x
	var bottom := inner.end.y
	#? Each corner - [position, direction to its center, radius, start angle], clockwise from top left.
	var corners := [
		[Vector2(left, top), Vector2(1, 1), style.corner_radius_top_left, PI],
		[Vector2(right, top), Vector2(-1, 1), style.corner_radius_top_right, PI * 1.5],
		[Vector2(right, bottom), Vector2(-1, -1), style.corner_radius_bottom_right, 0.0],
		[Vector2(left, bottom), Vector2(1, -1), style.corner_radius_bottom_left, PI * 0.5],
	]
	var points := PackedVector2Array()
	for corner: Array in corners:
		var radius := minf(float(corner[2]), limit) - inset
		if radius <= 0.0:
			points.append(corner[0])
			continue
		var center: Vector2 = corner[0] + corner[1] * radius
		for step in CORNER_SEGMENTS + 1:
			var angle: float = corner[3] + PI * 0.5 * float(step) / float(CORNER_SEGMENTS)
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	var tile := Vector2(checkers.get_size())
	var uvs := PackedVector2Array()
	for point in points:
		uvs.append(point / tile)
	draw_colored_polygon(points, Color.WHITE, uvs, checkers)
