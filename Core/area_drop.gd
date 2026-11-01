#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAreaDrop
extends RefCounted

#^ Where an Area is dropped on another: on it (CENTER), or beside it, on a side:
enum Zone { CENTER, LEFT, RIGHT, TOP, BOTTOM }
#^ MOVE takes it from its place, COPY leaves it there, SWAP trades places (CENTER only):
enum Mode { MOVE, COPY, SWAP }

#^ The part of an Area's width or height, from a side, that drops beside it:
const EDGE_SHARE := 0.25


#* The zone of an Area of a size that a point falls in:
static func zone_at(area_size: Vector2, point: Vector2) -> Zone:
	if area_size.x <= 0.0 or area_size.y <= 0.0:
		return Zone.CENTER
	var distances := {
		Zone.LEFT: point.x / area_size.x,
		Zone.RIGHT: 1.0 - point.x / area_size.x,
		Zone.TOP: point.y / area_size.y,
		Zone.BOTTOM: 1.0 - point.y / area_size.y,
	}
	var nearest: Zone = Zone.CENTER
	var nearest_distance := EDGE_SHARE
	for zone: Zone in distances:
		if distances[zone] < nearest_distance:
			nearest = zone
			nearest_distance = distances[zone]
	return nearest


#* Whether a drop changes anything at all (locks aside):
#? source and target are leaves of one tree.
static func changes(source: CandyAreaData, target: CandyAreaData, zone: Zone, mode: Mode) -> bool:
	if source == null or target == null or not source.is_leaf() or not target.is_leaf():
		return false
	if source != target:
		return true
	#% Onto itself - only a copy beside it does something:
	return mode == Mode.COPY and zone != Zone.CENTER


#* Drop source onto target, and return the tree's root afterwards:
#? copy: what COPY places (a copy of source); ignored otherwise.
#! Check changes() and the locks first.
static func apply(source: CandyAreaData, target: CandyAreaData, zone: Zone, mode: Mode,
		copy: CandyAreaData = null) -> CandyAreaData:
	if mode == Mode.SWAP and zone == Zone.CENTER:
		source.swap_with(target)
		return source.root_area()

	var placed := copy
	if mode != Mode.COPY:
		placed = source
		source.detach()

	#¦ 1. On the target - in its place:
	if zone == Zone.CENTER:
		var parent := target.get_parent_area()
		if parent != null:
			parent.replace_child(target, placed)
	#¦ 2. Beside it:
	else:
		var direction := CandyAreaData.Layout.LEFT_RIGHT
		if zone == Zone.TOP or zone == Zone.BOTTOM:
			direction = CandyAreaData.Layout.TOP_BOTTOM
		#? Kept in a variable: parents are weak, so a new root split would be freed before it's returned.
		var split := target.wrap_with(placed, direction, zone == Zone.LEFT or zone == Zone.TOP)
		return split.root_area()
	return placed.root_area()
