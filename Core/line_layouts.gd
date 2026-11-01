#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Node

const DEFAULT_TAB_NAME := "Line"
const FIELDS_WIDGET := "fields"


#* Get a Fields widget's field ids, in order, less separators:
func field_ids(entries: Variant) -> Array:
	var ids: Array = []
	if not entries is Array:
		return ids
	for entry in entries:
		#Ł Flatten categories ({ "name", "folded", "fields" }):
		if entry is Dictionary:
			var inside = entry.get("fields", [])
			if inside is Array:
				for id in inside:
					if not CandyListSeparators.is_separator(id):
						ids.append(str(id))
		elif not CandyListSeparators.is_separator(entry):
			ids.append(str(entry))
	return ids


#* Make a new area (a catch-all Fields widget):
func new_leaf() -> CandyAreaData:
	var leaf := CandyAreaData.make_leaf(FIELDS_WIDGET)
	leaf.config = default_config(FIELDS_WIDGET)
	return leaf


#* Get a widget's starting settings:
func default_config(widget_id: String) -> Dictionary:
	if widget_id == FIELDS_WIDGET:
		return {"fields": []}  #/ Empty = everything not placed elsewhere
	return {}


#* Check whether a saved Area layout fits line_type (every widget exists and fits):
func area_fits(layout: Variant, line_type: String) -> bool:
	var root := CandyLayoutLibrary.area_from_layout(layout)
	if root == null:
		return false
	var area_widgets := CandyWidgets.ids_of_kind("area")
	var leaves: Array[CandyAreaData] = []
	root.collect_leaves(leaves)
	for leaf in leaves:
		if not area_widgets.has(leaf.panel_id):
			return false
		#? Only asked, never configured nor added to the tree.
		var widget := CandyWidgets.instantiate_area(leaf.panel_id)
		var fits: bool = widget.fits_line_type(leaf.config, line_type)
		widget.free()
		if not fits:
			return false
	return true
