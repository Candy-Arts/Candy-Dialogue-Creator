#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySpeechViewerSettings
extends CandySpeechEditorSettings

var _bbcode: CheckBox
var _translation: CheckBox


func _init() -> void:
	#? Builds the parent's rows and _root (the parent's _init hasn't run yet).
	super()
	title = CandyLocale.t("Speech Viewer")

	_root.add_child(HSeparator.new())

	_bbcode = CheckBox.new()
	_bbcode.text = CandyLocale.t("Interpret BBCode")
	_bbcode.tooltip_text = CandyLocale.t("Off shows tags such as [b] as plain text.")
	_root.add_child(_bbcode)

	_translation = CheckBox.new()
	_translation.text = CandyLocale.t("Translation")
	_translation.tooltip_text = CandyLocale.t("Only used inside a Variation Editor widget, in Translate mode: on shows the language translated to, off the language translated from.")
	_root.add_child(_translation)


func _load_extra(config: Dictionary) -> void:
	_bbcode.button_pressed = bool(config.get("bbcode", CandySpeechViewerWidget.DEFAULT_BBCODE))
	_translation.button_pressed = bool(config.get("translation", false))


func _extra_config() -> Dictionary:
	return {"bbcode": _bbcode.button_pressed, "translation": _translation.button_pressed}