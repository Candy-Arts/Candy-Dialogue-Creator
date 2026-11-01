#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFoldHeader
extends Button

signal fold_toggled(folded: bool)

var folded: bool = false


func _init(category_name: String = "", p_folded: bool = false) -> void:
	text = category_name
	flat = true
	theme_type_variation = CandyThemeDefaults.FLAT_BUTTON
	focus_mode = Control.FOCUS_NONE
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	tooltip_text = CandyLocale.t("Fold or unfold this category")
	folded = p_folded
	pressed.connect(func():
		folded = not folded
		_update_icon()
		fold_toggled.emit(folded))


func _ready() -> void:
	_update_icon()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_icon()


func _update_icon() -> void:
	var icon_name := "arrow"
	if folded:
		icon_name = "arrow_collapsed"
	if has_theme_icon(icon_name, "Tree"):
		icon = get_theme_icon(icon_name, "Tree")
