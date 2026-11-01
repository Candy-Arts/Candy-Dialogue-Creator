#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyListRows
extends VBoxContainer


func _init() -> void:
	theme_type_variation = CandyThemeDefaults.ROOMY_VBOX
	sort_children.connect(queue_redraw)


func _draw() -> void:
	var color := get_theme_color(&"line_color", CandyThemeDefaults.LIST_BOX)
	var gap := get_theme_constant(&"separation")
	var previous: Control = null
	for child in get_children():
		var row := child as Control
		if row == null or not row.visible:
			continue
		if previous != null:
			var y := row.position.y - gap / 2.0
			draw_line(Vector2(0, y), Vector2(size.x, y), color)
		previous = row
