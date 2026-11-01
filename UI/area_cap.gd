#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAreaCap
extends Container

#^ The most its content gets; a component of 0 has no maximum:
var max_size := Vector2.ZERO

var _content: Control


#* An Area's view, held to the maximum size of its config (the view itself when it has none):
static func around(view: Control, config: Dictionary) -> Control:
	var limit := Vector2(CandyMinSizeFields.max_of_config(config))
	if limit == Vector2.ZERO:
		return view
	var cap := CandyAreaCap.new()
	cap.max_size = limit
	cap._content = view
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_child(view)
	#Ł Hidden with its content (a filtered widget), so a split gives its space to the other side:
	cap.visible = view.visible
	view.visibility_changed.connect(func(): cap.visible = view.visible)
	return cap


#* The most an Area's view can use - INF where there's no maximum:
#? A cap, a split (its sides') and a frame (its content's) answer through area_max_size().
static func max_of(view: Control) -> Vector2:
	if view != null and view.has_method(&"area_max_size"):
		return view.call(&"area_max_size")
	return Vector2(INF, INF)


#* Give an Area's view the room hidden Areas left (CandyAreaSplit.set_area_growth()):
#? A cap and a frame hand it to their content; a split shares it out; a leaf just fills it.
static func pass_growth(view: Control, extra: Vector2, grow: Vector2i) -> void:
	if view != null and view.has_method(&"set_area_growth"):
		view.call(&"set_area_growth", extra, grow)


func set_area_growth(extra: Vector2, grow: Vector2i) -> void:
	pass_growth(_content, extra, grow)


#* Change an Area's bottom Areas' height by delta (CandyAreaSplit.give_bottom()):
#? A leaf just gets its new rect.
static func give_bottom_of(view: Control, height: float, delta: float) -> void:
	if view != null and view.has_method(&"give_bottom"):
		view.call(&"give_bottom", height, delta)


func give_bottom(height: float, delta: float) -> void:
	give_bottom_of(_content, height, delta)


#* How much of a height an Area's view uses, given that height (CandyAreaSplit.used_height()):
#? A leaf uses all of it; a stacked split with hidden Areas less.
static func used_height_of(view: Control, height: float) -> float:
	if view != null and view.has_method(&"used_height"):
		return view.call(&"used_height", height)
	return height


func used_height(height: float) -> float:
	return used_height_of(_content, height)


#* The least height an Area's view can take, when only its bottom Areas shrink (CandyAreaSplit.least_height()):
#? A leaf: its minimum height.
static func least_height_of(view: Control, height: float) -> float:
	if view != null and view.has_method(&"least_height"):
		return view.call(&"least_height", height)
	if view == null:
		return 0.0
	return view.get_combined_minimum_size().y


func least_height(height: float) -> float:
	return least_height_of(_content, height)


func area_max_size() -> Vector2:
	var result := Vector2(INF, INF)
	var least := Vector2.ZERO
	if _content != null:
		least = _content.get_combined_minimum_size()
	for axis in 2:
		if max_size[axis] > 0.0:
			result[axis] = maxf(max_size[axis], least[axis])			#/ The minimum wins
	return result


func _get_minimum_size() -> Vector2:
	if _content == null:
		return Vector2.ZERO
	return _content.get_combined_minimum_size()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and _content != null:
		#? In its top-left corner, when the Area is bigger than the maximum.
		fit_child_in_rect(_content, Rect2(Vector2.ZERO, size.min(area_max_size())))
