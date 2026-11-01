#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyThemeOptionsPage
extends CandySettingsPage

const OVERRIDE_TOOLTIP := "Override: use this value instead of the theme's."		#/ translatable

var page_name := ""
var _option_rows: Array = []     #/ One per option shown: { id, option, check, control }


static func for_page(p_page_name: String) -> CandyThemeOptionsPage:
	var page := CandyThemeOptionsPage.new()
	page.page_name = p_page_name
	return page


#* Preview the draft's theme and overrides, without saving:
static func preview_draft(p_draft: CandySettingsDraft) -> void:
	var theme_id := str(p_draft.get_value(CandyTheme.THEME_SETTING, CandyTheme.DEFAULT_THEME))
	CandyTheme.preview(theme_id, CandyTheme.overrides_of(p_draft.get_dictionary(CandyTheme.OVERRIDES_SETTING), theme_id))


func build() -> void:
	add_note(CandyLocale.t("Tick the box before a value to change this setting of the chosen theme, or change the value. Untick it to go back to the theme's own value."))
	var sections := _sections()
	for index in sections.size():
		if index > 0:
			add_separator()
		_add_section(sections[index])


func refresh() -> void:
	super.refresh()
	var theme_id := str(draft.get_value(CandyTheme.THEME_SETTING, CandyTheme.DEFAULT_THEME))
	var overrides := CandyTheme.overrides_of(draft.get_dictionary(CandyTheme.OVERRIDES_SETTING), theme_id)
	for row in _option_rows:
		var id: String = row["id"]
		var overridden := overrides.has(id)
		row["check"].set_pressed_no_signal(overridden)
		var value = null
		if overridden:
			value = CandyTheme.coerce(row["option"], overrides[id])
		if value == null:
			value = CandyTheme.theme_value(theme_id, id)
		_show_value(row, value)


#& Layout

#* Sort the page's options into sections, in file order:
func _sections() -> Array:
	var sections: Array = []
	var row_of: Dictionary = {}    #/ Option id -> [ section index, row ]
	for option in CandyTheme.options():
		if str(option.get("page", "Other")) != page_name:
			continue
		var title := str(option.get("section", ""))
		if sections.is_empty() or sections.back()["title"] != title:
			sections.append({"title": title, "columns": [], "rows": []})
		var section: Dictionary = sections.back()
		var column := str(option.get("column", ""))
		if not section["columns"].has(column):
			section["columns"].append(column)
		#Ł Join the asked row, if in this section and free:
		var row: Dictionary = {}
		var asked: Array = row_of.get(str(option.get("row", "")), [])
		if not asked.is_empty() and asked[0] == sections.size() - 1 and not asked[1]["cells"].has(column):
			row = asked[1]
		else:
			row = {"first": option, "cells": {}}
			section["rows"].append(row)
		row["cells"][column] = option
		row_of[str(option["id"])] = [sections.size() - 1, row]
	return sections			#/ [ { title, columns: [ names ], rows: [ { first: option, cells: { column: option } } ] } ]


func _add_section(section: Dictionary) -> void:
	if section["title"] != "":
		add_heading(CandyLocale.t(str(section["title"])))
	var columns: Array = section["columns"]
	var grid := GridContainer.new()
	grid.theme_type_variation = CandyThemeDefaults.ROOMY_GRID
	grid.columns = 1 + columns.size()
	add_custom(grid)

	if columns != [""]:
		grid.add_child(Control.new())
		for column in columns:
			var header := Label.new()
			header.text = CandyLocale.t(str(column))
			grid.add_child(header)

	for row in section["rows"]:
		var first: Dictionary = row["first"]
		var label := Label.new()
		label.text = CandyLocale.t(str(first.get("label", first["id"])))
		label.custom_minimum_size.x = LABEL_WIDTH
		label.tooltip_text = CandyLocale.t(str(first.get("tooltip", "")))
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(label)
		for column in columns:
			var cell: Control = null
			if row["cells"].has(column):
				cell = _option_cell(row["cells"][column])
			if cell == null:
				cell = Control.new()
			grid.add_child(cell)


#* Make an option's cell (override box and value), or null for an unknown type:
func _option_cell(option: Dictionary) -> Control:
	var cell := HBoxContainer.new()
	var tooltip := CandyLocale.t(str(option.get("tooltip", "")))

	var check := CheckBox.new()
	check.tooltip_text = CandyLocale.t(OVERRIDE_TOOLTIP)
	check.focus_mode = Control.FOCUS_NONE
	cell.add_child(check)

	var row := {"id": str(option["id"]), "option": option, "check": check}
	match str(option.get("type", "")):
		"color":
			var picker := ColorPickerButton.new()
			picker.custom_minimum_size.x = 120
			picker.edit_alpha = true
			picker.tooltip_text = tooltip
			picker.color_changed.connect(func(color: Color): _on_value_changed(row, color))
			row["control"] = picker
		"number":
			var spin := SpinBox.new()
			spin.min_value = float(option.get("min", 0))
			spin.max_value = float(option.get("max", 100))
			spin.step = float(option.get("step", 1))
			spin.tooltip_text = tooltip
			spin.value_changed.connect(func(value: float): _on_value_changed(row, _number(value, spin.step)))
			row["control"] = spin
		"font":
			var picker := CandyFontPicker.new()
			picker.custom_minimum_size.x = 260
			picker.set_tooltip(tooltip)
			picker.font_changed.connect(func(file_name: String): _on_value_changed(row, file_name))
			row["control"] = picker
		_:
			push_warning("CandyThemeOptionsPage: option '%s' has an unknown type" % row["id"])
			cell.free()
			return null
	cell.add_child(row["control"])
	check.toggled.connect(func(pressed: bool): _on_override_toggled(row, pressed))
	_option_rows.append(row)
	return cell


func _key(row: Dictionary) -> String:
	var theme_id := str(draft.get_value(CandyTheme.THEME_SETTING, CandyTheme.DEFAULT_THEME))
	return "%s/%s/%s" % [CandyTheme.OVERRIDES_SETTING, theme_id, row["id"]]


func _on_value_changed(row: Dictionary, value: Variant) -> void:
	draft.set_value(_key(row), value)
	row["check"].set_pressed_no_signal(true)
	preview_draft(draft)


func _on_override_toggled(row: Dictionary, pressed: bool) -> void:
	if pressed:
		draft.set_value(_key(row), _current_value(row))
	else:
		draft.erase_value(_key(row))
		var theme_id := str(draft.get_value(CandyTheme.THEME_SETTING, CandyTheme.DEFAULT_THEME))
		_show_value(row, CandyTheme.theme_value(theme_id, row["id"]))
	preview_draft(draft)


func _current_value(row: Dictionary) -> Variant:
	var control: Control = row["control"]
	if control is ColorPickerButton:
		return control.color
	if control is SpinBox:
		return _number(control.value, control.step)
	if control is CandyFontPicker:
		return control.get_font()
	return null


func _show_value(row: Dictionary, value: Variant) -> void:
	var control: Control = row["control"]
	if control is ColorPickerButton and value is Color:
		control.color = value
	elif control is SpinBox and (value is int or value is float):
		control.set_value_no_signal(float(value))
	elif control is CandyFontPicker and value is String:
		control.set_font(value)
