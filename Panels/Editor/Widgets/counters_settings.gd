#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyCountersSettings
extends AcceptDialog

signal applied(config: Dictionary)

#^ Content column width:
#? Wrapping labels need an explicit width, or the dialog opens too tall.
const CONTENT_WIDTH := 428
const LABEL_WIDTH := 100
const LIST_HEIGHT := 130

var _reference: LineEdit
var _compare_reference: LineEdit
var _shown_list: ItemList
var _available_list: ItemList
var _columns: SpinBox
var _min_size: CandyMinSizeFields
#^ The ids of the stats shown, in order:
var _stats: Array = []


func _init() -> void:
	title = CandyLocale.t("Counters")
	ok_button_text = CandyLocale.t("Close")
	min_size = Vector2i(460, 0)

	var root := VBoxContainer.new()
	root.custom_minimum_size.x = CONTENT_WIDTH
	add_child(root)

	_reference = _add_line_row(root, CandyLocale.t("Reference 1"),
		CandyLocale.t("Counts the variation picked in the Variation Selector with this reference."))
	_compare_reference = _add_line_row(root, CandyLocale.t("Reference 2"),
		CandyLocale.t("C. Diff. and W. Diff. compare Reference 1 with the variation picked in the Variation Selector with this reference."))

	root.add_child(HSeparator.new())

	var lists := HBoxContainer.new()
	root.add_child(lists)

	_shown_list = _add_list_column(lists, CandyLocale.t("Displayed"))
	_shown_list.item_activated.connect(func(_index: int): _on_remove_pressed())
	CandyListSelection.enable_reorder(_shown_list, func(indices: Array, slot: int):
		var moved := CandyListSelection.move_to(_stats, indices, slot)
		_refresh_lists()
		CandyListSelection.select_indices(_shown_list, moved))

	var middle := VBoxContainer.new()
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	lists.add_child(middle)
	middle.add_child(_tool_button(CandyLocale.t("← Add"), _on_add_pressed))
	middle.add_child(_tool_button(CandyLocale.t("Remove →"), _on_remove_pressed))

	_available_list = _add_list_column(lists, CandyLocale.t("Available"))
	_available_list.select_mode = ItemList.SELECT_MULTI
	_available_list.item_activated.connect(func(_index: int): _on_add_pressed())

	var note := Label.new()
	note.text = CandyLocale.t("Drag the displayed stats to change their order.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = CONTENT_WIDTH
	note.theme_type_variation = CandyThemeDefaults.NOTE
	root.add_child(note)

	var columns_row := HBoxContainer.new()
	root.add_child(columns_row)
	var columns_label := Label.new()
	columns_label.text = CandyLocale.t("Columns")
	columns_label.custom_minimum_size.x = LABEL_WIDTH
	columns_label.tooltip_text = CandyLocale.t("How many columns the stats are split across.")
	columns_label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	columns_row.add_child(columns_label)
	_columns = SpinBox.new()
	_columns.min_value = 1
	_columns.max_value = CandyCountersWidget.STATS.size()
	columns_row.add_child(_columns)

	_min_size = CandyMinSizeFields.new()
	root.add_child(_min_size)

	confirmed.connect(_apply)
	canceled.connect(_apply)


func _add_line_row(root: VBoxContainer, label_text: String, tooltip: String) -> LineEdit:
	var row := HBoxContainer.new()
	root.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = LABEL_WIDTH
	label.tooltip_text = tooltip
	label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	row.add_child(label)
	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.tooltip_text = tooltip
	row.add_child(edit)
	return edit


func _add_list_column(lists: HBoxContainer, column_title: String) -> ItemList:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lists.add_child(column)

	var label := Label.new()
	label.text = column_title
	column.add_child(label)

	var list := ItemList.new()
	list.custom_minimum_size.y = LIST_HEIGHT
	list.allow_reselect = true
	column.add_child(list)
	return list


func _tool_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(handler)
	return button


func open(config: Dictionary) -> void:
	_reference.text = str(config.get("reference", CandyVariationSelection.DEFAULT_REFERENCE))
	_compare_reference.text = str(config.get("compare_reference",
		CandyCountersWidget.DEFAULT_COMPARE_REFERENCE))
	_stats = CandyCountersWidget.stats_of(config)
	_columns.value = CandyCountersWidget.columns_of(config)
	_refresh_lists()
	_min_size.load_config(config)

	#Ł The dialog is reused - drop the previous size:
	reset_size()
	popup_centered()


#* Refresh both lists:
func _refresh_lists() -> void:
	_shown_list.clear()
	for id in _stats:
		_add_stat_item(_shown_list, str(id))
	#Ł Available - stats not displayed, in default order:
	_available_list.clear()
	for id in CandyCountersWidget.STATS:
		if not _stats.has(id):
			_add_stat_item(_available_list, str(id))


func _add_stat_item(list: ItemList, id: String) -> void:
	var index := list.add_item(CandyLocale.t(str(CandyCountersWidget.STAT_LABELS[id])))
	list.set_item_metadata(index, id)
	list.set_item_tooltip(index, CandyLocale.t(str(CandyCountersWidget.STAT_TOOLTIPS[id])))


#* Add every selected stat, in the Available list's order:
func _on_add_pressed() -> void:
	var indices := CandyListSelection.selected_indices(_available_list)
	if indices.is_empty():
		return
	for index in indices:
		_stats.append(str(_available_list.get_item_metadata(index)))
	_refresh_lists()


func _on_remove_pressed() -> void:
	var indices := CandyListSelection.selected_indices(_shown_list)
	if indices.is_empty():
		return
	indices.reverse()
	for index in indices:
		_stats.remove_at(index)
	_refresh_lists()


func _apply() -> void:
	var changes := {
		"reference": _reference.text.strip_edges(),
		"compare_reference": _compare_reference.text.strip_edges(),
		"stats": _stats.duplicate(),
		"columns": int(_columns.value),
	}
	_min_size.write_config(changes)
	applied.emit(changes)
