#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyRowReorder
extends RefCounted

#^ Width of the line drawn where a dragged item would go:
const MARK_WIDTH := 3.0
const PREVIEW_ALPHA := 0.75

var _row: Control
#^ on_moved(from_index: int, to_index: int): to_index counts the items without the moved one:
var _on_moved: Callable
#^ The items, in order (direct children of the row):
var _items: Array[Control] = []
#^ The slot a dragged item would go to (0 = before the first item), -1 while none:
var _slot := -1
#^ While a drag is watched:
var _tree: SceneTree = null


#* Let items of a row (Buttons that are its children) be reordered by dragging:
#? Call add_item() for each item, in order, every time the row is rebuilt.
func _init(row: Control, on_moved: Callable) -> void:
	_row = row
	_on_moved = on_moved
	_row.draw.connect(_draw_mark)


func clear() -> void:
	_items.clear()
	_set_slot(-1)


func add_item(item: Control) -> void:
	_items.append(item)
	item.set_drag_forwarding(_get_drag_data.bind(item), _can_drop_data.bind(item), _drop_data.bind(item))


func _get_drag_data(_at_position: Vector2, item: Control) -> Variant:
	var preview := Label.new()
	if item is Button:
		preview.text = (item as Button).text
	preview.modulate.a = PREVIEW_ALPHA
	item.set_drag_preview(preview)
	return {"candy_row_reorder": self, "index": _items.find(item)}


func _can_drop_data(at_position: Vector2, data: Variant, item: Control) -> bool:
	if not _is_ours(data):
		return false
	_set_slot(_slot_at(item.position.x + at_position.x))
	_watch_drag()
	return true


func _drop_data(at_position: Vector2, data: Variant, item: Control) -> void:
	var slot := _slot_at(item.position.x + at_position.x)
	_set_slot(-1)
	if not _is_ours(data):
		return
	var from := int(data["index"])
	#% Dropped on either side of itself:
	if from < 0 or slot == from or slot == from + 1:
		return
	var to := slot
	if slot > from:
		to = slot - 1
	_on_moved.call(from, to)


func _is_ours(data: Variant) -> bool:
	return data is Dictionary and data.get("candy_row_reorder") == self


#* The slot an x position in the row falls in - before the item whose middle it's left of:
func _slot_at(x: float) -> int:
	for i in _items.size():
		var item := _items[i]
		if x < item.position.x + item.size.x * 0.5:
			return i
	return _items.size()


func _set_slot(slot: int) -> void:
	if slot == _slot:
		return
	_slot = slot
	_row.queue_redraw()


#* Clear the mark once the drag ends or leaves the items:
func _watch_drag() -> void:
	if _tree != null or not _row.is_inside_tree():
		return
	_tree = _row.get_tree()
	_tree.process_frame.connect(_check_drag)


func _check_drag() -> void:
	if _row.is_inside_tree() and _row.get_viewport().gui_is_dragging():
		for item in _items:
			if is_instance_valid(item) and item.get_global_rect().has_point(item.get_global_mouse_position()):
				return
	_set_slot(-1)
	_tree.process_frame.disconnect(_check_drag)
	_tree = null


#* The mark, in the gap before the slot's item (or after the last):
func _draw_mark() -> void:
	if _slot < 0 or _items.is_empty():
		return
	var x := 0.0
	if _slot == 0:
		x = _items[0].position.x - MARK_WIDTH * 0.5
	elif _slot < _items.size():
		var before := _items[_slot - 1]
		x = (before.position.x + before.size.x + _items[_slot].position.x) * 0.5
	else:
		var last := _items[_items.size() - 1]
		x = last.position.x + last.size.x + MARK_WIDTH * 0.5
	x = clampf(x, MARK_WIDTH * 0.5, _row.size.x - MARK_WIDTH * 0.5)
	var top := _items[0].position.y
	var bottom := top + _items[0].size.y
	var color := _row.get_theme_color(&"highlight", CandyThemeDefaults.AREA_SPLIT)
	_row.draw_line(Vector2(x, top), Vector2(x, bottom), color, MARK_WIDTH)
