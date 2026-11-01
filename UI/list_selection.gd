#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyListSelection

#^ Height of the drop line:
const DROP_LINE_HEIGHT := 2.0
const DROP_META := &"candy_drop_slot"
const DRAG_SOURCE := "candy_list_reorder"


#* Selected indices of an ItemList, in list order:
static func selected_indices(list: ItemList) -> Array:
	var indices: Array = []
	for index in list.get_selected_items():
		indices.append(int(index))
	indices.sort()
	return indices


#* Selected items of a Tree, in tree order:
static func selected_tree_items(tree: Tree) -> Array:
	var items: Array = []
	var item := tree.get_next_selected(null)
	while item != null:
		items.append(item)
		item = tree.get_next_selected(item)
	return items


#* Move entries of array (changed in place) before what was at slot, keeping their order:
#? slot: index in the array before the move (its size for the end).
static func move_to(array: Array, indices: Array, slot: int) -> Array:
	var sorted := indices.duplicate()
	sorted.sort()
	var moving: Array = []
	var before := 0
	for i in range(sorted.size() - 1, -1, -1):
		var index: int = sorted[i]
		moving.push_front(array[index])
		array.remove_at(index)
		if index < slot:
			before += 1
	var at := clampi(slot - before, 0, array.size())
	var result: Array = []
	for i in moving.size():
		array.insert(at + i, moving[i])
		result.append(at + i)
	return result			#/ Their new indices


#* Select exactly the items at indices:
static func select_indices(list: ItemList, indices: Array) -> void:
	list.deselect_all()
	for index in indices:
		if int(index) >= 0 and int(index) < list.item_count:
			list.select(int(index), false)


#* Make a list reorderable by dragging:
#? on_drop(indices: Array, slot: int), slot as move_to() takes it.
static func enable_reorder(list: ItemList, on_drop: Callable, multi: bool = true) -> void:
	if multi:
		list.select_mode = ItemList.SELECT_MULTI
	list.set_drag_forwarding(
		func(at_position: Vector2) -> Variant:
			var index := list.get_item_at_position(at_position, true)
			if index < 0:
				return null
			#Ł The dragged item gets selected:
			if not list.is_selected(index):
				select_indices(list, [index])
				if not multi:
					#? Selecting from code emits nothing.
					list.item_selected.emit(index)
			var indices := selected_indices(list)
			var preview := Label.new()
			if indices.size() == 1:
				preview.text = list.get_item_text(indices[0])
			else:
				preview.text = CandyLocale.tn("%d item", "%d items", indices.size()) % indices.size()
			list.set_drag_preview(preview)
			return {"source": DRAG_SOURCE, "list": list.get_instance_id(), "indices": indices},
		func(at_position: Vector2, data: Variant) -> bool:
			if not (data is Dictionary and data.get("source") == DRAG_SOURCE
					and data.get("list") == list.get_instance_id()):
				return false
			list.set_meta(DROP_META, _slot_at(list, at_position.y))
			list.queue_redraw()
			return true,
		func(at_position: Vector2, data: Variant) -> void:
			list.remove_meta(DROP_META)
			list.queue_redraw()
			on_drop.call(data["indices"], _slot_at(list, at_position.y)))
	list.draw.connect(func(): _draw_drop_line(list))
	list.mouse_exited.connect(list.queue_redraw)


#* Slot a drop at y lands in (before the item whose top half y is in):
static func _slot_at(list: ItemList, y: float) -> int:
	#? Item rects don't scroll; the mouse position does.
	var content_y := y + list.get_v_scroll_bar().value
	for index in list.item_count:
		if content_y < list.get_item_rect(index).get_center().y:
			return index
	return list.item_count


static func _draw_drop_line(list: ItemList) -> void:
	if not list.has_meta(DROP_META) or not list.get_viewport().gui_is_dragging():
		return
	var slot := int(list.get_meta(DROP_META))
	var y := 0.0
	if list.item_count > 0:
		if slot < list.item_count:
			y = list.get_item_rect(slot).position.y
		else:
			y = list.get_item_rect(list.item_count - 1).end.y
	y -= list.get_v_scroll_bar().value
	var color := list.get_theme_color(&"drop_indicator", CandyThemeDefaults.NAVIGATOR)
	list.draw_rect(Rect2(0.0, y - DROP_LINE_HEIGHT * 0.5, list.size.x, DROP_LINE_HEIGHT), color)
