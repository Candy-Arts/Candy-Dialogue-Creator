#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySaveLoadSettingsPage
extends CandySettingsPage


func build() -> void:
	add_heading(CandyLocale.t("Loading"))
	var load_edit := add_path(CandySaves.LOAD_PATH_SETTING, CandyLocale.t("Folder"),
		CandyLocale.t("File > Load Dialogue... starts here.\nLeave empty for the profile's Saves folder."))
	load_edit.placeholder_text = CandySaves.default_load_folder()
	add_note(CandyLocale.t("A loaded file becomes the file Save writes to only if it is a manual save from the manual saves folder below."))
	add_separator()

	add_heading(CandyLocale.t("Manual saves"))
	_add_folder(CandySaves.KIND_MANUAL, CandyLocale.t("File > Save, Save As... and Save Incremental start here."))
	var method := add_choice("default_save_mode", CandyLocale.t("Save method"), [
		{"label": CandyLocale.t("Normal"), "value": str(CandySaves.MODE_NORMAL)},
		{"label": CandyLocale.t("Incremental"), "value": str(CandySaves.MODE_INCREMENTAL)},
	], CandyLocale.t("Normal: Save overwrites the current save file.\nIncremental: Save writes a new file beside it, stamped with the date and time."),
		str(CandySaves.MODE_NORMAL))
	#? Stored as a number, as 1.1 profiles hold it.
	method.item_selected.connect(func(index: int):
		draft.set_value("default_save_mode", int(str(method.get_item_metadata(index)))))
	add_separator()

	add_heading(CandyLocale.t("Auto saves"))
	_add_folder(CandySaves.KIND_AUTO, "")
	add_number("auto_save_freq", CandyLocale.t("Frequency (seconds)"), CandySaves.MIN_AUTO_SAVE_SECONDS, 86400, 1,
		CandyLocale.t("How often the dialogue is auto saved, when it changed."), str(CandySaves.DEFAULT_AUTO_SAVE_SECONDS))
	add_number("auto_saves_max", CandyLocale.t("Maximum files"), -1, 9999, 1,
		CandyLocale.t("How many auto saves are kept before the oldest is overwritten.\n-1: auto saving is off.\n0: no limit."), "5")
	add_separator()

	add_heading(CandyLocale.t("Quick saves"))
	_add_folder(CandySaves.KIND_QUICK, "")
	add_number("quick_saves_max", CandyLocale.t("Maximum files"), -1, 9999, 1,
		CandyLocale.t("How many quick saves are kept before the oldest is overwritten.\n-1: quick saving is off.\n0: no limit."), "5")
	add_note(CandyLocale.t("Maximum files: -1 turns the save off, 0 keeps every file."))


#* Add a save folder row (empty = the profile's Saves folder, shown as a hint):
func _add_folder(kind: String, tooltip: String) -> void:
	var text := CandyLocale.t("Leave empty for the profile's Saves folder.")
	if tooltip != "":
		text = tooltip + "\n" + text
	var edit := add_path(str(CandySaves.PATH_SETTINGS[kind]), CandyLocale.t("Folder"), text)
	edit.placeholder_text = CandySaves.default_folder(kind)
