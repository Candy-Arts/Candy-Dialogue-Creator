#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyLineLayoutSet
extends RefCounted

#^ A type's layout changed, its views rebuild ("" for every type, from set_data()):
signal changed(line_type: String)
#^ The data changed - the owner keeps it (the Dialogue Editor saves its window layout):
signal stored
#^ A tab's filters changed (see CandyFilters):
signal filters_changed(line_type: String)

#^ Stored form, by line type - { "tabs" = [...] }:
var _data: Dictionary = {}
#^ Parsed trees per type, so drags and edits don't re-parse:
var _cache: Dictionary = {}    #/ line type -> Array of { name, min_height, height, filters, root: CandyAreaData }


#* Get a copy of every type's layout:
func get_data() -> Dictionary:
	return _data.duplicate(true)


#* Replace every type's layout (missing types get their default):
func set_data(data: Variant) -> void:
	_data = {}
	if data is Dictionary:
		_data = data.duplicate(true)
	_cache.clear()
	changed.emit("")


#& Reading

#* Get a line type's tabs:
func tabs(line_type: String) -> Array:
	if _cache.has(line_type):
		return _cache[line_type]

	var result := _parse_tabs(_data.get(line_type, {}))
	if result.is_empty():
		result = _default_tabs(line_type)

	_cache[line_type] = result
	_give_uids(result)
	return result			#/ [{ "name": String, "min_height": int, "height": int, "filters": Dictionary, "root": CandyAreaData }]


#* Parse a type's stored { "tabs": [...] }, skipping tabs that don't parse:
func _parse_tabs(type_data: Variant) -> Array:
	var result: Array = []
	if not (type_data is Dictionary and type_data.get("tabs") is Array):
		return result
	for tab in type_data["tabs"]:
		if not tab is Dictionary or not tab.get("root", {}) is Dictionary:
			continue
		var root = CandyAreaData.from_dict(tab.get("root", {}))
		if root == null:
			continue
		var filters = tab.get("filters", {})
		if not filters is Dictionary:
			filters = {}
		result.append({"name": str(tab.get("name", CandyLineLayouts.DEFAULT_TAB_NAME)),
			"min_height": maxi(0, int(tab.get("min_height", 0))), "height": maxi(0, int(tab.get("height", 0))),
			"filters": filters, "root": root})
	return result


#* Get the default tabs (the schema's "layout", or one Fields widget):
func _default_tabs(line_type: String) -> Array:
	#Ł Copy, so edits never change the loaded schema:
	var result := _parse_tabs(CandySchemas.get_layout(line_type).duplicate(true))
	if result.is_empty():
		result = [{"name": CandyLineLayouts.DEFAULT_TAB_NAME, "min_height": 0, "height": 0, "filters": {},
			"root": CandyLineLayouts.new_leaf()}]
	return result


func tab_count(line_type: String) -> int:
	return tabs(line_type).size()


func get_root(line_type: String, tab_index: int) -> CandyAreaData:
	var list := tabs(line_type)
	if tab_index < 0 or tab_index >= list.size():
		return null
	return list[tab_index]["root"]


#* Get a tab's filters, { "definitions": [...], "state": {...} }:
func tab_filters(line_type: String, tab_index: int) -> Dictionary:
	var list := tabs(line_type)
	if tab_index < 0 or tab_index >= list.size():
		return {}
	var filters = list[tab_index].get("filters", {})
	if filters is Dictionary:
		return filters
	return {}


#* Store a tab's filters without rebuilding the line UI (filters_changed tells):
func set_tab_filters(line_type: String, tab_index: int, filters: Dictionary) -> void:
	var list := tabs(line_type)
	if tab_index < 0 or tab_index >= list.size():
		return
	list[tab_index]["filters"] = filters
	store(line_type)
	filters_changed.emit(line_type)


#* Get a tab's minimum height (0 = none):
func tab_min_height(line_type: String, tab_index: int) -> int:
	var list := tabs(line_type)
	if tab_index < 0 or tab_index >= list.size():
		return 0
	return int(list[tab_index].get("min_height", 0))


#* Get how far down a tab's widgets reach, set by the dragger under them (0 = to the bottom):
func tab_height(line_type: String, tab_index: int) -> int:
	var list := tabs(line_type)
	if tab_index < 0 or tab_index >= list.size():
		return 0
	return int(list[tab_index].get("height", 0))


#* Keep how far down a tab's widgets reach (the line UI already shows it):
func set_tab_height(line_type: String, tab_index: int, height: int) -> void:
	var list := tabs(line_type)
	if tab_index < 0 or tab_index >= list.size():
		return
	list[tab_index]["height"] = maxi(0, height)
	store(line_type)


#& Field placement

#* Get the field ids placed in some Fields widget, anywhere in the layout:
func placed_fields(line_type: String) -> Dictionary:
	var placed := {}
	for tab in tabs(line_type):
		_collect_placed(tab["root"], placed)
	return placed


func _collect_placed(area: CandyAreaData, placed: Dictionary) -> void:
	if area.is_leaf():
		if area.panel_id == CandyLineLayouts.FIELDS_WIDGET:
			for id in CandyLineLayouts.field_ids(area.config.get("fields", [])):
				placed[id] = true
		return
	_collect_placed(area.first, placed)
	_collect_placed(area.second, placed)


#& Editing

func add_tab(line_type: String, tab_name: String) -> int:
	var list := tabs(line_type)
	list.append({"name": tab_name, "min_height": 0, "height": 0, "filters": {}, "root": CandyLineLayouts.new_leaf()})
	save(line_type)
	return list.size() - 1


func rename_tab(line_type: String, tab_index: int, tab_name: String) -> void:
	var list := tabs(line_type)
	if tab_index < 0 or tab_index >= list.size():
		return
	list[tab_index]["name"] = tab_name
	save(line_type)


func set_tab_min_height(line_type: String, tab_index: int, height: int) -> void:
	var list := tabs(line_type)
	if tab_index < 0 or tab_index >= list.size():
		return
	list[tab_index]["min_height"] = maxi(0, height)
	save(line_type)


#* Remove a tab (never the last one):
func remove_tab(line_type: String, tab_index: int) -> bool:
	var list := tabs(line_type)
	if list.size() <= 1 or tab_index < 0 or tab_index >= list.size():
		return false
	list.remove_at(tab_index)
	save(line_type)
	return true


func move_tab(line_type: String, tab_index: int, to_index: int) -> bool:
	var list := tabs(line_type)
	if tab_index < 0 or tab_index >= list.size() or to_index < 0 or to_index >= list.size():
		return false
	var tab = list[tab_index]
	list.remove_at(tab_index)
	list.insert(to_index, tab)
	save(line_type)
	return true


#* Set a tab's root, when an edit replaced it (see CandyLineAreaEdits):
func set_root(line_type: String, tab_index: int, root: CandyAreaData) -> void:
	var list := tabs(line_type)
	if tab_index < 0 or tab_index >= list.size():
		return
	root.set_parent_area(null)
	list[tab_index]["root"] = root


#* Keep the type's layout and rebuild its views:
func save(line_type: String) -> void:
	store(line_type)
	changed.emit(line_type)


#* Keep the type's layout without rebuilding the line UI:
#? For changes the line UI already shows (a folded category).
func store(line_type: String) -> void:
	var stored_tabs: Array = []
	_give_uids(tabs(line_type))
	for tab in tabs(line_type):
		stored_tabs.append({"name": str(tab["name"]), "min_height": int(tab.get("min_height", 0)),
			"height": int(tab.get("height", 0)),
			"filters": tab.get("filters", {}).duplicate(true), "root": tab["root"].to_dict()})
	_data[line_type] = {"tabs": stored_tabs}
	stored.emit()


#* Reset a type to its default layout:
func reset(line_type: String) -> void:
	_data.erase(line_type)
	_cache[line_type] = _default_tabs(line_type)
	save(line_type)


#* Give a uid to every leaf without one, or with a duplicate:
func _give_uids(tab_list: Array) -> void:
	var taken := {}
	for tab in tab_list:
		var leaves: Array[CandyAreaData] = []
		tab["root"].collect_leaves(leaves)
		for leaf in leaves:
			while leaf.uid == "" or taken.has(leaf.uid):
				leaf.uid = "%08x" % randi()			#/ Random: a removed area's uid never comes back with its filters
			taken[leaf.uid] = true
