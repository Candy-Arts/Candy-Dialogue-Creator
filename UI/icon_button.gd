#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyIconButton
extends Button

var icon_name: StringName
var icon_type: StringName
var fallback_text := ""


func _init(p_icon_name: StringName = &"", p_icon_type: StringName = CandyThemeDefaults.ICONS,
		p_fallback_text: String = "", tooltip: String = "") -> void:
	icon_name = p_icon_name
	icon_type = p_icon_type
	fallback_text = p_fallback_text
	tooltip_text = tooltip
	focus_mode = Control.FOCUS_NONE


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_icon()


func _update_icon() -> void:
	if has_theme_icon(icon_name, icon_type):
		icon = get_theme_icon(icon_name, icon_type)
		text = ""
	else:
		icon = null
		text = fallback_text
	var font_height := get_theme_font("font", "Button").get_height(get_theme_font_size("font_size", "Button"))
	custom_minimum_size.y = font_height + get_theme_stylebox("normal", "Button").get_minimum_size().y
