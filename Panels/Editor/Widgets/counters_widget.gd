#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyCountersWidget
extends CandyAreaWidget

const VARIATIONS_FIELD := "Variations"
const TEXT_FIELD := "Text"
const DEFAULT_COMPARE_REFERENCE := "2"
const DEFAULT_COLUMNS := 3

#^ Every stat, in the default order:
const STATS: Array = ["words", "chars", "limit", "char_diff", "word_diff"]
const STAT_LABELS := {
	"words": "Words",  #/ translatable
	"chars": "Chars.",  #/ translatable
	"limit": "Limit",  #/ translatable
	"char_diff": "C. Diff.",  #/ translatable
	"word_diff": "W. Diff.",  #/ translatable
}
const STAT_TOOLTIPS := {
	"words": "Words in the variation of Reference 1.",  #/ translatable
	"chars": "Characters in the variation of Reference 1, without BBCode tags.",  #/ translatable
	"limit": "Characters of Reference 1 against the Spoken Text Limit (Settings > General > Counters).\n-100: 100 characters below the limit. +20: 20 characters over it.",  #/ translatable
	"char_diff": "Characters of Reference 1 minus those of Reference 2.\n+: Reference 1 has more. -: it has less.",  #/ translatable
	"word_diff": "Words of Reference 1 minus those of Reference 2.\n+: Reference 1 has more. -: it has less.",  #/ translatable
}

#& Settings > General > Counters

const LIMIT_SETTING := "spoken_text_limit"
const MARGIN_SETTING := "limit_margin"
#^ The states a number is shown in, each with its own colors:
const COLOR_STATES: Array = ["words", "chars", "under_limit", "near_limit", "over_limit",
	"more", "less", "equal"]
#^ + state - its text color ("counter_color_under_limit"):
const COLOR_PREFIX := "counter_color_"
#^ + state - its outline color ("counter_color_outline_under_limit"):
const OUTLINE_PREFIX := "counter_color_outline_"
#^ The colors the user set, per theme (see the header):
const COLORS_SETTING := "counter_colors"
#^ A theme's starting colors, by setting key:
const DEFAULT_COLORS := {
	"counter_color_under_limit": Color(0, 1, 0, 1),
	"counter_color_near_limit": Color(1, 1, 0, 1),
	"counter_color_over_limit": Color(1, 0, 0, 1),
	"counter_color_more": Color(1, 1, 1, 1),
	"counter_color_less": Color(1, 1, 1, 1),
}

var _grid: GridContainer
var _values: Dictionary = {}       #/ stat id -> value Label
#^ Parses BBCode for the counts. Never added to the tree:
var _parser: RichTextLabel
var _word_regex: RegEx
var _settings: CandyCountersSettings
var _line_path: Array = []
#^ Typed but not yet written - variation name -> text:
var _typed: Dictionary = {}


#* Needs the line's Variations:
func fits_line_type(_config: Dictionary, line_type: String) -> bool:
	return has_top_field(line_type, VARIATIONS_FIELD)


#* Group references for the Variation Editor:
func variation_group_config(p_config: Dictionary, refs: Dictionary, mode: String) -> Variant:
	var result := p_config.duplicate(true)
	#¦ 1. TTS - twin vs variation:
	if mode == CandyVariationEditorWidget.MODE_TTS:
		result["reference"] = refs["tts"]
		result["compare_reference"] = refs["variation"]
	#¦ 2. Translate - translation vs source:
	elif mode == CandyVariationEditorWidget.MODE_TRANSLATE:
		result["reference"] = refs["variation"]
		result["compare_reference"] = refs["source"]
	#¦ 3. Random - the Group's variation vs the base:
	else:
		result["reference"] = refs["variation"]
		result["compare_reference"] = refs["base"]
	return result


func _on_configured() -> void:
	_parser = RichTextLabel.new()
	_parser.bbcode_enabled = true
	_word_regex = RegEx.new()
	_word_regex.compile("\\S+")

	_grid = GridContainer.new()
	_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_grid)
	_build_stats()

	var shared := selection()
	if shared != null:
		shared.changed.connect(_on_selection_changed)
		shared.text_typed.connect(_on_text_typed)
	CandyProfiles.settings_changed.connect(_on_setting_changed)


func bind_line(line_path: Array) -> void:
	_line_path = line_path.duplicate()
	#? Whatever was typed is written before the line changes.
	_typed.clear()
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _parser != null:
		_parser.free()
	elif what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_refresh()


#* Minimum size - the stats' height, so the area can't be made smaller than them:
func _get_minimum_size() -> Vector2:
	if _grid == null:
		return Vector2.ZERO
	return _grid.get_combined_minimum_size()


#& Config

#* Ref 2 - the Variation Selector the counted variation is compared with:
func compare_reference() -> String:
	var value := str(config.get("compare_reference", DEFAULT_COMPARE_REFERENCE)).strip_edges()
	if value == "":
		return DEFAULT_COMPARE_REFERENCE
	return value


#* The ids of the stats shown, in order (unknown ids skipped):
static func stats_of(widget_config: Dictionary) -> Array:
	var stored = widget_config.get("stats", STATS)
	var result: Array = []
	if not stored is Array:
		return STATS.duplicate()
	for id in stored:
		if STATS.has(str(id)) and not result.has(str(id)):
			result.append(str(id))
	return result


static func columns_of(widget_config: Dictionary) -> int:
	return maxi(1, int(widget_config.get("columns", DEFAULT_COLUMNS)))

#& Building

func _build_stats() -> void:
	for child in _grid.get_children():
		child.free()
	_values.clear()
	_grid.columns = columns_of(config)

	for id in stats_of(config):
		var cell := HBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.tooltip_text = CandyLocale.t(str(STAT_TOOLTIPS[id]))
		cell.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
		_grid.add_child(cell)

		var title := Label.new()
		title.text = CandyLocale.t(str(STAT_LABELS[id]))
		cell.add_child(title)

		var value := Label.new()
		value.theme_type_variation = CandyThemeDefaults.COUNTER
		cell.add_child(value)
		_values[id] = value
	update_minimum_size()


#& Counting

func _refresh() -> void:
	if _grid == null:
		return
	for id in _values:
		var label: Label = _values[id]
		label.text = ""
		label.remove_theme_color_override("font_color")
		label.remove_theme_color_override("font_outline_color")

	var variations = _variations()
	if not variations is Array:
		return

	var parsed_1 := _parsed(_text_of(variations, _variation_of(reference())))
	var chars_1 := _count_characters(parsed_1)
	var words_1 := _count_words(parsed_1)
	var chars_2 := 0
	var words_2 := 0
	if _values.has("char_diff") or _values.has("word_diff"):
		var parsed_2 := _parsed(_text_of(variations, _variation_of(compare_reference())))
		chars_2 = _count_characters(parsed_2)
		words_2 = _count_words(parsed_2)

	if _values.has("words"):
		_values["words"].text = str(words_1)
		_paint(_values["words"], "words")
	if _values.has("chars"):
		_values["chars"].text = str(chars_1)
		_paint(_values["chars"], "chars")
	if _values.has("limit"):
		_show_limit(_values["limit"], chars_1)
	if _values.has("char_diff"):
		_show_difference(_values["char_diff"], chars_1 - chars_2)
	if _values.has("word_diff"):
		_show_difference(_values["word_diff"], words_1 - words_2)


func _show_limit(label: Label, chars: int) -> void:
	var limit := int(str(CandyProfiles.get_setting(LIMIT_SETTING, "250")))
	var margin := int(str(CandyProfiles.get_setting(MARGIN_SETTING, "50")))
	label.text = _signed(chars - limit)
	var state := "under_limit"
	if chars > limit:
		state = "over_limit"
	elif chars > limit - margin:
		state = "near_limit"
	_paint(label, state)


func _show_difference(label: Label, difference: int) -> void:
	label.text = _signed(difference)
	if difference > 0:
		_paint(label, "more")
	elif difference < 0:
		_paint(label, "less")
	else:
		_paint(label, "equal")


#* "+12", "-12", "0":
func _signed(number: int) -> String:
	if number > 0:
		return "+%d" % number
	return str(number)


#* The text as a player reads it (no markers, no lexicon escapes, no BBCode):
func _parsed(text: String) -> String:
	text = CandyTextEventMarkers.strip(text)
	text = _strip_lexicon_escapes(text)
	if text == "":
		return ""
	_parser.text = text
	return _parser.get_parsed_text()


#* Lexicon escape symbols removed, a doubled one kept once ("¬Alice¬" → "Alice", "¬¬" → "¬"):
func _strip_lexicon_escapes(text: String) -> String:
	var stored = CandyProfiles.get_setting("symbols", {})
	if not stored is Dictionary:
		return text
	var symbols: PackedStringArray = []
	for key in ["lexicon_escape_start", "lexicon_escape_end"]:
		var symbol := str(stored.get(key, ""))
		if symbol != "" and not symbol in symbols:
			symbols.append(symbol)
	if symbols.is_empty():
		return text
	var result := ""
	var i := 0
	while i < text.length():
		var matched := ""
		for symbol in symbols:
			if text.substr(i, symbol.length()) == symbol:
				matched = symbol
		if matched == "":
			result += text[i]
			i += 1
		elif text.substr(i + matched.length(), matched.length()) == matched:
			result += matched		#/ Doubled: displayed once
			i += matched.length() * 2
		else:
			i += matched.length()	#/ An escape: not displayed
	return result


func _count_characters(parsed: String) -> int:
	return parsed.replace("\r", "").replace("\n", "").length()


func _count_words(parsed: String) -> int:
	return _word_regex.search_all(parsed).size()


#* Give a number its state's text and outline colors:
func _paint(label: Label, state: String) -> void:
	var stored := CandyTheme.overrides_of(CandyProfiles.get_setting(COLORS_SETTING, {}), CandyTheme.current_theme_id())
	var text_color = color_of(COLOR_PREFIX + state, stored)
	if text_color is Color:
		label.add_theme_color_override("font_color", text_color)
	label.add_theme_color_override("font_outline_color", CandySpeechEditorSettings.to_color(
		color_of(OUTLINE_PREFIX + state, stored), Color(0, 0, 0, 0)))


#* A color setting (COLOR_PREFIX or OUTLINE_PREFIX + state), or null:
#? stored: the user's colors for the current theme.
static func color_of(key: String, stored: Dictionary) -> Variant:
	if CandySpeechEditorSettings.has_color(stored.get(key)):
		return CandySpeechEditorSettings.to_color(stored[key], Color.WHITE)
	#Ł Else the theme's, else DEFAULT_COLORS:
	var theme_key := key.trim_prefix(COLOR_PREFIX)
	if key.begins_with(OUTLINE_PREFIX):
		theme_key = "outline_" + key.trim_prefix(OUTLINE_PREFIX)
	var from_theme = CandyTheme.counter_colors().get(theme_key)
	if from_theme is Color:
		return from_theme
	if DEFAULT_COLORS.has(key):
		return DEFAULT_COLORS[key]
	return null


#& Data

func _variation_of(variation_reference: String) -> String:
	var shared := selection()
	if shared == null:
		return CandyVariationSelection.DEFAULT_VARIATION
	return shared.get_selected(variation_reference)


#* The line's Variations array, or null:
func _variations() -> Variant:
	if not CandyDialogue.is_line_path(_line_path):
		return null
	return CandyDialogue.get_field(_line_path, [VARIATIONS_FIELD], null)


#* What is being typed into the variation, else its text in the dialogue:
func _text_of(variations: Array, variation: String) -> String:
	if _typed.has(variation):
		return str(_typed[variation])
	for entry in variations:
		if entry is Dictionary and entry.size() > 0 and str(entry.keys()[0]) == variation:
			var value = entry[entry.keys()[0]]
			if value is Dictionary:
				return str(value.get(TEXT_FIELD, ""))
	return ""


#& Input

func _on_selection_changed(changed_reference: String, _variation_name: String) -> void:
	if changed_reference == reference() or changed_reference == compare_reference():
		_refresh()


func _on_text_typed(variation_name: String, text: String) -> void:
	_typed[variation_name] = text
	if variation_name == _variation_of(reference()) or variation_name == _variation_of(compare_reference()):
		_refresh()


func _on_setting_changed(key: String) -> void:
	if key == LIMIT_SETTING or key == MARGIN_SETTING or key == COLORS_SETTING:
		_refresh()


func has_settings() -> bool:
	return true


func open_settings() -> void:
	if _settings == null:
		_settings = CandyCountersSettings.new()
		_settings.applied.connect(_on_settings_applied)
		add_child(_settings)
	_settings.open(config)


func _on_settings_applied(new_config: Dictionary) -> void:
	var merged := config.duplicate(true)
	for key in new_config:
		merged[key] = new_config[key]
	save_config(merged)
	#? Saving usually rebuilds this widget; not in every context.
	_build_stats()
	_refresh()
