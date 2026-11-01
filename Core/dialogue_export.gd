#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDialogueExport

const TEST_FILE := "test_dialogue.txt"
const DIALOGUES_KEY := "Dialogues"
const PATHS_KEY := "custom_project_paths"
const ROOT_KEY := "project_path"
const EXPORTED_BY := "Candy Dialogue Creator"
const COMMENT := "\u0023"


#& Folders

#* The Dialogues folder's absolute path ("" if unknown):
static func dialogues_folder() -> String:
	if not CandyProfiles.is_profile_open():
		return ""
	var relative := ""
	var paths = CandyProfiles.get_setting(PATHS_KEY, {})
	if paths is Dictionary:
		relative = str(paths.get(DIALOGUES_KEY, "")).strip_edges()
	if relative == "":
		relative = _default_dialogues_folder()
	if relative == "":
		return ""
	if relative.is_absolute_path():
		return ProjectSettings.globalize_path(relative)
	var root := str(CandyProfiles.get_setting(ROOT_KEY, "")).strip_edges()
	if root == "":
		return ""
	return root.path_join(relative)


static func _default_dialogues_folder() -> String:
	var defaults = CandyProfileDefaults.create("", "", CandyProfiles.VERSION).get(PATHS_KEY, {})
	if defaults is Dictionary:
		return str(defaults.get(DIALOGUES_KEY, ""))
	return ""


#* What the user typed, as an absolute path:
static func resolve_path(text: String, add_extension: bool) -> String:
	var path := text.strip_edges()
	if path == "":
		return ""
	if add_extension and path.get_extension() == "":
		path += ".txt"
	if path.is_absolute_path():
		return ProjectSettings.globalize_path(path)
	#% Relative paths land in the Dialogues folder:
	var folder := dialogues_folder()
	if folder == "":
		return path
	return folder.path_join(path)


#& Export

#* Export the whole dialogue over the file:
static func export_dialogue(path: String) -> String:
	var problem := _check_export_path(path)
	if problem != "":
		return problem
	return _write(path, export_text(export_data()))


#* Why the open dialogue can't be exported or saved with the profile's symbols ("" if it can):
#? CandySymbolPrompt.ensure_dialogue() updates it first.
static func dialogue_symbols_problem() -> String:
	if CandyDialogue.symbols_match():
		return ""
	return CandyLocale.t("The profile's symbols changed since it was opened. Update the open dialogue's symbols first.")


#* Why a file read by read_dialogue() can't be merged with the open dialogue ("" if it can):
#? CandySymbolPrompt.ensure_files() updates it first. A file that doesn't store its symbols can.
static func file_symbols_problem(result: Dictionary) -> String:
	var symbols: Dictionary = result.get("symbols", {})
	if symbols.is_empty() or CandySymbolUpdater.same_symbols(symbols, CandySymbolUpdater.profile_symbols()):
		return ""
	return CandyLocale.t("This file was written with other symbols than the profile's. Update its symbols first (Edit > Symbol Updater...).")



#* Merge the selection into the file (CandyDialogueMerge):
static func export_merged(path: String, selection: Dictionary, mode: int, unit: int) -> String:
	var problem := _check_export_path(path)
	if problem != "":
		return problem
	problem = dialogue_symbols_problem()
	if problem != "":
		return problem
	var target := {}
	#? Overwrite doesn't read the file, so it also replaces an unreadable one.
	if mode != CandyDialogueMerge.Mode.OVERWRITE and FileAccess.file_exists(path):
		var read := {}
		problem = read_dialogue(path, read)
		if problem == "":
			problem = file_symbols_problem(read)
		if problem != "":
			return problem
		target = read["dialogue"]
	var merged := CandyDialogueMerge.run(target, export_data(), selection, mode, unit, true)
	return _write(path, export_text(merged["result"]))


static func _check_export_path(path: String) -> String:
	if not CandyProfiles.is_profile_open():
		return CandyLocale.t("Open a project profile first.")
	if path == "":
		return CandyLocale.t("No file given.")
	if path.get_extension().to_lower() != "txt":
		return CandyLocale.t("The file must be a .txt file.")
	return ""


static func _write(path: String, text: String) -> String:
	var dir_error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if dir_error != OK and not DirAccess.dir_exists_absolute(path.get_base_dir()):
		return CandyLocale.t("Can't create the folder:\n{folder}\n({error})").format({"folder": path.get_base_dir(), "error": error_string(dir_error)})

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return CandyLocale.t("Can't write the file:\n{file}\n({error})").format({"file": path, "error": error_string(FileAccess.get_open_error())})
	file.store_string(text)
	file.close()
	print("Exported dialogue to: ", path)
	return ""


#* Export to test_dialogue.txt in the Dialogues folder:
static func test_export() -> String:
	if not CandyProfiles.is_profile_open():
		return CandyLocale.t("Open a project profile first.")
	var folder := dialogues_folder()
	if folder == "":
		return CandyLocale.t("Set the project root in Settings > Project > Paths first: the Dialogues folder is inside it.")
	var problem := dialogue_symbols_problem()
	if problem != "":
		return problem
	return export_dialogue(folder.path_join(TEST_FILE))


static func test_path() -> String:
	var folder := dialogues_folder()
	if folder == "":
		return ""
	return folder.path_join(TEST_FILE)


#* The file's text around a dialogue:
#? symbols: the ones the dialogue is written with (CandySymbolUpdater's keys), the open dialogue's by default.
static func export_text(dialogue: Dictionary, symbols: Dictionary = {}) -> String:
	if symbols.is_empty():
		symbols = CandyDialogue.symbols
	var data := {
		"Meta": {
			"Exported By": EXPORTED_BY,
			"Creator Version": CandyProfiles.VERSION,
			"Dialogue Version": CandySaves.DIALOGUE_VERSION,
			CandySymbolUpdater.SYMBOLS_KEY: symbols,
		},
		"Dialogue": dialogue,
	}
	var header := "%s Exported By: %s\n" % [COMMENT, EXPORTED_BY]
	header += "%s Creator Version: %s\n" % [COMMENT, CandyProfiles.VERSION]
	header += "%s Dialogue Version: %s\n\n" % [COMMENT, CandySaves.DIALOGUE_VERSION]
	return header + CandyVariantFile.stringify(data) + "\n"


#* The profile's Candy DE symbols, by their Candy_Properties.gd variable names, and its CandyRef tables:
static func export_symbols() -> Dictionary:
	var stored = {}
	if CandyProfiles.is_profile_open():
		stored = CandyProfiles.get_setting(CandySymbolsPage.SYMBOLS_KEY, {})
	if not stored is Dictionary:
		stored = {}
	var symbols := {}
	for symbol in CandySymbolsPage.SYMBOLS:
		symbols[str(symbol[2])] = str(stored.get(str(symbol[1]), ""))
	symbols.merge(CandySymbolUpdater.tables_of(candy_ref_entries()))
	return symbols


#* The profile's CandyRef_Shortcuts.gd symbols, as the Symbols page lists them:
static func candy_ref_entries() -> Array:
	if not CandyProfiles.is_profile_open():
		return []
	var entries = CandyProfiles.get_setting(CandySymbolsPage.CANDY_REF_KEY, [])
	if entries is Array:
		return entries
	return []


#* A cleaned copy of the dialogue:
static func export_data() -> Dictionary:
	var data: Dictionary = CandyDialogue.dialogue.duplicate(true)
	for conversation in data.values():
		if not conversation is Dictionary:
			continue
		for block in conversation.values():
			if not block is Dictionary:
				continue
			var text_lines = block.get(CandyDialogue.TEXT_KEY)
			if not text_lines is Array:
				continue
			for line in text_lines:
				if not line is Dictionary:
					continue
				for line_type in line:
					_clean_line_data(line[line_type])
	return data


#* Drop editor data and empty variations, at any depth:
static func _clean_line_data(value: Variant) -> void:
	if value is Dictionary:
		value.erase(CandyDialogue.META_KEY)
		if value.get("Variations") is Array:
			value["Variations"] = _filled_variations(value["Variations"])
		for child in value.values():
			_clean_line_data(child)
	elif value is Array:
		for item in value:
			_clean_line_data(item)


#* Leave out variations with empty text ([{"Default" = {"Text" = ...}}, ...]):
static func _filled_variations(entries: Array) -> Array:
	var kept: Array = []
	for entry in entries:
		if entry is Dictionary and entry.size() == 1:
			var content = entry.values()[0]
			if content is Dictionary and content.has("Text") and str(content["Text"]) == "":
				continue
		kept.append(entry)
	return kept


#& Import

#* Whether the selection of path can be imported:
static func check_import(path: String, selection: Dictionary) -> String:
	var result := {}
	var problem := read_dialogue(path, result)
	if problem != "":
		return problem
	var repair := CandyVariationRepair.check(CandyDialogueMerge.selected_part(result["dialogue"], selection))
	#% Unfixable variation names open their report:
	if repair.has_problems():
		CandyVariationReportDialog.open_report(repair, path)
		return CandyVariationRepair.REFUSED
	return ""


#* Merge the selection of path into the open dialogue (CandyDialogueMerge):
static func import_merged(path: String, selection: Dictionary, mode: int, unit: int) -> String:
	if not CandyProfiles.is_profile_open():
		return CandyLocale.t("Open a project profile first.")
	var result := {}
	var problem := read_dialogue(path, result)
	if problem == "":
		problem = dialogue_symbols_problem()
	if problem == "":
		problem = file_symbols_problem(result)
	if problem != "":
		return problem
	var source: Dictionary = result["dialogue"]
	var part := CandyDialogueMerge.selected_part(source, selection)
	#@ Step 1 - Broken variation names are fixed or refuse the import (a report opens):
	var repair := CandyVariationRepair.check(part)
	CandyVariationReportDialog.open_report(repair, path)
	if repair.has_problems():
		return CandyVariationRepair.REFUSED
	repair.apply()
	#@ Step 2 - Normalize the imported lines:
	for blocks in part.values():
		for block in blocks.values():
			if block is Dictionary and block.get(CandyDialogue.TEXT_KEY) is Array:
				var text_lines: Array = block[CandyDialogue.TEXT_KEY]
				for i in text_lines.size():
					if text_lines[i] is Dictionary:
						text_lines[i] = CandySchemas.normalize_line(text_lines[i])

	var merged := CandyDialogueMerge.run(CandyDialogue.dialogue, source, selection, mode, unit, true)
	if mode == CandyDialogueMerge.Mode.OVERWRITE:
		CandyDialogue.set_dialogue(merged["result"])
		#? Not the open save anymore.
		CandySaves.set_current_save("")
	else:
		CandyDialogue.merge_dialogue(merged["result"])
	print("Imported dialogue from: ", path)
	return ""


#* Parse a dialogue file into result["dialogue"], and the symbols it stores into result["symbols"] ({} if none):
static func read_dialogue(path: String, result: Dictionary) -> String:
	if path == "":
		return CandyLocale.t("No file given.")
	if path.get_extension().to_lower() != "txt":
		return CandyLocale.t("The file must be a .txt file.")
	if not FileAccess.file_exists(path):
		return CandyLocale.t("The file doesn't exist:\n%s") % path

	var text := _strip_header(FileAccess.get_file_as_string(path))
	if text.strip_edges() == "":
		return CandyLocale.t("The file is empty:\n%s") % path
	var data = str_to_var(text)
	if not data is Dictionary:
		data = JSON.parse_string(text)
	if not data is Dictionary or not data.get("Dialogue") is Dictionary:
		return CandyLocale.t("This isn't a Candy dialogue file:\n%s") % path

	#@ Step 1 - Version -under "Meta" in exports, at the top in saves:
	var version := str(data.get("Dialogue Version", "unknown"))
	var meta = data.get("Meta")
	if meta is Dictionary:
		version = str(meta.get("Dialogue Version", version))
	version = version.strip_edges()
	if version != CandySaves.DIALOGUE_VERSION:
		return CandyLocale.t("This file uses the {version} dialogue format. Convert it to the {current} format with Edit > Dialogue Converter... first.").format({"version": version, "current": CandySaves.DIALOGUE_VERSION})

	var dialogue: Dictionary = data["Dialogue"].duplicate(true)
	#@ Step 2 - Drop preset conversation names:
	for preset in CandyDialogue.PRESET_CONVERSATIONS:
		dialogue.erase(preset)
	result["dialogue"] = dialogue
	result["symbols"] = CandySymbolUpdater.stored_symbols(data)
	return ""


#* Drop the "# ..." header lines (str_to_var() can't read them):
static func _strip_header(text: String) -> String:
	var lines := text.split("\n")
	var start := 0
	while start < lines.size():
		var line := lines[start].strip_edges()
		if line != "" and not line.begins_with(COMMENT):
			break
		start += 1
	return "\n".join(lines.slice(start))
