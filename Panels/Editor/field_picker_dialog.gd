#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFieldPickerDialog
extends AcceptDialog

#^ Only the keys this dialog edits ("fields", "columns", "hidden_children", "child_order"):
#? The caller merges them into the area's config.
signal applied(changes: Dictionary)

const NEW_CATEGORY_NAME := "Category"
#^ What a Displayed item is, in its metadata's "kind":
const KIND_FIELD := "field"          #/ A field or separator of the widget's "fields"
const KIND_CATEGORY := "category"
const KIND_CHILD := "child"          #/ A child field, or a separator among them
const CHILD_TOOLTIP := "Untick to leave it out of this area. Drag it to move it among the fields beside it."	#/ translatable

#^ [{ "id", "label" }]:
var _candidates: Array = []
#^ Field ids the catch-all shows:
var _catch_all_ids: Array = []
#^ Every child field, by schema path:
#? { "Players/Loops": { "key", "label", "depth", "top", "parent" } }
var _child_info: Dictionary = {}
#^ Each parent's child ids in schema order, by parent schema path:
#? { "Players": ["File", "Volume", "Loops"] }
var _schema_children: Dictionary = {}
#^ The widget's "fields": field ids, separator ids, categories { "name", "folded", "fields" }:
var _chosen: Array = []
var _hidden_children: Dictionary = {}    #/ Schema path -> true
#^ The widget's "child_order": { parent schema path: [child or separator id, ...] }:
#? Only parents arranged differently from the schema.
var _child_order: Dictionary = {}

var _catch_all: CheckBox
var _columns: SpinBox
var _available: ItemList
#^ Item metadata - { "kind", "top", "field", "nested" }:
#?   top     index in _chosen (-1 under the catch-all)
#?   field   field or separator id, "" for a category
#?   nested  whether the field is in a category
#? A child's is its top-level field's, plus "parent" (schema path) and "id".
var _displayed: Tree
#^ Folded Displayed items, kept across refreshes:
var _displayed_folds: Dictionary = {}
var _lists: HBoxContainer
var _available_column: VBoxContainer
var _middle: Control
var _name_prompt: CandyNamePrompt


func _init() -> void:
	title = CandyLocale.t("Fields in this area")
	min_size = Vector2i(640, 620)

	var root := VBoxContainer.new()
	add_child(root)

	var columns_row := HBoxContainer.new()
	root.add_child(columns_row)
	var columns_label := Label.new()
	columns_label.text = CandyLocale.t("Columns")
	columns_label.custom_minimum_size.x = 90
	columns_label.tooltip_text = CandyLocale.t("Fields fill the first column top to bottom, then the next. Each category, and each part a separator divides, is spread over the columns on its own.")
	columns_row.add_child(columns_label)
	_columns = SpinBox.new()
	_columns.min_value = 1
	_columns.max_value = CandyFieldsAreaWidget.MAX_COLUMNS
	_columns.step = 1
	_columns.rounded = true
	columns_row.add_child(_columns)

	root.add_child(HSeparator.new())

	_catch_all = CheckBox.new()
	_catch_all.toggled.connect(_on_catch_all_toggled)
	root.add_child(_catch_all)

	_lists = HBoxContainer.new()
	_lists.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_lists)

	#? Displayed on the left, as in every pick-what-is-displayed dialog.
	var displayed_column := _add_column(CandyLocale.t("Displayed in this area"))
	_displayed = Tree.new()
	_displayed.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_displayed.hide_root = true
	_displayed.allow_reselect = true
	_displayed.select_mode = Tree.SELECT_MULTI
	_displayed.item_activated.connect(_on_displayed_activated)
	_displayed.item_edited.connect(_on_item_edited)
	_displayed.set_drag_forwarding(_get_displayed_drag, _can_drop_displayed, _drop_displayed)
	displayed_column.add_child(_displayed)

	var category_row := HBoxContainer.new()
	displayed_column.add_child(category_row)
	var add_category := _button(CandyLocale.t("Add Category"), _on_add_category_pressed)
	add_category.tooltip_text = CandyLocale.t("A category folds and unfolds in the area. Select it, then add fields to it.")
	category_row.add_child(add_category)
	var add_separator := _button(CandyLocale.t("Add Separator"), _on_add_separator_pressed)
	add_separator.tooltip_text = CandyLocale.t("A horizontal line after the selected field or child field, or at the end of the selected category.")
	category_row.add_child(add_separator)
	category_row.add_child(_button(CandyLocale.t("Rename"), _on_rename_category_pressed))
	var delete := _button(CandyLocale.t("Delete"), _on_delete_pressed)
	delete.tooltip_text = CandyLocale.t("Deletes the selected categories and separators. The fields of a deleted category go back to Available.")
	category_row.add_child(delete)

	_middle = _middle_buttons()
	_lists.add_child(_middle)
	_available_column = _add_column(CandyLocale.t("Available"))
	_available = ItemList.new()
	_available.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_available.allow_reselect = true
	_available.select_mode = ItemList.SELECT_MULTI
	_available.item_activated.connect(func(index: int): _add_fields([index]))
	_available_column.add_child(_available)

	_name_prompt = CandyNamePrompt.new()
	add_child(_name_prompt)

	confirmed.connect(_apply)


#* Open the dialog on a widget's config:
#? candidates, children, options and catch_all_ids come from
#? CandyFieldsAreaWidget's picker_candidates(), picker_children(),
#? picker_options() and picker_catch_all().
func open(candidates: Array, config: Dictionary, options: Dictionary, children: Array = [],
		catch_all_ids: Array = []) -> void:
	_candidates = candidates
	_catch_all_ids = catch_all_ids
	_read_children(children)
	_chosen = _read_entries(config.get("fields", []))
	_hidden_children = {}
	var hidden = config.get("hidden_children", [])
	if hidden is Array:
		for key in hidden:
			_hidden_children[str(key)] = true
	_child_order = {}
	var order = config.get("child_order", {})
	if order is Dictionary:
		for parent in order:
			if order[parent] is Array:
				_child_order[str(parent)] = order[parent].duplicate()

	title = CandyLocale.t("Fields in this area")
	if options.has("title"):
		title = str(options["title"])
	_catch_all.text = CandyLocale.t("Everything not placed in another area")
	if options.has("catch_all"):
		_catch_all.text = str(options["catch_all"])
	_catch_all.tooltip_text = str(options.get("catch_all_tooltip", ""))
	_catch_all.set_pressed_no_signal(_chosen.is_empty())

	_columns.value = clampi(int(config.get("columns", 1)), 1, CandyFieldsAreaWidget.MAX_COLUMNS)

	_refresh()
	popup_centered()


#* Fill _child_info and _schema_children from picker_children():
func _read_children(children: Array) -> void:
	_child_info = {}
	_schema_children = {}
	for child in children:
		var key := str(child["key"])
		_child_info[key] = child
		var slash := key.rfind("/")
		if slash < 0:
			continue
		var parent := key.substr(0, slash)
		if not _schema_children.has(parent):
			_schema_children[parent] = []
		_schema_children[parent].append(key.substr(slash + 1))


#* Copy the stored entries, each field once (even in a hand-edited layout):
func _read_entries(stored: Variant) -> Array:
	var result: Array = []
	if not stored is Array:
		return result
	var seen := {}
	for entry in stored:
		if not entry is Dictionary:
			if not seen.has(str(entry)):
				seen[str(entry)] = true
				result.append(str(entry))
			continue
		var ids: Array = []
		var inside = entry.get("fields", [])
		if inside is Array:
			for id in inside:
				if not seen.has(str(id)):
					seen[str(id)] = true
					ids.append(str(id))
		result.append({"name": str(entry.get("name", NEW_CATEGORY_NAME)),
			"folded": CandyVariantFile.to_bool(entry.get("folded", false), false), "fields": ids})
	return result


func _apply() -> void:
	applied.emit({
		"fields": _chosen.duplicate(true),
		"columns": int(_columns.value),
		"hidden_children": _hidden_children.keys(),
		"child_order": _child_order.duplicate(true),
	})


#& Building

func _add_column(title_text: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lists.add_child(column)

	var label := Label.new()
	label.text = title_text
	column.add_child(label)
	return column


func _middle_buttons() -> Control:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_button(CandyLocale.t("← Add"), func(): _add_fields(CandyListSelection.selected_indices(_available))))
	column.add_child(_button(CandyLocale.t("Remove →"), _on_remove_pressed))
	return column


func _button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	return button


#* Ids of every displayed field, categories included:
func _chosen_ids() -> Array:
	return CandyLineLayouts.field_ids(_chosen)


#* Ids of every displayed field and separator, categories included:
func _entry_ids() -> Array:
	var ids: Array = []
	for entry in _chosen:
		if entry is Dictionary:
			ids.append_array(entry["fields"])
		else:
			ids.append(entry)
	return ids


#* Rebuild both lists:
#? select: Displayed items to select, by _item_key(); select_categories: by index in _chosen.
func _refresh(select: Array = [], select_categories: Array = []) -> void:
	var catch_all := _catch_all.button_pressed
	var shade := 1.0
	var filter := Control.MOUSE_FILTER_STOP
	if catch_all:
		shade = 0.5
		filter = Control.MOUSE_FILTER_IGNORE
	_available_column.modulate.a = shade
	_middle.modulate.a = shade
	_available.mouse_filter = filter

	var shown := _chosen_ids()
	_available.clear()
	for field in _candidates:
		var id := str(field["id"])
		if shown.has(id):
			continue
		var index := _available.add_item(CandyLocale.t(str(field["label"])))
		_available.set_item_metadata(index, id)

	CandyTreeFolds.remember(_displayed, _displayed_folds)
	_displayed.clear()
	var tree_root := _displayed.create_item()
	var to_select: Array = []
	if catch_all:
		for id in _catch_all_ids:
			_add_field_item(tree_root, str(id), -1, false, select, to_select)
	else:
		var category_color := _displayed.get_theme_color(&"font_color", CandyThemeDefaults.SECTION_TITLE)
		for i in _chosen.size():
			var entry = _chosen[i]
			if not entry is Dictionary:
				_add_field_item(tree_root, str(entry), i, false, select, to_select)
				continue
			var category_item := _displayed.create_item(tree_root)
			category_item.set_text(0, str(entry["name"]))
			category_item.set_tooltip_text(0, CandyLocale.t("Category"))
			category_item.set_custom_color(0, category_color)
			category_item.set_metadata(0, {"kind": KIND_CATEGORY, "top": i, "field": "", "nested": false})
			if select_categories.has(i):
				to_select.append(category_item)
			for id in entry["fields"]:
				_add_field_item(category_item, str(id), i, true, select, to_select)
	CandyTreeFolds.restore(_displayed, _displayed_folds)

	#Ł Select after restore(), unfolding what holds them:
	for item in to_select:
		item.select(0)
		var parent: TreeItem = item.get_parent()
		while parent != null:
			parent.collapsed = false
			parent = parent.get_parent()


#* Add a top-level field or separator, its child fields folded under it:
func _add_field_item(parent: TreeItem, id: String, top: int, nested: bool, select: Array,
		to_select: Array) -> void:
	var item := _displayed.create_item(parent)
	item.set_text(0, _label_for(id))
	if CandyListSeparators.is_separator(id):
		item.set_tooltip_text(0, CandyLocale.t(CandyListSeparators.TOOLTIP))
	var data := {"kind": KIND_FIELD, "top": top, "field": id, "nested": nested}
	item.set_metadata(0, data)
	if select.has(id):
		to_select.append(item)
	if _schema_children.has(id):
		item.collapsed = true
		_add_child_items(item, id, data, select, to_select)


#* Add a field's children in their order, each ticked when shown:
#? top_data: the metadata of their top-level field.
func _add_child_items(parent_item: TreeItem, parent_key: String, top_data: Dictionary,
		select: Array, to_select: Array) -> void:
	for id in _child_ids(parent_key):
		var key := parent_key + "/" + str(id)
		var item := _displayed.create_item(parent_item)
		var data := top_data.duplicate()
		data["kind"] = KIND_CHILD
		data["parent"] = parent_key
		data["id"] = str(id)
		item.set_metadata(0, data)
		if select.has(key):
			to_select.append(item)
		if CandyListSeparators.is_separator(id):
			item.set_text(0, CandyLocale.t(CandyListSeparators.LABEL))
			item.set_tooltip_text(0, CandyLocale.t(CandyListSeparators.TOOLTIP))
			continue
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_text(0, _child_label(key, str(id)))
		item.set_tooltip_text(0, CandyLocale.t(CHILD_TOOLTIP))
		item.set_editable(0, true)
		item.set_checked(0, not _hidden_children.has(key))
		if _schema_children.has(key):
			item.collapsed = true
			_add_child_items(item, key, top_data, select, to_select)


#* An item's key for _refresh(): a top-level field's id, a child's schema path:
func _item_key(data: Dictionary) -> String:
	if data["kind"] == KIND_CHILD:
		return str(data["parent"]) + "/" + str(data["id"])
	return str(data["field"])


func _on_item_edited() -> void:
	var item := _displayed.get_edited()
	if item == null:
		return
	var data = item.get_metadata(0)
	if not data is Dictionary or data["kind"] != KIND_CHILD:
		return
	var key := _item_key(data)
	if item.is_checked(0):
		_hidden_children.erase(key)
	else:
		_hidden_children[key] = true


func _label_for(id: String) -> String:
	if CandyListSeparators.is_separator(id):
		return CandyLocale.t(CandyListSeparators.LABEL)
	for field in _candidates:
		if str(field["id"]) == id:
			return CandyLocale.t(str(field["label"]))
	return id  #/ Gone from the schema; shown so it can be removed


#* A child field's label, as shown (its id when the schema has none):
func _child_label(key: String, id: String) -> String:
	if _child_info.has(key) and _child_info[key].has("label"):
		return CandyLocale.t(str(_child_info[key]["label"]))
	return id


#& Child fields

#* A parent's child ids in their order, separators included (a new Array):
func _child_ids(parent_key: String) -> Array:
	return CandyFieldForm.ordered_ids(_schema_children.get(parent_key, []), _child_order.get(parent_key))


#* Store a parent's child order (forgotten when it's the schema's):
func _set_child_ids(parent_key: String, order: Array) -> void:
	if order == _schema_children.get(parent_key, []):
		_child_order.erase(parent_key)
	else:
		_child_order[parent_key] = order


#* Remove the separators among children ([[parent schema path, id], ...]):
func _erase_child_separators(children: Array) -> bool:
	var removed := false
	for pair in children:
		if not CandyListSeparators.is_separator(pair[1]):
			continue
		var order := _child_ids(str(pair[0]))
		order.erase(str(pair[1]))
		_set_child_ids(str(pair[0]), order)
		removed = true
	return removed


#* Every separator id in use, children's included (new ids are unique dialog-wide):
func _separator_ids() -> Array:
	var ids := _entry_ids()
	for parent in _child_order:
		ids.append_array(_child_order[parent])
	return ids


#& Editing

#* The Displayed selection, in tree order:
func _displayed_selection() -> Dictionary:
	var fields: Array = []
	var categories: Array = []
	var children: Array = []
	for item in CandyListSelection.selected_tree_items(_displayed):
		var data = item.get_metadata(0)
		if not data is Dictionary:
			continue
		match str(data["kind"]):
			KIND_CHILD:
				children.append([str(data["parent"]), str(data["id"])])
			KIND_CATEGORY:
				if not categories.has(int(data["top"])):
					categories.append(int(data["top"]))
			_:
				fields.append(str(data["field"]))
	return {"fields": fields, "categories": categories, "children": children}	#/ categories: indexes in _chosen


#* The category the first selected item is in or on, -1 for none:
func _selected_category() -> int:
	var item := _displayed.get_next_selected(null)
	if item == null:
		return -1
	var data = item.get_metadata(0)
	if not data is Dictionary:
		return -1
	if data["kind"] == KIND_CATEGORY or bool(data["nested"]):
		return int(data["top"])
	return -1


#* Add the Available fields at indices to the selected category or the end, and select them:
func _add_fields(indices: Array) -> void:
	if _catch_all.button_pressed or indices.is_empty():
		return
	var ids: Array = []
	for index in indices:
		if int(index) >= 0 and int(index) < _available.item_count:
			ids.append(str(_available.get_item_metadata(int(index))))
	if ids.is_empty():
		return
	var category := _selected_category()
	if category >= 0:
		_chosen[category]["fields"].append_array(ids)
	else:
		_chosen.append_array(ids)
	_refresh(ids)


#* Remove the selected fields and child separators (not categories nor child fields):
func _on_remove_pressed() -> void:
	var selection := _displayed_selection()
	var removed := _erase_child_separators(selection["children"])
	var ids: Array = selection["fields"]
	if not _catch_all.button_pressed and not ids.is_empty():
		_erase_fields(ids)
		removed = true
	if removed:
		_refresh()


#* Remove field ids from the list, wherever they are:
func _erase_fields(ids: Array) -> void:
	for id in ids:
		_chosen.erase(id)
	for entry in _chosen:
		if entry is Dictionary:
			for id in ids:
				entry["fields"].erase(id)


#* Double-click - rename a category, remove a field or separator:
func _on_displayed_activated() -> void:
	var item := _displayed.get_selected()
	if item == null:
		return
	var data = item.get_metadata(0)
	if not data is Dictionary:
		return
	match str(data["kind"]):
		KIND_CATEGORY:
			_on_rename_category_pressed()
		KIND_CHILD:
			if _erase_child_separators([[str(data["parent"]), str(data["id"])]]):
				_refresh()
		_:
			_on_remove_pressed()


func _on_catch_all_toggled(pressed: bool) -> void:
	if pressed:
		_chosen.clear()
	_refresh()


#& Categories and separators

func _has_category(category_name: String, except_index: int = -1) -> bool:
	for i in _chosen.size():
		if i != except_index and _chosen[i] is Dictionary and str(_chosen[i]["name"]) == category_name:
			return true
	return false


func _unique_category_name(base: String) -> String:
	if not _has_category(base):
		return base
	var number := 2
	while _has_category("%s %d" % [base, number]):
		number += 1
	return "%s %d" % [base, number]


#* Add a category after the selected item's top-level place, or at the end:
func _on_add_category_pressed() -> void:
	if _catch_all.button_pressed:
		return
	var at := _chosen.size()
	var item := _displayed.get_next_selected(null)
	if item != null and item.get_metadata(0) is Dictionary:
		at = int(item.get_metadata(0)["top"]) + 1
	_name_prompt.prompt(CandyLocale.t("New Category"), _unique_category_name(NEW_CATEGORY_NAME),
		func(new_name: String) -> String:
			if _has_category(new_name):
				return CandyLocale.t("This area already has a category called \"%s\".") % new_name
			return "",
		func(new_name: String) -> void:
			_chosen.insert(mini(at, _chosen.size()), {"name": new_name, "folded": false, "fields": []})
			_refresh([], [mini(at, _chosen.size() - 1)]))


#* Add a separator after the selected child or field, or at the end (of the selected category):
func _on_add_separator_pressed() -> void:
	#? Unique dialog-wide - moving and removing find entries by id.
	var id := CandyListSeparators.new_id(_separator_ids())
	var item := _displayed.get_next_selected(null)
	var data = null
	if item != null:
		data = item.get_metadata(0)
	if data is Dictionary and data["kind"] == KIND_CHILD:
		var parent := str(data["parent"])
		var order := _child_ids(parent)
		order.insert(order.find(str(data["id"])) + 1, id)
		_set_child_ids(parent, order)
		_refresh([parent + "/" + id])
		return
	if _catch_all.button_pressed:
		return

	var container: Array = _chosen
	var at := _chosen.size()
	if data is Dictionary:
		var top := int(data["top"])
		if data["kind"] == KIND_CATEGORY:
			container = _chosen[top]["fields"]
			at = container.size()
		elif bool(data["nested"]):
			container = _chosen[top]["fields"]
			at = container.find(str(data["field"])) + 1
		else:
			at = top + 1
	container.insert(at, id)
	_refresh([id])


func _on_rename_category_pressed() -> void:
	var index := _selected_category()
	if _catch_all.button_pressed or index < 0:
		return
	_name_prompt.prompt(CandyLocale.t("Rename Category"), str(_chosen[index]["name"]),
		func(new_name: String) -> String:
			if _has_category(new_name, index):
				return CandyLocale.t("This area already has a category called \"%s\".") % new_name
			return "",
		func(new_name: String) -> void:
			_chosen[index]["name"] = new_name
			_refresh([], [index]))


#* Delete the selected categories and separators (a category's fields go back to Available):
func _on_delete_pressed() -> void:
	var selection := _displayed_selection()
	var removed := _erase_child_separators(selection["children"])
	if not _catch_all.button_pressed:
		var indices: Array = selection["categories"]
		var separators: Array = []
		for id in selection["fields"]:
			if CandyListSeparators.is_separator(id):
				separators.append(id)
		#Ł Categories first - removing a top-level separator would shift their indices:
		indices.sort()
		indices.reverse()
		for index in indices:
			_chosen.remove_at(int(index))
		_erase_fields(separators)
		if not indices.is_empty() or not separators.is_empty():
			removed = true
	if removed:
		_refresh()


#& Dragging in Displayed

#* Start a drag - the selected fields, else categories, else children of the hovered one's parent:
func _get_displayed_drag(at_position: Vector2) -> Variant:
	var under := _displayed.get_item_at_position(at_position)
	if under == null:
		return null
	#Ł The hovered item joins the selection:
	if not under.is_selected(0):
		_displayed.deselect_all()
		under.select(0)
	var selection := _displayed_selection()
	var ids: Array = selection["fields"]
	var categories: Array = selection["categories"]
	#% Under the catch-all only child fields move:
	if _catch_all.button_pressed:
		ids = []
		categories = []

	var preview := Label.new()
	var data := {"source": CandyListSelection.DRAG_SOURCE, "tree": _displayed.get_instance_id()}
	if not ids.is_empty():
		data["fields"] = ids
		preview.text = CandyLocale.tn("%d field", "%d fields", ids.size()) % ids.size()
		if ids.size() == 1:
			preview.text = _label_for(str(ids[0]))
		_displayed.drop_mode_flags = Tree.DROP_MODE_INBETWEEN | Tree.DROP_MODE_ON_ITEM
	elif not categories.is_empty():
		data["categories"] = categories
		preview.text = CandyLocale.tn("%d category", "%d categories", categories.size()) % categories.size()
		if categories.size() == 1:
			preview.text = str(_chosen[int(categories[0])]["name"])
		_displayed.drop_mode_flags = Tree.DROP_MODE_INBETWEEN
	else:
		var under_data = under.get_metadata(0)
		if not under_data is Dictionary or under_data["kind"] != KIND_CHILD:
			return null
		var parent := str(under_data["parent"])
		var children: Array = []
		for pair in selection["children"]:
			if pair[0] == parent:
				children.append(pair[1])
		data["parent"] = parent
		data["children"] = children
		preview.text = CandyLocale.tn("%d field", "%d fields", children.size()) % children.size()
		if children.size() == 1:
			preview.text = under.get_text(0)
		_displayed.drop_mode_flags = Tree.DROP_MODE_INBETWEEN
	_displayed.set_drag_preview(preview)
	return data


func _can_drop_displayed(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("source") == CandyListSelection.DRAG_SOURCE \
		and data.get("tree") == _displayed.get_instance_id()


func _drop_displayed(at_position: Vector2, data: Variant) -> void:
	_displayed.drop_mode_flags = Tree.DROP_MODE_DISABLED
	var target := _displayed.get_item_at_position(at_position)
	var section := _displayed.get_drop_section_at_position(at_position)
	var target_data = null
	if target != null:
		target_data = target.get_metadata(0)
	if data.has("children"):
		_drop_children(str(data["parent"]), data["children"], target_data, section)
		return
	#% Dropped on a child field - after its top-level field:
	if target_data is Dictionary and target_data["kind"] == KIND_CHILD:
		section = 1
	if data.has("fields"):
		_drop_fields(data["fields"], target_data, section)
	else:
		_drop_categories(data["categories"], target_data, section)


#* Drop fields:
func _drop_fields(ids: Array, target_data: Variant, section: int) -> void:
	var category: Dictionary = {}    #/ Category they land in; empty for the top level
	var anchor: Variant = null       #/ Entry they land next to; null for an end
	var after := true
	if target_data is Dictionary:
		var top := int(target_data["top"])
		var field := str(target_data["field"])
		#¦ 1. A category - at its top when dropped on or below, else before it:
		if field == "":
			after = false
			if section < 0:
				anchor = _chosen[top]
			else:
				category = _chosen[top]
		#¦ 2. A field - before / after it (by half):
		else:
			anchor = field
			after = section >= 0
			if bool(target_data["nested"]):
				category = _chosen[top]
	if anchor is String and ids.has(anchor):
		return  #/ Dropped onto itself

	_erase_fields(ids)
	var container: Array = _chosen
	if not category.is_empty():
		container = category["fields"]
	var at := container.size()		#/ Else at the end
	if anchor != null:
		at = _index_of(container, anchor)
		if after:
			at += 1
	elif not after:
		at = 0
	for i in ids.size():
		container.insert(at + i, ids[i])
	_refresh(ids)


#* Where entry (a field id, or a category) is in container:
func _index_of(container: Array, entry: Variant) -> int:
	for i in container.size():
		if entry is Dictionary:
			if is_same(container[i], entry):
				return i
		elif container[i] is String and container[i] == entry:
			return i
	return container.size()


#* Drop categories - before the hovered top-level entry (top half), after it, or at the end:
func _drop_categories(indices: Array, target_data: Variant, section: int) -> void:
	var slot := _chosen.size()
	if target_data is Dictionary:
		slot = int(target_data["top"])
		if section >= 0:
			slot += 1
	var moved := CandyListSelection.move_to(_chosen, indices, slot)
	_refresh([], moved)


#* Drop child fields among their siblings only (first when dropped below their parent):
func _drop_children(parent: String, ids: Array, target_data: Variant, section: int) -> void:
	if ids.is_empty() or not target_data is Dictionary:
		return
	var order := _child_ids(parent)
	var anchor := ""    #/ Child they land next to; "" for the first place
	var after := section >= 0
	if target_data["kind"] == KIND_CHILD and str(target_data["parent"]) == parent:
		anchor = str(target_data["id"])
		if ids.has(anchor):
			return  #/ Dropped onto itself
	elif _item_key(target_data) != parent or section < 0:
		return		#/ Anywhere else they stay

	for id in ids:
		order.erase(id)
	var at := 0
	if anchor != "":
		at = order.find(anchor)
		if after:
			at += 1
	for i in ids.size():
		order.insert(at + i, ids[i])
	_set_child_ids(parent, order)
	var keys: Array = []
	for id in ids:
		keys.append(parent + "/" + str(id))
	_refresh(keys)
