#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyCountersSettingsPage
extends CandySettingsPage

#^ Each state's [label, tooltip], in CandyCountersWidget.COLOR_STATES' order:
const STATE_LABELS := {
	"words": ["Words", "The number of words."],		#/ translatable
	"chars": ["Chars.", "The number of characters."],		#/ translatable
	"under_limit": ["Under the limit", "Limit, while the text is shorter than the limit minus the margin."],		#/ translatable
	"near_limit": ["Within the margin", "Limit, while the text is within the margin before the limit, or at it."],		#/ translatable
	"over_limit": ["Over the limit", "Limit, once the text is longer than the limit."],		#/ translatable
	"more": ["Reference 1 has more", "C. Diff. and W. Diff., when Reference 1 has more characters or words than Reference 2."],		#/ translatable
	"less": ["Reference 1 has less", "C. Diff. and W. Diff., when Reference 1 has fewer characters or words than Reference 2."],		#/ translatable
	"equal": ["Both the same", "C. Diff. and W. Diff., when Reference 1 has as many characters or words as Reference 2."],		#/ translatable
}

#^ Color pickers by key (COLOR_PREFIX or OUTLINE_PREFIX + state):
var _pickers: Dictionary = {}
var _color_menu: CandyOverrideMenu


func build() -> void:
	add_heading(CandyLocale.t("Limit"))
	add_number(CandyCountersWidget.LIMIT_SETTING, CandyLocale.t("Spoken text limit"), 0, 9999, 1,
		CandyLocale.t("Character count a spoken line is warned about."), "250")
	add_number(CandyCountersWidget.MARGIN_SETTING, CandyLocale.t("Limit margin"), 0, 9999, 1,
		CandyLocale.t("How many characters before the limit the Counters widget's Limit takes the margin color."), "50")
	add_separator()

	add_heading(CandyLocale.t("Colors"))
	add_note(CandyLocale.t("The colors of the Counters widget's numbers, and of their outlines, for the current theme. Each theme has its own. Ctrl+click a color to paste."))
	_color_menu = CandyOverrideMenu.new()
	add_child(_color_menu)
	var grid := GridContainer.new()
	grid.theme_type_variation = CandyThemeDefaults.ROOMY_GRID
	grid.columns = 3
	add_custom(grid)
	grid.add_child(Control.new())
	for title in [CandyLocale.t("Text"), CandyLocale.t("Outline")]:
		var header := Label.new()
		header.text = title
		grid.add_child(header)

	for state in CandyCountersWidget.COLOR_STATES:
		var entry: Array = STATE_LABELS.get(state, [str(state).capitalize(), ""])
		var label := Label.new()
		label.text = CandyLocale.t(str(entry[0]))
		label.custom_minimum_size.x = LABEL_WIDTH
		label.tooltip_text = CandyLocale.t(str(entry[1]))
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(label)
		_color_picker(grid, CandyCountersWidget.COLOR_PREFIX + str(state), CandyLocale.t(str(entry[1])))
		_color_picker(grid, CandyCountersWidget.OUTLINE_PREFIX + str(state), CandyLocale.t(str(entry[1])))


func refresh() -> void:
	super.refresh()
	#? Use Label's color: a variation named here isn't looked up through its base type.
	var theme_color := get_theme_color(&"font_color", &"Label")
	var stored := CandyTheme.overrides_of(draft.get_dictionary(CandyCountersWidget.COLORS_SETTING), _theme_id())
	for key in _pickers:
		var color = CandyCountersWidget.color_of(key, stored)
		if not color is Color:
			color = theme_color
			if key.begins_with(CandyCountersWidget.OUTLINE_PREFIX):
				color = Color(0, 0, 0, 0)
		_pickers[key].color = color


func _theme_id() -> String:
	return str(draft.get_value(CandyTheme.THEME_SETTING, CandyTheme.DEFAULT_THEME))


#* Get a color's draft key: "counter_colors/<theme id>/<key>":
func _setting_key(key: String) -> String:
	return "/".join([CandyCountersWidget.COLORS_SETTING, _theme_id(), key])


func _color_picker(grid: GridContainer, key: String, tooltip: String) -> void:
	var button := ColorPickerButton.new()
	button.custom_minimum_size.x = 120
	button.tooltip_text = tooltip + "\n" + CandyLocale.t("Right-click to copy, paste or remove it. Ctrl+click to paste.")
	button.color_changed.connect(func(color: Color): draft.set_value(_setting_key(key), color))
	_color_menu.add_to_color(button,
		func(color: Color):
			draft.set_value(_setting_key(key), color)
			refresh(),
		func():
			draft.erase_value(_setting_key(key))
			refresh(),
		func() -> bool: return draft.has_value(_setting_key(key)))
	grid.add_child(button)
	_pickers[key] = button
