#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyConverterReportDialog
extends AcceptDialog

const COPY_ACTION := &"copy"

var _text: RichTextLabel
var _plain: PackedStringArray = []
var _rich: PackedStringArray = []
var _error_color := ""
var _warning_color := ""
#^ The script whose run it reports (CandyFileConverter, CandySymbolUpdater): its report_lines(),
#^ outcome_text(), report_title(), report_intro() and summary_words():
var _source: GDScript


#* Open the report of a run (source: the script that ran it, CandyFileConverter by default):
static func open_report(results: Array, source: GDScript = null) -> void:
	var dialog := CandyConverterReportDialog.new()
	if source == null:
		source = CandyFileConverter
	dialog._source = source
	var tree := Engine.get_main_loop() as SceneTree
	CandyLocale.claim(dialog)
	tree.root.add_child(dialog)
	dialog._show_report(results)


func _init() -> void:
	#? Own theme - it opens under the root, outside Candy DC's windows.
	theme = CandyTheme.theme
	ok_button_text = CandyLocale.t("Close")
	transient_to_focused = true
	min_size = Vector2i(820, 560)
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


func _show_report(results: Array) -> void:
	_error_color = get_theme_color(&"font_color", CandyThemeDefaults.ERROR).to_html(false)
	_warning_color = get_theme_color(&"font_color", CandyThemeDefaults.WARNING).to_html(false)
	title = _source.report_title()
	_plain = _source.report_lines(results)

	var counts := {}
	for result in results:
		var outcome := str(result["outcome"])
		counts[outcome] = int(counts.get(outcome, 0)) + 1
	_rich.append("[b]%s[/b]" % _summary(counts))
	_rich.append(_escape(_source.report_intro()))

	for result in results:
		_file(result)
	_text.text = "\n".join(_rich)
	popup_centered()


func _summary(counts: Dictionary) -> String:
	var words: Dictionary = _source.summary_words()
	var parts := PackedStringArray()
	parts.append("%s: %d" % [words[CandyFileConverter.OUTCOME_CONVERTED], int(counts.get(CandyFileConverter.OUTCOME_CONVERTED, 0))])
	for outcome in [CandyFileConverter.OUTCOME_SKIPPED, CandyFileConverter.OUTCOME_FAILED]:
		if counts.has(outcome):
			parts.append("%s: %d" % [words[outcome], int(counts[outcome])])
	return ".  ".join(parts) + "."


func _file(result: Dictionary) -> void:
	_rich.append("")
	_rich.append("[b]%s[/b]" % _escape(ProjectSettings.globalize_path(str(result["path"]))))
	var outcome := _escape(_source.outcome_text(result))
	if str(result["outcome"]) == CandyFileConverter.OUTCOME_FAILED:
		outcome = "[color=#%s]%s[/color]" % [_error_color, outcome]
	_rich.append("[indent]%s[/indent]" % outcome)
	if str(result.get("backup", "")) != "":
		_rich.append("[indent][i]%s[/i][/indent]" % (CandyLocale.t("Backup: %s") % _escape(ProjectSettings.globalize_path(str(result["backup"])))))

	for group in CandyFileConverter.grouped_notes(result):
		var text := _escape(str(group["text"]))
		if str(group["level"]) == CandyDialogueConverter.LEVEL_CHECK:
			text = "[color=#%s]%s[/color]" % [_warning_color, CandyLocale.t("Check: %s") % text]
		else:
			text = CandyLocale.t("Note: %s") % text
		_rich.append("[indent]%s[/indent]" % text)
		for where in group["wheres"]:
			_rich.append("[indent][indent][indent]%s[/indent][/indent][/indent]" % _escape(str(where)))


#* Escape "[" in names and text from files:
func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


func _on_custom_action(action: StringName) -> void:
	if action == COPY_ACTION:
		DisplayServer.clipboard_set("\n".join(_plain))
