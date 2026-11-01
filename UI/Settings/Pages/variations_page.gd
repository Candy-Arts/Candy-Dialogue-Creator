#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationsPage
extends CandySettingsPage

const LIST_HEIGHT := 260

var _data: CandyVariationData
var _combination_list: CandyVariationList
var _random_list: CandyVariationList
var _variation_list: CandyVariationList
var _summary: Label
#^ Languages unfolded in the full list (session only):
var _unfolded: Dictionary = {}


func build() -> void:
	_data = CandyVariationData.new(draft)

	add_note(CandyLocale.t("Built from the languages and tags on the Languages & Tags page."))
	_summary = add_note(" ")

	begin_section(CandyLocale.t("Tag combinations"), "settings_variations_combinations_open", true)
	add_note(CandyLocale.t("Every combination of custom tags, one value per tag key."))
	_combination_list = _add_list()
	end_section()

	begin_section(CandyLocale.t("With random tags"), "settings_variations_randoms_open", true)
	add_note(CandyLocale.t("The combinations above, each with a random tag. Combinations switched off above don't appear."))
	_random_list = _add_list()
	end_section()

	begin_section(CandyLocale.t("All variations"), "settings_variations_all_open", true)
	add_note(CandyLocale.t("Every variation name, per language. Use a language's fold button to show its variations."))
	_variation_list = _add_list()
	end_section()

	_rebuild()


func refresh() -> void:
	super.refresh()
	_rebuild()


func _toggle_disabled(id: String) -> void:
	_data.toggle_disabled(id)
	_rebuild()


func _toggle_fold(language: String) -> void:
	if _unfolded.has(language):
		_unfolded.erase(language)
	else:
		_unfolded[language] = true
	_rebuild()


func _toggle_hidden(language: String) -> void:
	_data.toggle_language_hidden(language)
	_rebuild()


func _rebuild() -> void:
	if _combination_list == null:
		return

	var custom := _data.custom_tags()
	var randoms := _data.random_tags()
	var disabled := _data.disabled()

	#@ Step 1 - Every combination of custom tags:
	var combinations := CandyVariations.combinations(custom)
	var rows: Array = []
	for combination in combinations:
		rows.append(_make_row(combination, combination, 0, disabled.has(combination)))
	_combination_list.set_rows(rows)

	#@ Step 2 - Enabled combinations, each with a random tag:
	var enabled_combinations: Array = []
	for combination in combinations:
		if not disabled.has(combination):
			enabled_combinations.append(combination)
	rows = []
	for variation_name in CandyVariations.with_randoms(enabled_combinations, randoms):
		rows.append(_make_row(variation_name, variation_name, 0, disabled.has(variation_name)))
	_random_list.set_rows(rows)

	#@ Step 3 - Every language, with the remaining tag variations:
	var tag_variations := CandyVariations.ordered_tag_variations(custom, randoms, disabled)
	rows = []
	var total := 0
	for entry in _data.languages():
		var language := str(entry.get("name", ""))
		var is_hidden := bool(entry.get("hidden", false))
		var folded := not _unfolded.has(language)

		var language_row := _make_row(language, language, 0, disabled.has(language))
		language_row["foldable"] = true
		language_row["folded"] = folded
		language_row["hideable"] = language != CandyVariationData.DEFAULT_LANGUAGE
		language_row["hidden"] = is_hidden
		rows.append(language_row)

		if is_hidden:
			continue
		if not disabled.has(language):
			total += 1
		if folded:
			continue
		for tags in tag_variations:
			var variation_name = language + CandyVariations.SEPARATOR + tags
			var is_off = disabled.has(variation_name)
			rows.append(_make_row(variation_name, variation_name, 1, is_off))
			if not is_off:
				total += 1
	_variation_list.set_rows(rows)

	_summary.text = CandyLocale.t("{combinations} combinations, {randoms} with random tags, {variations} variations in use.").format({
		"combinations": combinations.size(), "randoms": _random_list.row_count(), "variations": total})


func _make_row(id: String, text: String, indent: int, disabled: bool) -> Dictionary:
	return {"id": id, "text": text, "indent": indent, "disabled": disabled}


func _add_list() -> CandyVariationList:
	var list := CandyVariationList.new()
	list.theme_type_variation = CandyThemeDefaults.SETTINGS_LIST
	list.custom_minimum_size.y = LIST_HEIGHT
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.show_guides = true
	list.disable_pressed.connect(_toggle_disabled)
	list.fold_pressed.connect(_toggle_fold)
	list.hide_pressed.connect(_toggle_hidden)
	add_list_box(list)
	return list