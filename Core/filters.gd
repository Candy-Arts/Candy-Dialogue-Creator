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

const FIELD_PREFIX := "field:"
const WIDGET_PREFIX := "widget:"
const AREA_PREFIX := "area:"
#^ A Fields widget's category part, by name (see area_part_target()):
const CATEGORY_PREFIX := "category:"
#^ Between an area and a field or part - "area:3fa9c2d1/field:Portrait":
const AREA_FIELD_SEPARATOR := "/"
#^ How many listed fields a widget label names (see widget_labels()):
const WIDGET_LABEL_FIELDS := 3


#& Definitions

func definitions(layouts: CandyLineLayoutSet, line_type: String, tab_index: int) -> Array:
	var list = layouts.tab_filters(line_type, tab_index).get("definitions", [])
	if list is Array:
		return list
	return []


func set_definitions(layouts: CandyLineLayoutSet, line_type: String, tab_index: int, list: Array) -> void:
	var filters: Dictionary = layouts.tab_filters(line_type, tab_index).duplicate(true)
	filters["definitions"] = list
	layouts.set_tab_filters(line_type, tab_index, filters)


#& State

func is_enabled(layouts: CandyLineLayoutSet, line_type: String, tab_index: int, id: String) -> bool:
	var state = layouts.tab_filters(line_type, tab_index).get("state", {})
	if not state is Dictionary:
		return true
	return bool(state.get(id, true))  #/ On by default, so nothing hides silently


func set_enabled(layouts: CandyLineLayoutSet, line_type: String, tab_index: int, id: String, enabled: bool) -> void:
	var filters: Dictionary = layouts.tab_filters(line_type, tab_index).duplicate(true)
	var state = filters.get("state", {})
	if not state is Dictionary:
		state = {}
	state[id] = enabled
	filters["state"] = state
	layouts.set_tab_filters(line_type, tab_index, filters)


#& Targets

#* A field target (key = its schema path):
func field_target(key: String) -> String:
	return FIELD_PREFIX + key


func widget_target(id: String) -> String:
	return WIDGET_PREFIX + id


func area_target(uid: String) -> String:
	return AREA_PREFIX + uid


func area_field_target(uid: String, field_key: String) -> String:
	return area_target(uid) + AREA_FIELD_SEPARATOR + field_target(field_key)


#* A part target (part = "category:Voice" or "separator:2"):
func area_part_target(uid: String, part: String) -> String:
	return area_target(uid) + AREA_FIELD_SEPARATOR + part


func category_part(category_name: String) -> String:
	return CATEGORY_PREFIX + category_name


func is_part(text: String) -> bool:
	return text.begins_with(CATEGORY_PREFIX) or CandyListSeparators.is_separator(text)


#* Normalize a target (a bare id is a field):
func normalize_target(target: String) -> String:
	if target.begins_with(FIELD_PREFIX) or target.begins_with(WIDGET_PREFIX) \
			or target.begins_with(AREA_PREFIX):
		return target
	return FIELD_PREFIX + target


#* The area uid a target aims at ("" for none):
func target_uid(target: String) -> String:
	var text := normalize_target(target)
	if not text.begins_with(AREA_PREFIX):
		return ""
	return text.substr(AREA_PREFIX.length()).get_slice(AREA_FIELD_SEPARATOR, 0)


#* A label for each widget of a tab, by area uid:
func widget_labels(layouts: CandyLineLayoutSet, line_type: String, tab_index: int) -> Dictionary:
	var result := {}
	var root := layouts.get_root(line_type, tab_index)
	if root == null:
		return result
	var leaves: Array[CandyAreaData] = []
	root.collect_leaves(leaves)
	var counts := {}
	for leaf in leaves:
		var label := _widget_label(leaf)
		counts[label] = int(counts.get(label, 0)) + 1
		if int(counts[label]) > 1:
			label += " #%d" % int(counts[label])
		result[leaf.uid] = label			#/ "Fields (Reference, Disposition, Portrait +3)", duplicates numbered
	return result


func _widget_label(leaf: CandyAreaData) -> String:
	var details: Array = []
	var listed := CandyLineLayouts.field_ids(leaf.config.get("fields", []))
	if not listed.is_empty():
		var text := ", ".join(PackedStringArray(listed.slice(0, WIDGET_LABEL_FIELDS)))
		if listed.size() > WIDGET_LABEL_FIELDS:
			text += " +%d" % (listed.size() - WIDGET_LABEL_FIELDS)
		details.append(text)
	if str(leaf.config.get("reference", "")).strip_edges() != "":
		details.append(CandyLocale.t("ref %s") % str(leaf.config["reference"]).strip_edges())
	var label := CandyWidgets.get_title(leaf.panel_id)
	if not details.is_empty():
		label += " (%s)" % ", ".join(PackedStringArray(details))
	return label


#* A target's label ("Every Portrait Preview widget", "Portrait in Fields (...)"):
#? labels: widget_labels().
func target_label(target: String, labels: Dictionary) -> String:
	var text := normalize_target(target)
	if text.begins_with(WIDGET_PREFIX):
		return CandyLocale.t("Every %s widget") % CandyWidgets.get_title(text.substr(WIDGET_PREFIX.length()))
	if text.begins_with(FIELD_PREFIX):
		return _path_label(text.substr(FIELD_PREFIX.length()))
	var uid := target_uid(text)
	var widget := str(labels.get(uid, CandyLocale.t("a removed widget")))
	var field := text.substr(AREA_PREFIX.length() + uid.length()).trim_prefix(AREA_FIELD_SEPARATOR)
	if field.begins_with(FIELD_PREFIX):
		return CandyLocale.t("{field} in {widget}").format({"field": _path_label(field.substr(FIELD_PREFIX.length())), "widget": widget})
	if field.begins_with(CATEGORY_PREFIX):
		return CandyLocale.t("{category} category in {widget}").format(
			{"category": CandyLocale.t(field.substr(CATEGORY_PREFIX.length())), "widget": widget})
	if CandyListSeparators.is_separator(field):
		return CandyLocale.t("A separator in %s") % widget
	return widget


#* "Categories/Setup" -> "Categories › Setup":
func _path_label(key: String) -> String:
	return key.replace("/", " › ")


#* What the off filters of a tab hide:
func hidden_targets(layouts: CandyLineLayoutSet, line_type: String, tab_index: int) -> Dictionary:
	var result := {"widgets": {}, "areas": {}, "fields": {}, "area_fields": {}, "area_parts": {}}
	for definition in definitions(layouts, line_type, tab_index):
		if not definition is Dictionary:
			continue
		var id := str(definition.get("id", ""))
		if id == "" or is_enabled(layouts, line_type, tab_index, id):
			continue
		var targets = definition.get("targets", [])
		if targets is Array:
			for target in targets:
				_add_hidden(result, normalize_target(str(target)))
	#?   { "widgets": { widget id: true }, "areas": { uid: true },
	#?     "fields": { schema path: true }, "area_fields": { uid: { schema path: true } },
	#?     "area_parts": { uid: { "category:Voice": true, "separator:2": true } } }
	return result			#/ For is_area_hidden(), fields_hidden_in() and parts_hidden_in()


func _add_hidden(result: Dictionary, target: String) -> void:
	if target.begins_with(WIDGET_PREFIX):
		result["widgets"][target.substr(WIDGET_PREFIX.length())] = true
	elif target.begins_with(FIELD_PREFIX):
		result["fields"][target.substr(FIELD_PREFIX.length())] = true
	elif target.begins_with(AREA_PREFIX):
		var uid := target_uid(target)
		var rest := target.substr(AREA_PREFIX.length() + uid.length())
		if rest == "":
			result["areas"][uid] = true
			return
		rest = rest.trim_prefix(AREA_FIELD_SEPARATOR)
		if rest.begins_with(FIELD_PREFIX):
			var fields: Dictionary = result["area_fields"].get(uid, {})
			fields[rest.substr(FIELD_PREFIX.length())] = true
			result["area_fields"][uid] = fields
		elif is_part(rest):
			var parts: Dictionary = result["area_parts"].get(uid, {})
			parts[rest] = true
			result["area_parts"][uid] = parts


#* Whether hidden_now hides the whole widget in area:
func is_area_hidden(hidden_now: Dictionary, area: CandyAreaData) -> bool:
	return hidden_now["widgets"].has(area.panel_id) or hidden_now["areas"].has(area.uid)


#* The fields hidden_now hides in area's widget (everywhere + its own):
func fields_hidden_in(hidden_now: Dictionary, area: CandyAreaData) -> Dictionary:
	var result: Dictionary = hidden_now["fields"].duplicate()
	result.merge(hidden_now["area_fields"].get(area.uid, {}))
	return result


#* The parts hidden_now hides in area's widget:
func parts_hidden_in(hidden_now: Dictionary, area: CandyAreaData) -> Dictionary:
	return hidden_now["area_parts"].get(area.uid, {}).duplicate()

