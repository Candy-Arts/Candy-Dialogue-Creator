#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyBottomReach
extends Container

#^ The bottom widgets' height changed, and the tab's ratios with it - to be stored:
signal ratios_changed

#^ (to: float, down: bool) - moves the bottom dragger to that height, when widgets at the bottom are hidden or shown:
var move_dragger: Callable

var _content: Control
#^ The widgets' own height, the room hidden widgets keep included (0: not laid out yet):
var _nominal := 0.0
#^ The room hidden widgets keep at the bottom of their column - their height moves the dragger:
var _room := 0.0


#* Hold the tab's widgets (its root view):
func setup(content: Control) -> void:
	_content = content
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)


#* The dragger stops where the bottom widgets reach their minimum height:
func _get_minimum_size() -> Vector2:
	if _content == null:
		return Vector2.ZERO
	var result := _content.get_combined_minimum_size()
	if _nominal > 0.0:
		result.y = maxf(result.y, CandyAreaCap.least_height_of(_content, _nominal))
	return result


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN or _content == null:
		return
	_follow_size()
	var extra := Vector2.ZERO
	var grow := Vector2i.ZERO
	if absf(size.y - _nominal) >= 1.0:
		extra.y = size.y - _nominal			#/ Negative: the room hidden widgets keep
		grow.y = 1
	CandyAreaCap.pass_growth(_content, extra, grow)
	fit_child_in_rect(_content, Rect2(Vector2.ZERO, size))


#* Keep every widget's height as the dragger's height changes, but the bottom ones':
func _follow_size() -> void:
	#% First layout - the ratios share out what the dragger gives:
	if _nominal <= 0.0:
		_nominal = size.y
		_room = _nominal - CandyAreaCap.used_height_of(_content, _nominal)
		update_minimum_size()
		return

	#@ Step 1 - Widgets at the bottom hidden or shown: the dragger moves by their height, the widgets keep theirs:
	var room: float = _nominal - CandyAreaCap.used_height_of(_content, _nominal)
	if absf(room - _room) >= 0.5:
		var shown_more := room < _room
		_room = room
		update_minimum_size()
		if move_dragger.is_valid():
			#? Not from its size now: a widget shown may already have raised it to its minimum.
			move_dragger.call(_nominal - _room, shown_more)
			return			#/ Laid out again at the dragger's new place

	#@ Step 2 - The dragger moved (or the Editor resized): only the bottom widgets take the difference:
	var wanted := size.y + _room
	if absf(wanted - _nominal) < 0.5:
		return
	var least: float = CandyAreaCap.least_height_of(_content, _nominal)
	var delta := maxf(wanted - _nominal, least + _room - _nominal)
	CandyAreaCap.give_bottom_of(_content, _nominal, delta)
	_nominal += delta
	update_minimum_size()
	ratios_changed.emit()
