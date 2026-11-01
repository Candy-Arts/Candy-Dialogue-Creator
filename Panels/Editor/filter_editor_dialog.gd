#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFilterEditorDialog
extends AcceptDialog

const MIN_SIZE := Vector2i(680, 500)

var _layouts: CandyLineLayoutSet
var _line_type: String = ""
var _tab_index: int = 0
var _definitions: Array = []
var _selected: int = -1

var _list: ItemList
var _targets_tree: Tree
var _name_prompt: CandyNamePrompt
var _hint: Label


func _init() -> void:
	title = CandyLocale.t("Filters")
	min_size = MIN_SIZE

	var root := HBoxContainer.new()
	add_child(root)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 200
	root.add_child(left)

	var filters_label := Label.new()
	filters_label.text = CandyLocale.t("Filters")
	left.add_child(filters_label)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.tooltip_text = CandyLocale.t("Drag a filter to move it. The filter bar shows them in this order.")
	_list.item_selected.connect(_on_filter_selected)
	CandyListSelection.enable_reorder(_list, _on_filters_dropped, false)
	left.add_child(_list)

	var buttons := HBoxContainer.new()
	left.add_child(buttons)
	buttons.add_child(_make_button(CandyLocale.t("New"), _on_new_pressed))
	buttons.add_child(_make_button(CandyLocale.t("Rename"), _on_rename_pressed))
	buttons.add_child(_make_button(CandyLocale.t("Delete"), _on_delete_pressed))

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)

	_hint = Label.new()
	right.add_child(_hint)

	_targets_tree = Tree.new()
	_targets_tree.hide_root = true
	_targets_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_targets_tree.item_edited.connect(_on_item_edited)
	right.add_child(_targets_tree)

	_name_prompt = CandyNamePrompt.new()
	add_child(_name_prompt)


func open(layouts: CandyLineLayoutSet, line_type: String, tab_index: int) -> void:
	_layouts = layouts
	_line_type = line_type
	_tab_index = tab_index
	_definitions = CandyFilters.definitions(layouts, line_type, tab_index).duplicate(true)
	_drop_removed_widgets()
	if _definitions.is_empty():
		_selected = -1
	else:
		_selected = 0
	var tab_name := ""
	var tabs := layouts.tabs(line_type)
	if tab_index >= 0 and tab_index < tabs.size():
		tab_name = str(tabs[tab_index]["name"])
	title = CandyLocale.t("Filters — {line_type} › {tab}").format({"line_type": CandyLocale.command_title(CandySchemas.get_title(line_type)), "tab": tab_name})
	_refresh_list()
	_refresh_targets()
	popup_centered()


func _refresh_list() -> void:
	_list.clear()
	for definition in _definitions:
		_list.add_item(str(definition.get("label", definition.get("id", ""))))
	if _selected >= 0 and _selected < _list.item_count:
		_list.select(_selected)


func _refresh_targets() -> void:
	_targets_tree.clear()
	var tree_root := _targets_tree.create_item()

	if _selected < 0 or _selected >= _definitions.size():
		_hint.text = CandyLocale.t("Create a filter to choose what it covers.")
		return
	_hint.text = CandyLocale.t("What this filter shows or hides in this tab")

	var targets := _targets(_definitions[_selected])
	var leaves := _leaves()
	var labels: Dictionary = CandyFilters.widget_labels(_layouts, _line_type, _tab_index)

	#@ Step 1 - Widgets, with their fields:
	var widgets := _add_heading(tree_root, CandyLocale.t("Widgets"))
	for leaf in leaves:
		var widget := _add_check(widgets, str(labels.get(leaf.uid, leaf.panel_id)),
			CandyFilters.area_target(leaf.uid), targets)
		widget.set_tooltip_text(0, CandyLocale.t("Hides this widget"))
		var any_field := _add_fields(widget, _widget_outline(leaf), targets,
			func(field: Dictionary) -> String:
				if field.has("part"):
					return CandyFilters.area_part_target(leaf.uid, str(field["part"]))
				return CandyFilters.area_field_target(leaf.uid, str(field["key"])))
		widget.collapsed = not any_field

	#@ Step 2 - Widget types, once per type in the tab:
	var types := _add_heading(tree_root, CandyLocale.t("Widget types"))
	var seen_types := {}
	for leaf in leaves:
		if seen_types.has(leaf.panel_id):
			continue
		seen_types[leaf.panel_id] = true
		var target := CandyFilters.widget_target(leaf.panel_id)
		_add_check(types, CandyFilters.target_label(target, labels), target, targets)

	#@ Step 3 - Fields in every widget:
	var fields := _add_heading(tree_root, CandyLocale.t("Fields in every widget"))
	_add_fields(fields, CandySchemas.field_index(_line_type), targets,
		func(field: Dictionary) -> String: return CandyFilters.field_target(str(field["key"])))


#* Add fields under parent, nested by depth:
#? fields: CandySchemas.field_index() or filter_outline() entries.
#? target_of(field) -> String: the target each one ticks.
func _add_fields(parent: TreeItem, fields: Array, targets: Array, target_of: Callable) -> bool:
	var any_ticked := false
	var by_depth: Array = [parent]  #/ Last item added at each depth, parent first
	for field in fields:
		var depth := int(field["depth"])
		#% Deeper items are done with:
		if by_depth.size() > depth + 1:
			by_depth.resize(depth + 1)
		var under: TreeItem = by_depth[by_depth.size() - 1]
		var item := _add_check(under, _field_label(field), target_of.call(field), targets)
		item.set_tooltip_text(0, _field_tooltip(field))
		if item.is_checked(0):
			any_ticked = true
		by_depth.append(item)
	for item in parent.get_children():
		_fold_unticked(item)
	return any_ticked


#* A field's or part's label as shown (a category's name is the user's own):
func _field_label(field: Dictionary) -> String:
	var part := str(field.get("part", ""))
	if part.begins_with(CandyFilters.CATEGORY_PREFIX):
		return str(field["label"])
	return CandyLocale.t(str(field["label"]))


func _field_tooltip(field: Dictionary) -> String:
	var part := str(field.get("part", ""))
	if part.begins_with(CandyFilters.CATEGORY_PREFIX):
		return CandyLocale.t("Hides this category: its header and its fields")
	if CandyListSeparators.is_separator(part):
		return CandyLocale.t("Hides this separator")
	return str(field["key"]).replace("/", " › ")


#* Fold item unless something inside it is ticked:
func _fold_unticked(item: TreeItem) -> bool:
	var inside_ticked := false
	for child in item.get_children():
		if _fold_unticked(child):
			inside_ticked = true
	if item.get_child_count() > 0:
		item.collapsed = not inside_ticked
	return inside_ticked or item.is_checked(0)			#/ Item or anything inside it is ticked


func _add_heading(parent: TreeItem, text: String) -> TreeItem:
	var item := _targets_tree.create_item(parent)
	item.set_text(0, text)
	item.set_selectable(0, false)
	return item


func _add_check(parent: TreeItem, label: String, target: String, targets: Array) -> TreeItem:
	var item := _targets_tree.create_item(parent)
	item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	item.set_editable(0, true)
	item.set_text(0, label)
	item.set_checked(0, targets.has(target))
	item.set_metadata(0, target)
	return item


#* The tab's leaves, in layout order:
func _leaves() -> Array[CandyAreaData]:
	var leaves: Array[CandyAreaData] = []
	var root := _layouts.get_root(_line_type, _tab_index)
	if root != null:
		root.collect_leaves(leaves)
	return leaves


#* The widget's filter outline (CandyAreaWidget.filter_outline()):
func _widget_outline(leaf: CandyAreaData) -> Array:
	if not CandyWidgets.ids_of_kind("area").has(leaf.panel_id):
		return []
	var widget := CandyWidgets.instantiate_area(leaf.panel_id)
	#? Never configured - only what a catch-all Fields widget needs to answer.
	widget.context = {"line_type": _line_type, "line_layouts": _layouts}
	var outline: Array = widget.filter_outline(leaf.config, _line_type)
	widget.free()
	return outline


#* Drop targets that can never match again (widget, category or separator gone):
func _drop_removed_widgets() -> void:
	var parts := {}    #/ uid -> { part: true }
	for leaf in _leaves():
		var leaf_parts := {}
		for field in _widget_outline(leaf):
			if field.has("part"):
				leaf_parts[str(field["part"])] = true
		parts[leaf.uid] = leaf_parts
	for definition in _definitions:
		if not definition is Dictionary:
			continue
		var kept: Array = []
		for target in _targets(definition):
			var uid := CandyFilters.target_uid(str(target))
			if uid == "":
				kept.append(target)
				continue
			if not parts.has(uid):
				continue
			var part := str(target).substr(CandyFilters.area_target(uid).length()) \
				.trim_prefix(CandyFilters.AREA_FIELD_SEPARATOR)
			if not CandyFilters.is_part(part) or parts[uid].has(part):
				kept.append(target)
		definition["targets"] = kept			#/ Saved with the next change


func _on_filter_selected(index: int) -> void:
	_selected = index
	_refresh_targets()


#* Reorder by drag; the dragged filter stays selected:
func _on_filters_dropped(indices: Array, slot: int) -> void:
	var moved := CandyListSelection.move_to(_definitions, indices, slot)
	if moved.is_empty():
		return
	_selected = int(moved[0])
	_save()
	_refresh_list()


func _on_item_edited() -> void:
	var item := _targets_tree.get_edited()
	if item == null or _selected < 0:
		return
	var target := str(item.get_metadata(0))
	var targets := _targets(_definitions[_selected])
	if item.is_checked(0) and not targets.has(target):
		targets.append(target)
	elif not item.is_checked(0):
		targets.erase(target)
	_definitions[_selected]["targets"] = targets
	_save()


func _on_new_pressed() -> void:
	_name_prompt.prompt(CandyLocale.t("New Filter"), "Filter",
		func(label: String) -> String:
			if _has_label(label, -1):
				return CandyLocale.t("A filter with that name already exists.")
			return "",
		func(label: String) -> void:
			_definitions.append({"id": _unique_id(label), "label": label, "targets": []})
			_selected = _definitions.size() - 1
			_save()
			_refresh_list()
			_refresh_targets())


func _on_rename_pressed() -> void:
	if _selected < 0:
		return
	var current := str(_definitions[_selected].get("label", ""))
	_name_prompt.prompt(CandyLocale.t("Rename Filter"), current,
		func(label: String) -> String:
			if _has_label(label, _selected):
				return CandyLocale.t("A filter with that name already exists.")
			return "",
		func(label: String) -> void:
			_definitions[_selected]["label"] = label
			_save()
			_refresh_list())


func _on_delete_pressed() -> void:
	if _selected < 0:
		return
	_definitions.remove_at(_selected)
	_selected = mini(_selected, _definitions.size() - 1)
	_save()
	_refresh_list()
	_refresh_targets()


func _save() -> void:
	CandyFilters.set_definitions(_layouts, _line_type, _tab_index, _definitions.duplicate(true))


#* A filter's targets, normalized so a bare field id still matches its checkbox:
func _targets(definition: Dictionary) -> Array:
	var stored = definition.get("targets", [])
	var result: Array = []
	if stored is Array:
		for target in stored:
			result.append(CandyFilters.normalize_target(str(target)))
	return result


func _has_label(label: String, except_index: int) -> bool:
	for i in _definitions.size():
		if i != except_index and str(_definitions[i].get("label", "")) == label:
			return true
	return false


#* A new filter id (stable key, never changes on rename):
func _unique_id(label: String) -> String:
	var base := label.to_snake_case()
	if base == "":
		base = "filter"
	var taken: Array = []
	for definition in _definitions:
		taken.append(str(definition.get("id", "")))
	return CandyDialogue.unique_name(taken, base)


func _make_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	return button
