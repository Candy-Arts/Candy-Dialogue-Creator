#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyLanguageSettingsPage
extends CandySettingsPage

#? The language is an app setting, the same for every profile, saved at once (not in the draft).

#^ The message shown once a setting of this page changes, in the language chosen:
const RESTART_TITLE := "Language"	#/ translatable
const RESTART_TEXT := "Restart Candy Dialogue Creator for the new language to take effect."	#/ translatable
const RESTART_CHANGE_TEXT := "Restart Candy Dialogue Creator for this change to take effect."	#/ translatable
const RESTART_OK := "OK"	#/ translatable

var _restart_message: AcceptDialog


func build() -> void:
	add_heading(CandyLocale.t("Language"))
	var button := OptionButton.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill_choice(button, CandyLocale.language_choices())
	_select_value(button, CandyLocale.language_setting())
	button.item_selected.connect(func(index: int): _change_language(str(button.get_item_metadata(index))))
	_row(CandyLocale.t("Language"), button,
		CandyLocale.t("The language of Candy Dialogue Creator's menus, panels and settings, for every profile."))
	add_note(CandyLocale.t("The new language shows the next time Candy Dialogue Creator starts."))

	var command_names := CheckBox.new()
	command_names.set_pressed_no_signal(CandyLocale.command_names_setting())
	command_names.toggled.connect(func(pressed: bool):
		CandyLocale.set_command_names_setting(pressed)
		_ask_restart())
	_row(CandyLocale.t("Translate command names"), command_names,
		CandyLocale.t("On: commands show by their names in the language chosen above.\nOff: by their English names (Spoken Line, Media Play), as Candy Dialogue Engine's documentation writes them.\nThe names saved in dialogues (Spoken_Line) are never translated."))

	_restart_message = AcceptDialog.new()
	add_child(_restart_message)


#* Save the language, and ask for a restart:
func _change_language(language: String) -> void:
	CandyLocale.set_language_setting(language)
	_ask_restart()


#* Ask for a restart in the language chosen, while the settings differ from what's shown (texts are translated as they're built):
func _ask_restart() -> void:
	var language := CandyLocale.language_setting()
	var new_language := language != CandyLocale.current_language()
	var new_command_names := CandyLocale.command_names_setting() != CandyLocale.translates_command_names()
	#% Back to what's shown - no restart needed:
	if not new_language and not new_command_names:
		_restart_message.hide()
		return
	_restart_message.title = CandyLocale.t_in(language, RESTART_TITLE)
	if new_language:
		_restart_message.dialog_text = CandyLocale.t_in(language, RESTART_TEXT)
	else:
		_restart_message.dialog_text = CandyLocale.t_in(language, RESTART_CHANGE_TEXT)
	_restart_message.ok_button_text = CandyLocale.t_in(language, RESTART_OK)
	_restart_message.popup_centered()
