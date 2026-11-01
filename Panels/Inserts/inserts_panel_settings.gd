#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyInsertsPanelSettings
extends AcceptDialog

signal categories_changed(categories: Array)
#^ Read the new values from the layout options:
signal layout_changed(options: CandyButtonLayoutOptions)
signal reference_changed(reference: String)

const NEW_CATEGORY_NAME := "Category"
const PAGE_OPTIONS := "Options"	#/ translatable
const PAGE_BUTTONS := "Buttons"	#/ translatable

#^ [{ "name" = String, "folded" = bool, "inserts" = [id, ...] }, ...]:
var _categories: Array = []

var _displayed: Tree
var _available: Tree
#^ Folded categories of each list, kept across refreshes:
var _displayed_folds: Dictionary = {}
var _available_folds: Dictionary = {}
var _layout_options: CandyButtonLayoutOptions
var _reference_edit: LineEdit
var min_size_fields: CandyMinSizeFields
var _name_prompt: CandyNamePrompt
var _options_page: VBoxContainer
var _buttons_page: VBoxContainer


func _init() -> void:
	ok_button_text = CandyLocale.t("Close")

	var pages := VBoxContainer.new()
	add_child(pages)
	_options_page = VBoxContainer.new()
	pages.add_child(_options_page)
	_buttons_page = VBoxContainer.new()
	_buttons_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pages.add_child(_buttons_page)

	#& Options
	var reference_row := HBoxContainer.new()
	_options_page.add_child(reference_row)
	var reference_label := Label.new()
	reference_label.text = CandyLocale.t("Reference")
	reference_label.tooltip_text = CandyLocale.t("The color tags ([color], [bgcolor]...) take the color of the Color Selector with this reference.")
	reference_label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	reference_row.add_child(reference_label)
	_reference_edit = LineEdit.new()
	_reference_edit.custom_minimum_size.x = 120
	_reference_edit.tooltip_text = reference_label.tooltip_text
	_reference_edit.text_changed.connect(func(typed: String):
		if typed.strip_edges() != "":
			reference_changed.emit(typed.strip_edges()))
	reference_row.add_child(_reference_edit)

	_options_page.add_child(HSeparator.new())
	_layout_options = CandyButtonLayoutOptions.new()
	_layout_options.changed.connect(func(): layout_changed.emit(_layout_options))
	_options_page.add_child(_layout_options)

	min_size_fields = CandyMinSizeFields.new()
	_options_page.add_child(min_size_fields)

	#& Buttons
	var lists := HBoxContainer.new()
	lists.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_buttons_page.add_child(lists)

	#Ł Displayed, on the left:
	var displayed_column := _build_column(lists, CandyLocale.t("Displayed"))
	_displayed = _build_tree(displayed_column)
	_displayed.item_activated.connect(_on_displayed_activated)
	_displayed.set_drag_forwarding(_get_displayed_drag, _can_drop_displayed, _drop_displayed)

	#? Wraps, so the buttons don't make the column wider than the Available one.
	var category_row := HFlowContainer.new()
	displayed_column.add_child(category_row)
	category_row.add_child(_build_tool_button(CandyLocale.t("Add Category"), _on_add_category_pressed))
	var add_separator := _build_tool_button(CandyLocale.t("Add Separator"), _on_add_separator_pressed)
	add_separator.tooltip_text = CandyLocale.t("A horizontal line after the selected insert, or at the end of the selected category.")
	category_row.add_child(add_separator)
	var add_row := _build_tool_button(CandyLocale.t("Add Row"), _on_add_row_pressed)
	add_row.tooltip_text = CandyLocale.t("Starts a new row of buttons after the selected insert, or at the end of the selected category.")
	category_row.add_child(add_row)
	category_row.add_child(_build_tool_button(CandyLocale.t("Rename"), _on_rename_category_pressed))
	var delete := _build_tool_button(CandyLocale.t("Delete"), _on_delete_pressed)
	delete.tooltip_text = CandyLocale.t("Deletes the selected categories, separators and rows. The inserts of a deleted category go back to Available.")
	category_row.add_child(delete)

	#Ł Add / Remove, between the lists:
	var middle := VBoxContainer.new()
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	lists.add_child(middle)
	middle.add_child(_build_tool_button(CandyLocale.t("← Add"), _on_add_pressed))
	middle.add_child(_build_tool_button(CandyLocale.t("Remove →"), _on_remove_pressed))

	#Ł Available, on the right:
	var available_column := _build_column(lists, CandyLocale.t("Available"))
	_available = _build_tree(available_column)
	_available.item_activated.connect(_on_add_pressed)

	var note := Label.new()
	note.text = CandyLocale.t("Select a category on the left, then add inserts to it. Double-click an insert to add or remove it. Separators and rows are removed like inserts.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = 560
	note.theme_type_variation = CandyThemeDefaults.NOTE
	_buttons_page.add_child(note)

	_name_prompt = CandyNamePrompt.new()
	add_child(_name_prompt)

	CandyInserts.inserts_changed.connect(func():
		if visible:
			_refresh())


#* Open on a page (PAGE_OPTIONS or PAGE_BUTTONS):
func open(categories: Array, layout: String, columns: int, min_width: int, alignment: String,
		scroll: bool, reference: String, page: String = PAGE_OPTIONS) -> void:
	var buttons := page == PAGE_BUTTONS
	title = CandyLocale.t(page)
	_options_page.visible = not buttons
	_buttons_page.visible = buttons
	if buttons:
		min_size = Vector2i(620, 440)
	else:
		min_size = Vector2i(0, 0)
	_categories = categories.duplicate(true)
	_reference_edit.text = reference
	#Ł Drop deleted inserts (invisible, they'd make moves look like they do nothing):
	if CandyInserts.is_loaded():
		for category in _categories:
			var kept: Array = []
			for id in category["inserts"]:
				if CandyInserts.has_insert(str(id)) or _is_divider(id) or CandySpeechInsertMenus.is_menu(id):
					kept.append(str(id))
			category["inserts"] = kept
	_layout_options.set_values(layout, columns, min_width, alignment, scroll)
	_refresh()
	reset_size()
	popup_centered()


#& Building

func _build_column(parent: Control, heading: String) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	var label := Label.new()
	label.text = heading
	column.add_child(label)
	return column


func _build_tree(parent: Control) -> Tree:
	var tree := Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.hide_root = true
	tree.allow_reselect = true
	tree.select_mode = Tree.SELECT_MULTI
	parent.add_child(tree)
	return tree


func _build_tool_button(label_text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	return button


#& Lists

#* Rebuild both lists:
#? selected_category / selected_id: what to select afterwards.
func _refresh(selected_category: int = -2, selected_id: String = "") -> void:
	if selected_category == -2:			#/ Keep the current selection
		var current := _displayed_selection()
		selected_category = current[0]
		selected_id = current[1]

	CandyTreeFolds.remember(_displayed, _displayed_folds)
	CandyTreeFolds.remember(_available, _available_folds)
	_displayed.clear()
	var displayed_root := _displayed.create_item()
	for i in _categories.size():
		var category: Dictionary = _categories[i]
		var category_item := _displayed.create_item(displayed_root)
		category_item.set_text(0, str(category["name"]))
		category_item.set_metadata(0, {"category": i, "id": ""})
		if i == selected_category and selected_id == "":
			category_item.select(0)
		for id in category["inserts"]:
			var label_text := CandyLocale.t(CandyListSeparators.LABEL)
			var tooltip := CandyLocale.t(CandyListSeparators.TOOLTIP)
			if CandyListRowBreaks.is_row_break(id):
				label_text = CandyLocale.t(CandyListRowBreaks.LABEL)
				tooltip = CandyLocale.t(CandyListRowBreaks.TOOLTIP)
			elif CandySpeechInsertMenus.is_menu(id):
				label_text = CandyLocale.t(CandySpeechInsertMenus.title_of(id))
				tooltip = CandyLocale.t(CandySpeechInsertMenus.tooltip_of(id))
			elif not CandyListSeparators.is_separator(id):
				var insert := CandyInserts.get_insert(str(id))
				if insert.is_empty():
					continue
				label_text = str(insert["label"])
				if insert["type"] == CandyInserts.TYPE_NATIVE:
					label_text = CandyLocale.t(str(insert["label"]))
				tooltip = _describe(insert)
			var item := _displayed.create_item(category_item)
			item.set_text(0, label_text)
			item.set_tooltip_text(0, tooltip)
			item.set_metadata(0, {"category": i, "id": str(id)})
			if i == selected_category and str(id) == selected_id:
				item.select(0)

	var shown := _displayed_ids()
	_available.clear()
	var available_root := _available.create_item()
	for category_name in CandyInserts.categories():
		var category_item: TreeItem = null
		for id in CandyInserts.ids_in_category(str(category_name)):
			if shown.has(id):
				continue
			if category_item == null:
				category_item = _available.create_item(available_root)
				category_item.set_text(0, str(category_name))
				category_item.set_selectable(0, false)
				category_item.set_metadata(0, "")
			var insert := CandyInserts.get_insert(str(id))
			var item := _available.create_item(category_item)
			item.set_text(0, str(insert["label"]))
			if insert["type"] == CandyInserts.TYPE_NATIVE:
				item.set_text(0, CandyLocale.t(str(insert["label"])))
			item.set_tooltip_text(0, _describe(insert))
			item.set_metadata(0, str(id))

	#Ł The Text Events and Lexicon drop-downs, in a category of their own:
	var menus_item: TreeItem = null
	for id in CandySpeechInsertMenus.all_ids():
		if shown.has(id):
			continue
		if menus_item == null:
			menus_item = _available.create_item(available_root)
			menus_item.set_text(0, CandyLocale.t(CandySpeechInsertMenus.CATEGORY))
			menus_item.set_selectable(0, false)
			menus_item.set_metadata(0, "")
		var item := _available.create_item(menus_item)
		item.set_text(0, CandyLocale.t(CandySpeechInsertMenus.title_of(id)))
		item.set_tooltip_text(0, CandyLocale.t(CandySpeechInsertMenus.tooltip_of(id)))
		item.set_metadata(0, str(id))

	CandyTreeFolds.restore(_displayed, _displayed_folds)
	CandyTreeFolds.restore(_available, _available_folds)


#* An insert's tooltip:
func _describe(insert: Dictionary) -> String:
	var lines: PackedStringArray = []
	if insert["type"] == CandyInserts.TYPE_NATIVE:
		lines.append(CandyLocale.t("Built in"))
	elif insert["type"] == CandyInserts.TYPE_USER:
		lines.append(CandyLocale.t("User insert (%s)") % insert["category"])
	else:
		lines.append(CandyLocale.t("Profile insert (%s)") % insert["category"])
	var parts := [[CandyLocale.t("Left: \"%s\""), "left"], [CandyLocale.t("Middle: \"%s\""), "middle"],
		[CandyLocale.t("Right: \"%s\""), "right"]]
	for part in parts:
		var value := str(insert[part[1]])
		if value != "":
			lines.append(str(part[0]) % value)
	return "\n".join(lines)


func _displayed_ids() -> Array:
	var result: Array = []
	for category in _categories:
		for id in category["inserts"]:
			result.append(str(id))
	return result


#* Displayed's selection: [category index or -1, insert id or ""]:
func _displayed_selection() -> Array:
	var item := _displayed.get_selected()
	if item == null:
		return [-1, ""]
	var data = item.get_metadata(0)
	if not data is Dictionary:
		return [-1, ""]
	return [int(data["category"]), str(data["id"])]


func _emit() -> void:
	categories_changed.emit(_categories.duplicate(true))


#& Inserts

#* Add every selected Available insert, in order:
func _on_add_pressed() -> void:
	var shown := _displayed_ids()
	var ids: Array = []
	for item in CandyListSelection.selected_tree_items(_available):
		var id := str(item.get_metadata(0))
		if id != "" and not shown.has(id) and not ids.has(id):
			ids.append(id)
	if ids.is_empty():
		return

	#Ł Into the selected category, or the last one (made if none):
	var target: int = _displayed_selection()[0]
	if target < 0 or target >= _categories.size():
		if _categories.is_empty():
			_categories.append(_new_category(_unique_category_name(NEW_CATEGORY_NAME)))
		target = _categories.size() - 1
	_categories[target]["inserts"].append_array(ids)
	_refresh(target, str(ids[0]))
	_select_displayed_ids(ids)
	_emit()


#* Remove every selected Displayed insert (categories are left alone):
func _on_remove_pressed() -> void:
	var removed := false
	var last_category := -1
	for item in CandyListSelection.selected_tree_items(_displayed):
		var data = item.get_metadata(0)
		if not data is Dictionary or str(data["id"]) == "":
			continue
		_categories[int(data["category"])]["inserts"].erase(str(data["id"]))
		last_category = int(data["category"])
		removed = true
	if not removed:
		return
	_refresh(last_category, "")
	_emit()


#* Select the Displayed items of these insert ids:
func _select_displayed_ids(ids: Array) -> void:
	var item := _displayed.get_root()
	while item != null:
		var data = item.get_metadata(0)
		if data is Dictionary and ids.has(str(data["id"])):
			item.select(0)
		item = item.get_next_in_tree()


#& Dragging in Displayed

#* Drag the selected inserts, or with none, the selected categories:
func _get_displayed_drag(at_position: Vector2) -> Variant:
	var under := _displayed.get_item_at_position(at_position)
	if under == null:
		return null
	#Ł An item outside the selection replaces it:
	if not under.is_selected(0):
		_displayed.deselect_all()
		under.select(0)
	var ids: Array = []
	var categories: Array = []
	for item in CandyListSelection.selected_tree_items(_displayed):
		var item_data = item.get_metadata(0)
		if not item_data is Dictionary:
			continue
		if str(item_data["id"]) != "":
			ids.append(str(item_data["id"]))
		elif not categories.has(int(item_data["category"])):
			categories.append(int(item_data["category"]))

	var preview := Label.new()
	var data := {"source": CandyListSelection.DRAG_SOURCE, "tree": _displayed.get_instance_id()}
	if not ids.is_empty():
		data["ids"] = ids
		preview.text = CandyLocale.tn("%d insert", "%d inserts", ids.size()) % ids.size()
		if ids.size() == 1 and CandyListSeparators.is_separator(ids[0]):
			preview.text = CandyLocale.t(CandyListSeparators.LABEL)
		elif ids.size() == 1 and CandyListRowBreaks.is_row_break(ids[0]):
			preview.text = CandyLocale.t(CandyListRowBreaks.LABEL)
		elif ids.size() == 1 and CandySpeechInsertMenus.is_menu(ids[0]):
			preview.text = CandyLocale.t(CandySpeechInsertMenus.title_of(ids[0]))
		elif ids.size() == 1:
			var dragged := CandyInserts.get_insert(str(ids[0]))
			preview.text = str(dragged.get("label", ids[0]))
			if dragged.get("type", "") == CandyInserts.TYPE_NATIVE:
				preview.text = CandyLocale.t(str(dragged.get("label", ids[0])))
		_displayed.drop_mode_flags = Tree.DROP_MODE_INBETWEEN | Tree.DROP_MODE_ON_ITEM
	else:
		data["categories"] = categories
		preview.text = CandyLocale.tn("%d category", "%d categories", categories.size()) % categories.size()
		if categories.size() == 1:
			preview.text = str(_categories[int(categories[0])]["name"])
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
	if data.has("ids"):
		_drop_inserts(data["ids"], target_data, section)
	else:
		_drop_categories(data["categories"], target_data, section)


#* Move inserts to where they're dropped:
func _drop_inserts(ids: Array, target_data: Variant, section: int) -> void:
	var category := _categories.size() - 1			#/ Off the list: the very end
	var anchor := ""    #/ Insert they land next to; "" for a category's top or end
	var after := true
	if target_data is Dictionary:
		category = int(target_data["category"])
		anchor = str(target_data["id"])
		if anchor == "":			#/ On or below a category: its top
			after = false
			if section < 0 and category > 0:			#/ Above a category: the end of the one before
				category -= 1
				after = true
		else:
			after = section >= 0			#/ On an insert: before or after it, by its half
	if category < 0 or ids.has(anchor):
		return  #/ Nowhere to go, or dropped onto itself

	for each in _categories:
		for id in ids:
			each["inserts"].erase(id)
	var inserts: Array = _categories[category]["inserts"]
	var at := inserts.size()
	if anchor != "":
		at = inserts.find(anchor)
		if after:
			at += 1
	elif not after:
		at = 0
	for i in ids.size():
		inserts.insert(at + i, ids[i])
	_refresh(category, str(ids[0]))
	_select_displayed_ids(ids)
	_emit()


#* Move categories to where they're dropped:
func _drop_categories(indices: Array, target_data: Variant, section: int) -> void:
	var slot := _categories.size()			#/ Off the list: the end
	if target_data is Dictionary:
		slot = int(target_data["category"])			#/ The category, or the insert's category
		if section >= 0:			#/ Bottom half: after
			slot += 1
	var moved := CandyListSelection.move_to(_categories, indices, slot)
	_refresh(int(moved[0]), "")
	for index in moved:
		_select_category(int(index))
	_emit()


func _select_category(index: int) -> void:
	var item := _displayed.get_root().get_first_child()
	while item != null:
		var data = item.get_metadata(0)
		if data is Dictionary and int(data["category"]) == index and str(data["id"]) == "":
			item.select(0)
		item = item.get_next()


func _on_displayed_activated() -> void:
	if _displayed_selection()[1] == "":
		_on_rename_category_pressed()
	else:
		_on_remove_pressed()


#& Categories

func _new_category(category_name: String) -> Dictionary:
	return {"name": category_name, "folded": false, "inserts": []}


func _has_category(category_name: String, except_index: int = -1) -> bool:
	for i in _categories.size():
		if i != except_index and str(_categories[i]["name"]) == category_name:
			return true
	return false


func _unique_category_name(base: String) -> String:
	if not _has_category(base):
		return base
	var number := 2
	while _has_category("%s %d" % [base, number]):
		number += 1
	return "%s %d" % [base, number]


func _on_add_category_pressed() -> void:
	var after: int = _displayed_selection()[0]
	_name_prompt.prompt(CandyLocale.t("New Category"), _unique_category_name(NEW_CATEGORY_NAME),
		func(new_name: String) -> String:
			if _has_category(new_name):
				return CandyLocale.t("This panel already has a category called \"%s\".") % new_name
			return "",
		func(new_name: String) -> void:
			var index := _categories.size()
			if after >= 0 and after < _categories.size():
				index = after + 1
			_categories.insert(index, _new_category(new_name))
			_refresh(index, "")
			_emit())


func _on_add_separator_pressed() -> void:
	#? Unique in the whole panel - moves and removals find entries by id.
	_add_divider(CandyListSeparators.new_id(_displayed_ids()))


func _on_add_row_pressed() -> void:
	_add_divider(CandyListRowBreaks.new_id(_displayed_ids()))


#* Whether id is a separator or a row break:
func _is_divider(id: Variant) -> bool:
	return CandyListSeparators.is_separator(id) or CandyListRowBreaks.is_row_break(id)


#* Put a separator or row break after the selected entry:
func _add_divider(id: String) -> void:
	var selection := _displayed_selection()
	var target: int = selection[0]
	if target < 0 or target >= _categories.size():			#/ None selected: the last category, made if none
		if _categories.is_empty():
			_categories.append(_new_category(_unique_category_name(NEW_CATEGORY_NAME)))
		target = _categories.size() - 1
	var inserts: Array = _categories[target]["inserts"]
	var at := inserts.size()			#/ No entry selected: the category's end
	if str(selection[1]) != "" and inserts.has(selection[1]):
		at = inserts.find(selection[1]) + 1
	inserts.insert(at, id)
	_refresh(target, id)
	_emit()


func _on_rename_category_pressed() -> void:
	var index: int = _displayed_selection()[0]
	if index < 0:
		return
	_name_prompt.prompt(CandyLocale.t("Rename Category"), str(_categories[index]["name"]),
		func(new_name: String) -> String:
			if _has_category(new_name, index):
				return CandyLocale.t("This panel already has a category called \"%s\".") % new_name
			return "",
		func(new_name: String) -> void:
			_categories[index]["name"] = new_name
			_refresh(index, "")
			_emit())


#* Delete the selected categories, separators and row breaks:
func _on_delete_pressed() -> void:
	var indices: Array = []
	var separators: Array = []
	for item in CandyListSelection.selected_tree_items(_displayed):
		var data = item.get_metadata(0)
		if not data is Dictionary:
			continue
		if str(data["id"]) == "":
			if not indices.has(int(data["category"])):
				indices.append(int(data["category"]))
		elif _is_divider(data["id"]):
			separators.append(str(data["id"]))
	if indices.is_empty() and separators.is_empty():
		return
	for category in _categories:
		for id in separators:
			category["inserts"].erase(id)
	indices.sort()
	indices.reverse()
	for index in indices:
		_categories.remove_at(int(index))			#/ Its inserts go back to Available
	var select := -1
	if not indices.is_empty():
		select = mini(int(indices[-1]), _categories.size() - 1)
	_refresh(select, "")
	_emit()
