#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAreaButton
extends Button

#^ Texts (+ for a leaf, the split's direction for a split):
const LEAF_TEXT := "+"
const TOOLTIP := "Area Settings"      #/ translatable
const SIDE_BY_SIDE_TEXT := "◧"
const STACKED_TEXT := "⬒"

signal highlight_changed(area: CandyAreaData, highlighted: bool)

var area: CandyAreaData
#^ Dragging it moves its Area (see CandyAreaFrame.around_leaf()), which its tooltip says:
var draggable := false

#^ Opens the menu under a screen rectangle and returns it:
var _open_menu: Callable
var _hovered := false
var _menu_open := false


#* Set up the button:
#? open_menu(anchor: Rect2i) -> PopupMenu
func setup(p_area: CandyAreaData, open_menu: Callable) -> void:
	area = p_area
	_open_menu = open_menu
	flat = true
	focus_mode = Control.FOCUS_NONE
	tooltip_text = CandyLocale.t(TOOLTIP)
	if area.is_leaf():
		text = LEAF_TEXT
	elif area.layout == CandyAreaData.Layout.LEFT_RIGHT:
		text = SIDE_BY_SIDE_TEXT
	else:
		text = STACKED_TEXT
	mouse_entered.connect(func(): _set_state(true, _menu_open))
	mouse_exited.connect(func(): _set_state(false, _menu_open))
	pressed.connect(_on_pressed)


#* Its tooltip, with the drag keys as they're set now:
func _get_tooltip(_at_position: Vector2) -> String:
	if not draggable:
		return tooltip_text
	return tooltip_text + "\n" + CandyAreaDrag.hint()


func _on_pressed() -> void:
	var anchor := Rect2i(Vector2i(get_screen_position()), Vector2i(size))
	var menu = _open_menu.call(anchor)
	if not menu is PopupMenu:
		return
	var popup: PopupMenu = menu
	_set_state(_hovered, true)
	if not popup.popup_hide.is_connected(_on_menu_hidden):
		popup.popup_hide.connect(_on_menu_hidden, CONNECT_ONE_SHOT)


func _on_menu_hidden() -> void:
	_set_state(_hovered, false)


func _set_state(hovered: bool, menu_open: bool) -> void:
	var was := _hovered or _menu_open
	_hovered = hovered
	_menu_open = menu_open
	var now := _hovered or _menu_open
	if now != was:
		highlight_changed.emit(area, now)
