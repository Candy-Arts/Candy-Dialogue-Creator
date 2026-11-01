#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAreaData
extends RefCounted

#^ LEFT_RIGHT = side by side, TOP_BOTTOM = stacked:
enum Layout { LEFT_RIGHT, TOP_BOTTOM }

#^ How a split sizes its children:
#? RATIO:        first child gets `ratio` of the space.
#? FIXED_FIRST:  first child is `fixed_size` px (0 = its minimum size).
#? FIXED_SECOND: same, for the second child.
enum SizeMode { RATIO, FIXED_FIRST, FIXED_SECOND }

static var _next_id: int = 1

#^ Runtime-only unique id (not saved):
var id: int

#& Leaf properties
var panel_id: String = ""
#^ Saved id of a line UI's area, for filters (CandyFilters):
#? Given by CandyLineLayouts; "" elsewhere.
var uid: String = ""
#^ Leaf settings - "min_width" / "min_height", and a line UI widget's settings:
var config: Dictionary = {}
#^ Panel state, captured on save, handed to the panel on creation:
var panel_state: Dictionary = {}
var can_change_panel: bool = true
var can_split: bool = true
var can_close: bool = true
var show_header: bool = true

#& Split properties
var layout: Layout = Layout.LEFT_RIGHT
var ratio: float = 0.5
var size_mode: SizeMode = SizeMode.RATIO
var fixed_size: float = 0.0
#^ Whether the divider can be dragged:
var can_resize: bool = true
#^ Whether this split may disappear when a child is closed:
var can_collapse: bool = true
var first: CandyAreaData = null
var second: CandyAreaData = null

#^ Weak, so a parent <-> child cycle doesn't leak:
var _parent_ref: WeakRef = null


func _init() -> void:
	id = _next_id
	_next_id += 1


#& Construction

static func make_leaf(p_panel_id: String) -> CandyAreaData:
	var a := CandyAreaData.new()
	a.panel_id = p_panel_id
	return a


static func make_split(p_layout: Layout, a: CandyAreaData, b: CandyAreaData, p_ratio: float = 0.5) -> CandyAreaData:
	var s := CandyAreaData.new()
	s.layout = p_layout
	s.ratio = p_ratio
	s.set_children(a, b)
	return s


#& Tree helpers

func is_leaf() -> bool:
	return first == null


func get_parent_area() -> CandyAreaData:
	if _parent_ref == null:
		return null
	return _parent_ref.get_ref()


func set_parent_area(p: CandyAreaData) -> void:
	if p == null:
		_parent_ref = null
	else:
		_parent_ref = weakref(p)


func set_children(a: CandyAreaData, b: CandyAreaData) -> void:
	first = a
	second = b
	a.set_parent_area(self)
	b.set_parent_area(self)


func replace_child(old_child: CandyAreaData, new_child: CandyAreaData) -> void:
	if first == old_child:
		first = new_child
	elif second == old_child:
		second = new_child
	else:
		push_error("replace_child: area %d is not a child of %d" % [old_child.id, id])
		return
	old_child.set_parent_area(null)
	new_child.set_parent_area(self)


#* Before a child goes and its sibling takes this split's place - keep the sibling's Areas their size:
#? Only the side of the sibling beside the child takes the child's room (its ratios change).
func keep_sizes_without(child: CandyAreaData) -> void:
	if is_leaf() or size_mode != SizeMode.RATIO:
		return			#/ A fixed size is already kept in pixels
	if child == first:
		second._grow_into(ratio, layout, true)
	elif child == second:
		first._grow_into(1.0 - ratio, layout, false)


#* Grow to the whole of its parent's room, the part of it that's new (share) at its start or end:
func _grow_into(share: float, along: Layout, at_start: bool) -> void:
	if is_leaf() or share <= 0.0 or share >= 1.0:
		return
	#¦ 1. Across the growth - both sides grow alike:
	if layout != along:
		first._grow_into(share, along, at_start)
		second._grow_into(share, along, at_start)
		return
	#¦ 2. A fixed side keeps its pixels - the other side grows:
	if size_mode == SizeMode.FIXED_FIRST:
		second._grow_into(share, along, at_start)			#/ Approximate: its share of the room isn't known
		return
	if size_mode == SizeMode.FIXED_SECOND:
		first._grow_into(share, along, at_start)
		return
	#¦ 3. Along it - only the side beside the new part grows:
	var kept := 1.0 - share
	if at_start:
		var new_ratio := ratio * kept + share
		first._grow_into(share / new_ratio, along, true)
		ratio = new_ratio
	else:
		var new_ratio := ratio * kept
		second._grow_into(share / (1.0 - new_ratio), along, false)
		ratio = new_ratio


func sibling_of(child: CandyAreaData) -> CandyAreaData:
	if child == first:
		return second
	return first


func find_area(target_id: int) -> CandyAreaData:
	if id == target_id:
		return self
	if is_leaf():
		return null
	var found := first.find_area(target_id)
	if found != null:
		return found
	return second.find_area(target_id)


func collect_leaves(out: Array[CandyAreaData]) -> void:
	if is_leaf():
		out.append(self)
	else:
		first.collect_leaves(out)
		second.collect_leaves(out)


#* Clear every leaf's uid (for a copy):
func clear_uids() -> void:
	var leaves: Array[CandyAreaData] = []
	collect_leaves(leaves)
	for leaf in leaves:
		leaf.uid = ""


#* The root of this Area's tree:
func root_area() -> CandyAreaData:
	var current := self
	while current.get_parent_area() != null:
		current = current.get_parent_area()
	return current


func first_leaf() -> CandyAreaData:
	if is_leaf():
		return self
	return first.first_leaf()


#* How many Areas sit in a row in a direction, along the busiest line:
func count_along(direction: Layout) -> int:
	if is_leaf():
		return 1
	var a := first.count_along(direction)
	var b := second.count_along(direction)
	if layout == direction:
		return a + b
	return maxi(a, b)


#& Structural edits
#? Only rearrange the tree: managers (CandyLayout, CandyLineLayouts) check the
#? locks, replace the root and announce the change.

#* Put this Area and new_leaf side by side in a new split, in its place:
#? With no parent, the caller makes the returned split the root.
func wrap_with(new_leaf: CandyAreaData, direction: Layout, new_area_first: bool) -> CandyAreaData:
	var share := 1.0 / float(count_along(direction) + 1)			#/ 1/2 beside one Area, 1/3 beside two...
	var split := CandyAreaData.new()
	split.layout = direction
	if new_area_first:
		split.ratio = share
	else:
		split.ratio = 1.0 - share

	var parent := get_parent_area()
	if parent != null:
		parent.replace_child(self, split)
	if new_area_first:
		split.set_children(new_leaf, self)
	else:
		split.set_children(self, new_leaf)
	return split


#* Put new_leaf between this split's sides: [first | [new | second]]:
func insert_between(new_leaf: CandyAreaData) -> void:
	if is_leaf():
		return
	var share := 1.0 / float(count_along(layout) + 1)			#/ wrap_with()'s share
	var inner := CandyAreaData.new()
	inner.layout = layout

	if size_mode == SizeMode.FIXED_SECOND:
		#% [[first | new] | second] - second keeps its size:
		var old_first := first
		inner.ratio = 1.0 - share
		replace_child(old_first, inner)
		inner.set_children(old_first, new_leaf)
		return

	var old_second := second
	if size_mode == SizeMode.FIXED_FIRST:
		inner.ratio = share			#/ First keeps its size
	else:
		#% Both sides shrink in proportion:
		var first_part := ratio * (1.0 - share)
		var second_part := (1.0 - ratio) * (1.0 - share)
		ratio = first_part
		inner.ratio = share / (share + second_part)
	replace_child(old_second, inner)
	inner.set_children(new_leaf, old_second)


#* Take this Area out of its tree - its sibling takes the parent's place:
#? A root stays as it is.
func detach() -> void:
	var parent := get_parent_area()
	if parent == null:
		return
	parent.keep_sizes_without(self)
	var sibling := parent.sibling_of(self)
	var grandparent := parent.get_parent_area()
	if grandparent != null:
		grandparent.replace_child(parent, sibling)
	else:
		sibling.set_parent_area(null)			#/ The sibling is the root now
	set_parent_area(null)


#* Trade places with another Area of the tree (each takes the other's size):
func swap_with(other: CandyAreaData) -> void:
	var parent := get_parent_area()
	var other_parent := other.get_parent_area()
	if other == self or parent == null or other_parent == null:
		return
	#% Same split - sides swap, sizes stay:
	if parent == other_parent:
		var old_first := parent.first
		parent.first = parent.second
		parent.second = old_first
		return
	var stand_in := CandyAreaData.new()
	parent.replace_child(self, stand_in)
	other_parent.replace_child(other, self)
	parent.replace_child(stand_in, other)


#* Swap the two sides (sizes follow):
func swap_children() -> void:
	if is_leaf():
		return
	var old_first := first
	first = second
	second = old_first
	ratio = 1.0 - ratio
	match size_mode:
		SizeMode.FIXED_FIRST:
			size_mode = SizeMode.FIXED_SECOND
		SizeMode.FIXED_SECOND:
			size_mode = SizeMode.FIXED_FIRST


#* Toggle side by side <-> stacked:
func toggle_layout() -> void:
	if is_leaf():
		return
	if layout == Layout.LEFT_RIGHT:
		layout = Layout.TOP_BOTTOM
	else:
		layout = Layout.LEFT_RIGHT


#& Serialization

func to_dict() -> Dictionary:
	if is_leaf():
		var result := {
			"panel": panel_id,
			"config": config,
			"state": panel_state,
			"can_change_panel": can_change_panel,
			"can_split": can_split,
			"can_close": can_close,
			"show_header": show_header,
		}
		if uid != "":
			result["uid"] = uid
		return result
	return {
		"layout": layout,
		"ratio": ratio,
		"size_mode": size_mode,
		"fixed_size": fixed_size,
		"can_resize": can_resize,
		"can_collapse": can_collapse,
		"first": first.to_dict(),
		"second": second.to_dict(),
	}


#* Build a tree from a dictionary (null if malformed):
static func from_dict(d: Dictionary) -> CandyAreaData:
	var a := CandyAreaData.new()
	if d.has("first") or d.has("second"):
		if typeof(d.get("first")) != TYPE_DICTIONARY or typeof(d.get("second")) != TYPE_DICTIONARY:
			return null
		var f := from_dict(d["first"])
		var s := from_dict(d["second"])
		if f == null or s == null:
			return null
		a.layout = clampi(int(d.get("layout", 0)), 0, Layout.size() - 1) as Layout
		a.ratio = clampf(float(d.get("ratio", 0.5)), 0.0, 1.0)
		a.size_mode = clampi(int(d.get("size_mode", 0)), 0, SizeMode.size() - 1) as SizeMode
		a.fixed_size = maxf(0.0, float(d.get("fixed_size", 0.0)))
		a.can_resize = bool(d.get("can_resize", true))
		a.can_collapse = bool(d.get("can_collapse", true))
		a.set_children(f, s)
	else:
		a.panel_id = str(d.get("panel", ""))
		a.uid = str(d.get("uid", ""))
		var stored_config = d.get("config", {})
		if stored_config is Dictionary:
			a.config = stored_config
		var state = d.get("state", {})
		if typeof(state) == TYPE_DICTIONARY:
			a.panel_state = state
		a.can_change_panel = bool(d.get("can_change_panel", true))
		a.can_split = bool(d.get("can_split", true))
		a.can_close = bool(d.get("can_close", true))
		a.show_header = bool(d.get("show_header", true))
	return a