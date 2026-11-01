#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyProjectDataPage
extends CandySettingsPage

const ROOT_KEY := "project_path"
const SCRIPTS_KEY := "project_scripts"
#^ Plain Array - PackedStringArray(...) isn't a constant expression:
const GD_FILTER := ["*.gd ; GDScript"]

#^ Each kind's [display name, stored key], in display order:
const KINDS := [
	["Actors", "Actors"],		#/ translatable
	["Roles", "Roles"],		#/ translatable
	["Flags", "Flags"],		#/ translatable
	["Dispositions", "Dispositions"],		#/ translatable
	["Effect players",		#/ translatable
		"Effect_Players"],
	["CS paths",		#/ translatable
		"CS_Paths"],
]

#^ Speech Inserts tables' [display name, key under speech_insert_scripts]:
const INSERT_TABLES := [
	["Lexicon", "Lexicon"],		#/ translatable
	["Text events",		#/ translatable
		"Text_Events"],
]

var _status: Label


func build() -> void:
	add_heading(CandyLocale.t("Project data"))
	var note := Label.new()
	note.text = CandyLocale.t("Read from your project's .gd files. Dictionaries contribute their top-level keys, arrays every element, a plain string itself.")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.theme_type_variation = CandyThemeDefaults.NOTE
	add_child(note)

	add_button("", CandyLocale.t("Update all"), _update_all, CandyLocale.t("Re-read every kind from its script."))
	_status = Label.new()
	_status.theme_type_variation = CandyThemeDefaults.NOTE
	_status.text = " "
	add_child(_status)

	for kind in KINDS:
		_build_kind(str(kind[0]), str(kind[1]))

	_build_insert_tables()


#* Build the Speech inserts section:
func _build_insert_tables() -> void:
	add_separator()
	add_heading(CandyLocale.t("Speech inserts"))
	var note := Label.new()
	note.text = CandyLocale.t("The Lexicon keywords and text events the Speech Inserts widget lists, read from your project each time it's scanned (Refresh, in the top bar).")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.theme_type_variation = CandyThemeDefaults.NOTE
	add_child(note)
	#? No Update button - read on every project scan (CandyResources.speech_insert_tables).
	for table in INSERT_TABLES:
		var title := CandyLocale.t(str(table[0]))
		var key := str(table[1])
		add_file(_insert_key(key, "Script"), CandyLocale.t("%s script") % title, CandyLocale.t("The .gd file holding the %s.") % title.to_lower(),
			ROOT_KEY, PackedStringArray(GD_FILTER))
		add_text(_insert_key(key, "Variable"), CandyLocale.t("%s variable") % title, CandyLocale.t("Name of its dictionary, sorted by variation."))


func _build_kind(title: String, key: String) -> void:
	add_separator()
	add_heading(CandyLocale.t(title))

	add_file(_key(key, "Script"), CandyLocale.t("Script"), CandyLocale.t("The .gd file holding this data."), ROOT_KEY,
		PackedStringArray(GD_FILTER))
	var variable := add_text(_key(key, "Variable"), CandyLocale.t("Variable"), CandyLocale.t("Name of the variable, array or dictionary to read."))
	#Ł Update button on the Variable's row:
	#? Clicking it doesn't take the field's focus, so it reads the field's text first.
	var update := Button.new()
	update.text = CandyLocale.t("Update")
	update.tooltip_text = CandyLocale.t("Re-read %s from the script.") % CandyLocale.t(title).to_lower()
	update.focus_mode = Control.FOCUS_NONE
	update.pressed.connect(func():
		draft.set_value(_key(key, "Variable"), variable.text)
		_update_kind(key))
	variable.get_parent().add_child(update)

	add_display(_key(key, "Loaded"), CandyLocale.t("Loaded"), CandyLocale.t("What the last update found in the script."))

	var exclude := add_text(_key(key, "Exclude"), CandyLocale.t("Exclude"),
		CandyLocale.t("Values to drop from the loaded data. Comma separated."))
	exclude.focus_exited.connect(func(): _recombine(key))
	exclude.text_submitted.connect(func(_text: String): _recombine(key))

	var extra := add_text(_key(key, "Add"), CandyLocale.t("Add"),
		CandyLocale.t("Extra values that aren't in the script. Comma separated."))
	extra.focus_exited.connect(func(): _recombine(key))
	extra.text_submitted.connect(func(_text: String): _recombine(key))

	add_display(_key(key, "Data"), CandyLocale.t("In use"), CandyLocale.t("Loaded, minus excluded, plus added. This is what Candy DC uses."))


#& Updating

func _update_all() -> void:
	var total := 0
	for kind in KINDS:
		total += _update_kind(str(kind[1]), false)
	refresh()
	_set_status(CandyLocale.t("Updated {values} values across {kinds} kinds.").format({"values": total, "kinds": KINDS.size()}))


#* Read one kind from its script, rewriting Loaded and Data:
func _update_kind(key: String, refresh_now: bool = true) -> int:
	var script_path := resolve_path(str(draft.get_value(_key(key, "Script"), "")), ROOT_KEY)
	var variable_name := str(draft.get_value(_key(key, "Variable"), ""))

	if script_path == "" or variable_name == "":
		_set_status(CandyLocale.t("%s: set a script and a variable first.") % key)
		return 0
	if not FileAccess.file_exists(script_path):
		_set_status(CandyLocale.t("{kind}: no file at {path}").format({"kind": key, "path": script_path}))
		return 0

	var loaded := CandyProjectScripts.read_variable(script_path, variable_name)
	draft.set_value(_key(key, "Loaded"), CandyProjectScripts.join_list(loaded))
	_recombine(key, false)

	if refresh_now:
		refresh()
		if loaded.is_empty():
			_set_status(CandyLocale.t("{kind}: found no values in \"{variable}\".").format({"kind": key, "variable": variable_name}))
		else:
			_set_status(CandyLocale.t("{kind}: loaded {count} values.").format({"kind": key, "count": loaded.size()}))
	return loaded.size()			#/ Values found


#* Recompute Data from Loaded, Exclude and Add:
func _recombine(key: String, refresh_now: bool = true) -> void:
	var combined := CandyProjectScripts.combine(
		CandyProjectScripts.split_list(str(draft.get_value(_key(key, "Loaded"), ""))),
		CandyProjectScripts.split_list(str(draft.get_value(_key(key, "Exclude"), ""))),
		CandyProjectScripts.split_list(str(draft.get_value(_key(key, "Add"), ""))))
	draft.set_value(_key(key, "Data"), CandyProjectScripts.join_list(combined))
	if refresh_now:
		refresh()


func _key(kind: String, field: String) -> String:
	return "%s/%s/%s" % [SCRIPTS_KEY, kind, field]


func _insert_key(table: String, field: String) -> String:
	return "%s/%s/%s" % [CandyResources.INSERT_TABLES_KEY, table, field]


func _set_status(message: String) -> void:
	if _status == null:
		return
	if message == "":
		_status.text = " "
	else:
		_status.text = message