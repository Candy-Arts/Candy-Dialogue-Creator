#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationSelectorSettings
extends AcceptDialog

signal applied(config: Dictionary)

#^ Content column width:
#? Wrapping labels need an explicit width, or the dialog opens too tall.
const CONTENT_WIDTH := 428

var _reference: LineEdit
var _show_header: CheckBox
var _hide_randoms: CheckBox
var _hide_tts: CheckBox
var _hidden_tags: LineEdit
var _available: Label
var _min_size: CandyMinSizeFields


func _init() -> void:
	title = CandyLocale.t("Variation Selector")
	ok_button_text = CandyLocale.t("Close")
	min_size = Vector2i(460, 0)

	var root := VBoxContainer.new()
	root.custom_minimum_size.x = CONTENT_WIDTH
	add_child(root)

	var reference_row := HBoxContainer.new()
	root.add_child(reference_row)
	var reference_label := Label.new()
	reference_label.text = CandyLocale.t("Reference")
	reference_label.custom_minimum_size.x = 100
	reference_label.tooltip_text = CandyLocale.t("Widgets sharing a reference show the same variation.")
	reference_row.add_child(reference_label)
	_reference = LineEdit.new()
	_reference.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reference_row.add_child(_reference)

	_show_header = CheckBox.new()
	_show_header.text = CandyLocale.t("Show the title and settings button")
	_show_header.tooltip_text = CandyLocale.t("\"Variations\" and the ... button above the list. Off leaves more room for the list; the settings are then in the widget's right-click menu.")
	root.add_child(_show_header)

	root.add_child(HSeparator.new())

	var filter_label := Label.new()
	filter_label.text = CandyLocale.t("Hide variations with these tags")
	root.add_child(filter_label)

	_hidden_tags = LineEdit.new()
	_hidden_tags.placeholder_text = "S=M, Shout"
	_hidden_tags.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_hidden_tags)

	var note := Label.new()
	note.text = CandyLocale.t("Comma separated. A tag without \"=\" hides every value of it: \"S\" hides S=F and S=M.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size.x = CONTENT_WIDTH
	note.theme_type_variation = CandyThemeDefaults.NOTE
	root.add_child(note)

	_available = Label.new()
	_available.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_available.custom_minimum_size.x = CONTENT_WIDTH
	_available.theme_type_variation = CandyThemeDefaults.NOTE
	root.add_child(_available)

	_hide_randoms = CheckBox.new()
	_hide_randoms.text = CandyLocale.t("Hide variations with a random tag")
	root.add_child(_hide_randoms)

	_hide_tts = CheckBox.new()
	_hide_tts.text = CandyLocale.t("Hide TTS variations")
	_hide_tts.tooltip_text = CandyLocale.t("The texts passed to Text To Speech, listed under each variation.")
	root.add_child(_hide_tts)

	_min_size = CandyMinSizeFields.new()
	root.add_child(_min_size)

	confirmed.connect(_apply)
	canceled.connect(_apply)


func open(config: Dictionary, custom_tags: Array) -> void:
	_reference.text = str(config.get("reference", CandyVariationSelection.DEFAULT_REFERENCE))
	_show_header.button_pressed = CandyVariantFile.to_bool(config.get("show_header", true), true)
	_hide_randoms.button_pressed = bool(config.get("hide_randoms", false))
	_hide_tts.button_pressed = bool(config.get("hide_tts", false))

	var hidden_list = config.get("hidden_tags", [])
	if hidden_list is Array:
		_hidden_tags.text = ", ".join(PackedStringArray(hidden_list))
	else:
		_hidden_tags.text = ""

	if custom_tags.is_empty():
		_available.text = CandyLocale.t("No custom tags yet.")
	else:
		_available.text = CandyLocale.t("In use: %s") % ", ".join(PackedStringArray(custom_tags))
	_min_size.load_config(config)

	#Ł The dialog is reused - drop the previous size (the "In use" list may be shorter):
	reset_size()
	popup_centered()


func _apply() -> void:
	var changes := {
		"reference": _reference.text.strip_edges(),
		"show_header": _show_header.button_pressed,
		"hide_randoms": _hide_randoms.button_pressed,
		"hide_tts": _hide_tts.button_pressed,
		"hidden_tags": parse_tags(_hidden_tags.text),
	}
	_min_size.write_config(changes)
	applied.emit(changes)


#* "S=M, Shout" -> ["S=M", "Shout"]:
static func parse_tags(text: String) -> Array:
	var result: Array = []
	for item in text.split(",", false):
		var trimmed := item.strip_edges()
		if trimmed != "" and not result.has(trimmed):
			result.append(trimmed)
	return result