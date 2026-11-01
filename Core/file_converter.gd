#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFileConverter
extends RefCounted

const KIND_DIALOGUE := "Dialogue"
const KIND_SAVE := "Save"
const KIND_PRESETS := "Presets"

#^ What inspect() found:
const STATUS_CONVERT := "convert"
const STATUS_CURRENT := "current"
const STATUS_OLD := "old"
const STATUS_UNREADABLE := "unreadable"

const OUTCOME_CONVERTED := "converted"
const OUTCOME_SKIPPED := "skipped"
const OUTCOME_FAILED := "failed"

const BACKUP_FOLDER := "Conversion Backups"
const BACKUP_KIND_FOLDER := "1.1 to 1.2"
const LOG_FILE := "Conversion Log.txt"
const PRESET_KEYS := ["USER PRESETS", "PROFILE PRESETS"]
const VERSION_HEADER := "Creator Version:"
const COMMENT := "#"


#& Reading

#* Inspect a file:
static func inspect(path: String) -> Dictionary:
	var info := {"path": path, "kind": "", "version": "", "status": STATUS_UNREADABLE,
		"problem": "", "data": {}, "header": PackedStringArray(), "raw": ""}	#/ problem: why it can't be converted. header: its "#" lines
	if not FileAccess.file_exists(path):
		info["problem"] = CandyLocale.t("The file doesn't exist.")
		return info
	var raw := FileAccess.get_file_as_string(path)
	info["raw"] = raw
	var header := PackedStringArray()
	var body := PackedStringArray()
	for line in raw.split("\n"):
		if line.strip_edges().begins_with(COMMENT):
			if body.is_empty():
				header.append(line.strip_edges())
			continue
		body.append(line)
	info["header"] = header
	var data = _parse("\n".join(body))
	if not data is Dictionary:
		info["problem"] = CandyLocale.t("This isn't a dialogue, save or preset file Candy Dialogue Creator can read.")
		return info
	info["data"] = data

	var version := ""
	if preset_key(data) != "":
		info["kind"] = KIND_PRESETS
		for line in header:
			var at := line.find(VERSION_HEADER)
			if at >= 0:
				version = line.substr(at + VERSION_HEADER.length()).strip_edges()
	elif data.get("Meta") is Dictionary and data.get("Dialogue") is Dictionary:
		info["kind"] = KIND_DIALOGUE
		version = str(data["Meta"].get("Dialogue Version", ""))
	elif data.get("Dialogue") is Dictionary and (data.has("Dialogue Version") or data.has("Type")):
		info["kind"] = KIND_SAVE
		version = str(data.get("Dialogue Version", ""))
	elif data.get("Dialogue") is Dictionary or _looks_like_conversations(data):
		info["kind"] = KIND_DIALOGUE
	else:
		info["problem"] = CandyLocale.t("This isn't a dialogue, save or preset file Candy Dialogue Creator can read.")
		return info
	version = version.strip_edges()
	info["version"] = version

	if version.begins_with("1.2"):
		info["status"] = STATUS_CURRENT
		info["problem"] = CandyLocale.t("Already in the 1.2 format.")
	elif version.begins_with("1.0"):
		info["status"] = STATUS_OLD
		info["problem"] = CandyLocale.t("A 1.0 file: convert it to 1.1 with Candy Dialogue Creator 1.1's converter first.")
	elif version.begins_with("1.1") or _has_old_commands(data):
		info["status"] = STATUS_CONVERT
	elif version == "":
		info["status"] = STATUS_CURRENT
		info["problem"] = CandyLocale.t("Nothing in it was written for Candy DE 1.1.")
	else:
		info["status"] = STATUS_UNREADABLE
		info["problem"] = CandyLocale.t("Unknown format version: %s.") % version
	return info


#* A file kind as shown (KIND_SAVE is a save file, not the command):
static func kind_label(kind: String) -> String:
	match kind:
		KIND_DIALOGUE:
			return CandyLocale.t("Dialogue", "file kind")
		KIND_SAVE:
			return CandyLocale.t("Save", "file kind")
		KIND_PRESETS:
			return CandyLocale.t("Presets", "file kind")
	return kind


#* Describe a file for the file list, e.g. "Dialogue, 1.1.0":
static func describe(info: Dictionary) -> String:
	var kind := str(info.get("kind", ""))
	if kind == "":
		return CandyLocale.t("Not readable")
	var version := str(info.get("version", ""))
	if version == "":
		return kind_label(kind)
	if kind == KIND_PRESETS:
		return CandyLocale.t("{kind}, Candy DC {version}").format({"kind": kind_label(kind), "version": version})
	return CandyLocale.t("{kind}, format {version}").format({"kind": kind_label(kind), "version": version})


#* Parse a file's text (without "#" lines) as GDScript data, else JSON:
static func _parse(text: String) -> Variant:
	var stripped := text.strip_edges()
	if stripped == "":
		return null
	var data = str_to_var(stripped)
	if data is Dictionary:
		return data
	data = str_to_var(stripped.replace("<null>", "null"))	#/ 1.1.3 also read <null>
	if data is Dictionary:
		return data
	data = JSON.parse_string(stripped)
	if data is Dictionary:
		return data
	return null


static func preset_key(data: Dictionary) -> String:
	for key in PRESET_KEYS:
		if data.get(key) is Dictionary:
			return key
	return ""


#* Check for { conversation = { block = { "Text" = [...] } } } with no wrapper:
static func _looks_like_conversations(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	for conversation in data.values():
		if not conversation is Dictionary:
			return false
		for block in conversation.values():
			if not block is Dictionary or not block.get(CandyDialogue.TEXT_KEY) is Array:
				return false
	return true


static func _has_old_commands(value: Variant) -> bool:
	if value is Dictionary:
		for key in value:
			var text := str(key)
			if text.begins_with("§") or text == "Spoken Line":
				return true
			if _has_old_commands(value[key]):
				return true
	elif value is Array:
		for item in value:
			if _has_old_commands(item):
				return true
	return false


#& Converting

#* Convert each file in place, after backing it up:
#? The options are CandyDialogueConverter's.
static func convert_files(paths: Array, old_symbols: Dictionary, new_symbols: Dictionary, project: Dictionary) -> Array:
	var stamp := make_stamp()
	var results: Array = []
	var backup_folders: Array = []
	for path in paths:
		var result := _convert_file(str(path), stamp, old_symbols, new_symbols, project)
		results.append(result)
		var backup := str(result.get("backup", ""))
		if backup != "" and not (backup.get_base_dir() in backup_folders):
			backup_folders.append(backup.get_base_dir())
	var log_text := "\n".join(report_lines(results)) + "\n"
	for folder in backup_folders:
		var file := FileAccess.open(str(folder).path_join(LOG_FILE), FileAccess.WRITE)
		if file != null:
			file.store_string(log_text)
			file.close()
	return results


#* The symbols a converted file is written with, as it records them:
#? The profile's, with the 1.2 symbols the conversion writes, but the 1.1 variable dictionary, role and
#? separator symbols, which the converter keeps. Candy Wizard's Symbol_Files.converted_symbols() does the same.
static func converted_symbols(old_symbols: Dictionary, new_symbols: Dictionary) -> Dictionary:
	var symbols := CandyDialogueExport.export_symbols()
	for symbol in CandySymbolsPage.SYMBOLS:
		if new_symbols.has(str(symbol[1])):
			symbols[str(symbol[2])] = str(new_symbols[str(symbol[1])])
	var old := CandyDialogueConverter.default_old_symbols()
	old.merge(old_symbols, true)
	for variable in [CandySymbolUpdater.VARDICT, CandySymbolUpdater.ROLE, CandySymbolUpdater.SEPARATOR]:
		symbols[variable] = str(old.get(variable, symbols.get(variable, "")))
	return symbols


static func _convert_file(path: String, stamp: String, old_symbols: Dictionary, new_symbols: Dictionary, project: Dictionary) -> Dictionary:
	var info := inspect(path)
	var result := {"path": path, "kind": info["kind"], "version": info["version"], "outcome": OUTCOME_SKIPPED,
		"message": str(info["problem"]), "backup": "", "notes": []}
	match str(info["status"]):
		STATUS_CURRENT:
			return result
		STATUS_OLD, STATUS_UNREADABLE:
			result["outcome"] = OUTCOME_FAILED
			return result

	var data: Dictionary = info["data"]
	var conversations: Dictionary = {}
	var presets_key := ""
	match str(info["kind"]):
		KIND_PRESETS:
			presets_key = preset_key(data)
			conversations = {presets_key: data[presets_key]}
		_:
			if data.get("Dialogue") is Dictionary:
				conversations = data["Dialogue"]
			else:
				conversations = data

	var converter := CandyDialogueConverter.new(old_symbols, new_symbols, project)
	var converted := converter.convert_conversations(conversations, presets_key == "")
	var notes: Array = converter.notes

	#Ł 1.2's variation names (":" in tags, and whatever Candy DC can fix):
	var repair := CandyVariationRepair.check(converted)
	for entry in repair.entries:
		for problem in entry["problems"]:
			notes.append({"where": entry["where"], "level": CandyDialogueConverter.LEVEL_CHECK,
				"text": CandyLocale.t("Variation {variation}: {problem}").format({"variation": entry["variation"], "problem": problem})})
	if repair.has_problems():
		result["outcome"] = OUTCOME_FAILED
		result["message"] = CandyLocale.t("Some variation names have problems Candy Dialogue Creator can't fix (listed below). Fix them in the file, then convert it again.")
		result["notes"] = notes
		return result
	for entry in repair.entries:
		var fixes: PackedStringArray = []
		for fix in entry["fixes"]:
			fixes.append("%s %s" % [fix["problem"], fix["fix"]])
		notes.append({"where": entry["where"], "level": CandyDialogueConverter.LEVEL_NOTE,
			"text": CandyLocale.t("Variation {variation} renamed {fixed}. {fixes}").format({"variation": entry["variation"],
				"fixed": entry["fixed"], "fixes": " ".join(fixes)})})
	repair.apply()

	var text := ""
	var symbols := converted_symbols(old_symbols, new_symbols)
	match str(info["kind"]):
		KIND_PRESETS:
			text = presets_text(info["header"], {presets_key: converted[presets_key],
				CandySymbolUpdater.SYMBOLS_KEY: symbols})
		KIND_SAVE:
			var save: Dictionary = data.duplicate()
			save["Dialogue Version"] = CandySaves.DIALOGUE_VERSION
			save["Version"] = CandyProfiles.VERSION
			save["Dialogue"] = converted
			save[CandySymbolUpdater.SYMBOLS_KEY] = symbols
			text = CandyVariantFile.stringify(save) + "\n"
		_:
			text = CandyDialogueExport.export_text(converted, symbols)

	var backup := backup_path(path, stamp)
	var problem := write_file(backup, str(info["raw"]))
	if problem != "":
		result["outcome"] = OUTCOME_FAILED
		result["message"] = CandyLocale.t("Couldn't back the file up, so it wasn't converted. %s") % problem
		return result
	result["backup"] = backup
	problem = write_file(path, text)
	if problem != "":
		result["outcome"] = OUTCOME_FAILED
		result["message"] = CandyLocale.t("Couldn't write the converted file. The original is unchanged. %s") % problem
		return result
	result["outcome"] = OUTCOME_CONVERTED
	result["message"] = ""
	result["notes"] = notes
	return result


#* Where a file is backed up (kind_folder: what changed it, e.g. "1.1 to 1.2"):
static func backup_path(path: String, stamp: String, kind_folder: String = BACKUP_KIND_FOLDER) -> String:
	return path.get_base_dir().path_join(BACKUP_FOLDER).path_join(kind_folder).path_join(stamp).path_join(path.get_file())


#* Rebuild the 1.1 header with the current Creator version:
static func presets_text(header: PackedStringArray, data: Dictionary) -> String:
	var lines := PackedStringArray()
	var found := false
	for line in header:
		if line.contains(VERSION_HEADER):
			lines.append("%s %s %s" % [COMMENT, VERSION_HEADER, CandyProfiles.VERSION])
			found = true
		else:
			lines.append(line)
	if not found:
		lines.insert(0, "%s %s %s" % [COMMENT, VERSION_HEADER, CandyProfiles.VERSION])
	return "\n".join(lines) + "\n\n" + CandyVariantFile.stringify(data) + "\n"


#* Write a file ("" on success, else why it failed):
static func write_file(path: String, text: String) -> String:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "(%s: %s)" % [path, error_string(FileAccess.get_open_error())]
	file.store_string(text)
	file.close()
	return ""


#* Make a stamp like the saves', D-2026-10-07_T-08-01-00:
static func make_stamp() -> String:
	var now := Time.get_datetime_dict_from_system()
	return "D-%04d-%02d-%02d_T-%02d-%02d-%02d" % [now["year"], now["month"], now["day"],
		now["hour"], now["minute"], now["second"]]


#& Report

#* Group a result's notes by text, checks first:
static func grouped_notes(result: Dictionary) -> Array:
	var groups: Array = []
	var by_text := {}
	for level in [CandyDialogueConverter.LEVEL_CHECK, CandyDialogueConverter.LEVEL_NOTE]:
		for note in result.get("notes", []):
			if str(note["level"]) != level:
				continue
			var key: String = str(level) + "\n" + str(note["text"])
			if not by_text.has(key):
				by_text[key] = {"text": note["text"], "level": level, "wheres": []}
				groups.append(by_text[key])
			by_text[key]["wheres"].append(note["where"])
	return groups


static func report_title() -> String:
	return CandyLocale.t("Dialogue Converter Report")


static func report_intro() -> String:
	return CandyLocale.t("Converted files replace the originals. Each original is backed up in a {folder} folder beside it, with this report as {log}.").format(
		{"folder": "%s/%s" % [BACKUP_FOLDER, BACKUP_KIND_FOLDER], "log": LOG_FILE})


static func summary_words() -> Dictionary:
	return {OUTCOME_CONVERTED: CandyLocale.t("Converted"), OUTCOME_SKIPPED: CandyLocale.t("Skipped"),
		OUTCOME_FAILED: CandyLocale.t("Not converted")}


#* Write the whole run as plain text:
static func report_lines(results: Array) -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append(CandyLocale.t("Candy Dialogue Creator %s: Dialogue Converter, 1.1 to 1.2") % CandyProfiles.VERSION)
	lines.append(Time.get_datetime_string_from_system(false, true))
	for result in results:
		lines.append("")
		lines.append(str(result["path"]))
		lines.append("    %s" % outcome_text(result))
		if str(result.get("backup", "")) != "":
			lines.append("    " + CandyLocale.t("Backup: %s") % result["backup"])
		for group in grouped_notes(result):
			var mark := CandyLocale.t("Check: %s")
			if str(group["level"]) == CandyDialogueConverter.LEVEL_NOTE:
				mark = CandyLocale.t("Note: %s")
			lines.append("    " + mark % group["text"])
			for where in group["wheres"]:
				lines.append("        %s" % where)
	return lines


static func outcome_text(result: Dictionary) -> String:
	match str(result["outcome"]):
		OUTCOME_CONVERTED:
			return CandyLocale.t("Converted (%s).") % CandyLocale.t(str(result["kind"])).to_lower()
		OUTCOME_SKIPPED:
			return CandyLocale.t("Skipped: %s") % result["message"]
	return CandyLocale.t("Not converted: %s") % result["message"]
