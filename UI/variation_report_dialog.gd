#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationReportDialog
extends AcceptDialog

const COPY_ACTION := &"copy"
const ARROW := "→"

var _text: RichTextLabel
#^ The report as the clipboard gets it:
var _plain: PackedStringArray = []
var _rich: PackedStringArray = []
var _error_color := ""
var _warning_color := ""


#* Open the report, if there's anything to report:
#? presets: the file is a preset file, not a dialogue.
static func open_report(repair: CandyVariationRepair, path: String, presets: bool = false) -> void:
	if repair.entries.is_empty():
		return
	var dialog := CandyVariationReportDialog.new()
	var tree := Engine.get_main_loop() as SceneTree
	CandyLocale.claim(dialog)
	tree.root.add_child(dialog)
	dialog._show_report(repair, path, presets)


func _init() -> void:
	#? Own theme - it opens under the root, outside Candy DC's windows.
	theme = CandyTheme.theme
	title = CandyLocale.t("Broken Variation Names")
	ok_button_text = CandyLocale.t("Close")
	#? Over the front window (e.g. the Import dialog), not only the main one.
	transient_to_focused = true
	min_size = Vector2i(720, 480)
	add_button(CandyLocale.t("Copy"), false, COPY_ACTION)
	custom_action.connect(_on_custom_action)
	confirmed.connect(queue_free)
	canceled.connect(queue_free)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.selection_enabled = true
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_text)


func _show_report(repair: CandyVariationRepair, path: String, presets: bool) -> void:
	_error_color = get_theme_color(&"font_color", CandyThemeDefaults.ERROR).to_html(false)
	_warning_color = get_theme_color(&"font_color", CandyThemeDefaults.WARNING).to_html(false)

	var broken: Array = []
	var fixable: Array = []
	for entry in repair.entries:
		if not entry["problems"].is_empty():
			broken.append(entry)
		if not entry["fixes"].is_empty():
			fixable.append(entry)

	if repair.has_problems():
		_write_refused(broken, fixable, path, presets)
	else:
		_write_loaded(fixable, path, presets)
	_text.text = "\n".join(_rich)
	popup_centered()


#& Report

func _write_refused(broken: Array, fixable: Array, path: String, presets: bool) -> void:
	if presets:
		var heading := CandyLocale.t("These presets weren't loaded.")
		_line("[b]%s[/b]" % heading, heading)
		_paragraph(CandyLocale.t("Some of their variation names have problems Candy Dialogue Creator can't solve. They must be edited by hand in the file, then the profile opened again. Until then, the file won't be overwritten."))
	else:
		var heading := CandyLocale.t("The dialogue wasn't loaded.")
		_line("[b]%s[/b]" % heading, heading)
		_paragraph(CandyLocale.t("Some of its variation names have problems Candy Dialogue Creator can't solve. They must be edited by hand in the file, then the dialogue loaded again."))
	_path(path)

	_heading(CandyLocale.t("Must be edited by hand (%d)") % broken.size(), _error_color)
	_paragraph(CandyLocale.t("Candy Dialogue Creator can't solve these problems."))
	_entries(broken, "problems", _error_color)

	if not fixable.is_empty():
		_heading(CandyLocale.t("Can be fixed automatically (%d)") % fixable.size(), _warning_color)
		_paragraph(CandyLocale.t("Candy Dialogue Creator fixes these itself when the file loads, once the problems above are solved."))
		_entries(fixable, "fixes", _warning_color)


func _write_loaded(fixable: Array, path: String, presets: bool) -> void:
	var heading := CandyLocale.t("Broken variation names were fixed.")
	_line("[b]%s[/b]" % heading, heading)
	if presets:
		_paragraph(CandyLocale.t("The presets loaded with the fixes below. Their file is corrected the next time presets are saved."))
	else:
		_paragraph(CandyLocale.t("The dialogue loaded with the fixes below. The file itself is only corrected when you save or export the dialogue."))
	_path(path)

	_heading(CandyLocale.t("Fixed (%d)") % fixable.size(), _warning_color)
	_entries(fixable, "fixes", _warning_color)


#* Write entries grouped by place, each variation with its problems or fixes:
#? kind: "problems" or "fixes".
func _entries(list: Array, kind: String, color: String) -> void:
	var last_where := ""
	for entry in list:
		var where := str(entry["where"])
		if where != last_where:
			_line("", "")
			_line("[b]%s[/b]" % _escape(where), where)
			last_where = where

		var variation := str(entry["variation"])
		var fixed := str(entry["fixed"])
		var word := CandyLocale.t("Variation")
		if kind == "fixes" and fixed != variation:
			_line("[indent]%s [b]%s[/b]  %s  [b]%s[/b][/indent]" % [word, _escape(variation), ARROW, _escape(fixed)],
				"    %s %s  %s  %s" % [word, variation, ARROW, fixed])
		else:
			_line("[indent]%s [b]%s[/b][/indent]" % [word, _escape(variation)], "    %s %s" % [word, variation])

		for item in entry[kind]:
			var text := ""
			if item is Dictionary:
				text = "%s  %s  %s" % [item["problem"], ARROW, item["fix"]]
			else:
				text = str(item)
			_line("[indent][indent][color=#%s]• %s[/color][/indent][/indent]" % [color, _escape(text)],
				"        • %s" % text)


func _heading(text: String, color: String) -> void:
	_line("", "")
	_line("[color=#%s][b]%s[/b][/color]" % [color, _escape(text)], text.to_upper())


func _paragraph(text: String) -> void:
	_line(_escape(text), text)


#* Write the file's disk path (not user://):
func _path(path: String) -> void:
	if path == "":
		return
	var shown := ProjectSettings.globalize_path(path)
	_line("[i]%s[/i]" % _escape(shown), shown)


func _line(rich: String, plain: String) -> void:
	_rich.append(rich)
	_plain.append(plain)


#* Escape "[" in names from files:
func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


func _on_custom_action(action: StringName) -> void:
	if action == COPY_ACTION:
		DisplayServer.clipboard_set("\n".join(_plain))
