#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Node

signal saved(path: String, save_type: String)
signal current_save_changed(path: String)

const DIALOGUE_VERSION := "1.2"

const TYPE_NORMAL := "Normal Save"
const TYPE_AUTO := "Auto Save"
const TYPE_QUICK := "Quick Save"

const MODE_NORMAL := 0
const MODE_INCREMENTAL := 1

const KIND_MANUAL := "Manual_Saves"
const KIND_AUTO := "Auto_Saves"
const KIND_QUICK := "Quick_Saves"
const PATH_SETTINGS := {
	KIND_MANUAL: "manual_saves_path",
	KIND_AUTO: "auto_saves_path",
	KIND_QUICK: "quick_saves_path",
}

const LOAD_PATH_SETTING := "load_path"

const AUTO_PREFIX := "Auto_Save"
const QUICK_PREFIX := "Quick_Save"
const MIN_AUTO_SAVE_SECONDS := 5
const DEFAULT_AUTO_SAVE_SECONDS := 60

var current_save: String = ""

var _auto_timer: Timer
#^ The dialogue as last auto saved, so an unchanged one isn't saved again (rotating saves out):
var _last_auto_text: String = ""
var _stamp_regex := RegEx.new()


func _ready() -> void:
	#? The stamp Save Incremental adds, with its "_".
	_stamp_regex.compile("_?〔D-\\d{4}-\\d{2}-\\d{2}_T-\\d{2}-\\d{2}-\\d{2}〕$")

	_auto_timer = Timer.new()
	_auto_timer.one_shot = false
	_auto_timer.timeout.connect(_on_auto_save_timeout)
	add_child(_auto_timer)

	CandyProfiles.profile_opened.connect(_on_profile_opened)
	CandyProfiles.profile_closed.connect(_on_profile_closed)
	CandyProfiles.settings_changed.connect(_on_setting_changed)


#& Folders

#* Get a save kind's folder (KIND_*), created if missing:
func folder(kind: String) -> String:
	if not CandyProfiles.is_profile_open():
		return ""
	var path := str(CandyProfiles.get_setting(str(PATH_SETTINGS.get(kind, "")), "")).strip_edges()
	if path == "":
		path = CandyProfiles.current_saves_dir(kind)
	DirAccess.make_dir_recursive_absolute(path)
	return path


#* Get where Load Dialogue starts ("load_path", or the profile's Saves folder):
func load_folder() -> String:
	if not CandyProfiles.is_profile_open():
		return ""
	var path := str(CandyProfiles.get_setting(LOAD_PATH_SETTING, "")).strip_edges()
	if path == "":
		path = CandyProfiles.current_saves_dir()
	DirAccess.make_dir_recursive_absolute(path)
	return path


func default_load_folder() -> String:
	if not CandyProfiles.is_profile_open():
		return ""
	return ProjectSettings.globalize_path(CandyProfiles.current_saves_dir())


#* Get a save kind's default folder, as an OS path:
func default_folder(kind: String) -> String:
	if not CandyProfiles.is_profile_open():
		return ""
	return ProjectSettings.globalize_path(CandyProfiles.current_saves_dir(kind))


#& Manual saves

#* Set the current save, so Save writes back to it:
func set_current_save(path: String) -> void:
	current_save = path
	current_save_changed.emit(path)


#* Save to the current save (Save As if none):
#? mode: MODE_NORMAL, MODE_INCREMENTAL, or -1 for the "default_save_mode" setting.
func save(mode: int = -1) -> void:
	if not CandyProfiles.is_profile_open():
		return
	if not CandyDialogue.symbols_match():
		CandySymbolPrompt.ensure_dialogue(self, CandyLocale.t("saving"), save.bind(mode))
		return
	if mode < 0:
		mode = _default_mode()
	if current_save == "":
		save_as(mode)
		return
	_save_manual(current_save, mode)


func save_incremental() -> void:
	save(MODE_INCREMENTAL)


#* Ask for a file, then save to it:
#? mode as in save().
func save_as(mode: int = -1) -> void:
	if not CandyProfiles.is_profile_open():
		return
	if not CandyDialogue.symbols_match():
		CandySymbolPrompt.ensure_dialogue(self, CandyLocale.t("saving"), save_as.bind(mode))
		return
	if mode < 0:
		mode = _default_mode()
	var dialog := FileDialog.new()
	dialog.title = CandyLocale.t("Save Dialogue As")
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.filters = PackedStringArray(["*.txt ; " + CandyLocale.t("Dialogue saves")])
	var start_folder := ProjectSettings.globalize_path(folder(KIND_MANUAL))
	if current_save != "":
		start_folder = current_save.get_base_dir()
	dialog.current_dir = start_folder
	if current_save != "":
		dialog.current_file = current_save.get_file()
	dialog.file_selected.connect(func(path: String):
		dialog.queue_free()
		if path.get_extension().to_lower() != "txt":
			path += ".txt"
		_save_manual(path, mode))
	dialog.canceled.connect(dialog.queue_free)
	CandyLocale.claim(dialog)
	dialog.theme = CandyTheme.theme
	add_child(dialog)
	dialog.popup_centered_ratio(0.6)


#* Write a manual save:
func _save_manual(path: String, mode: int) -> void:
	CandyLayout.commit_typing()	#/ Auto saves never do: it would end the typing's undo step
	var target := path
	if mode == MODE_INCREMENTAL:
		target = incremental_path(path)
	if write_save(target, TYPE_NORMAL):
		set_current_save(target)


#* Get path with its incremental stamp set to now:
func incremental_path(path: String) -> String:
	var extension := path.get_extension()
	var base := path.get_basename()
	base = _stamp_regex.sub(base, "")
	if extension == "":
		extension = "txt"
	return "%s_〔%s〕.%s" % [base, _stamp(), extension]


func _default_mode() -> int:
	if int(str(CandyProfiles.get_setting("default_save_mode", MODE_NORMAL))) == MODE_INCREMENTAL:
		return MODE_INCREMENTAL
	return MODE_NORMAL


#& Loading

func open_load_dialog() -> void:
	if not CandyProfiles.is_profile_open():
		return
	var dialog := FileDialog.new()
	dialog.title = CandyLocale.t("Load Dialogue")
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.use_native_dialog = true
	dialog.filters = PackedStringArray(["*.txt ; " + CandyLocale.t("Dialogue saves")])
	dialog.current_dir = ProjectSettings.globalize_path(load_folder())
	dialog.file_selected.connect(func(path: String):
		dialog.queue_free()
		_load_checked(path))
	dialog.canceled.connect(dialog.queue_free)
	CandyLocale.claim(dialog)
	dialog.theme = CandyTheme.theme
	add_child(dialog)
	dialog.popup_centered_ratio(0.6)


#* Replace the dialogue with the default one, and clear the current save:
func new_dialogue() -> void:
	CandyDialogue.new_dialogue()
	#? Nothing to auto save until it's edited.
	_last_auto_text = _dialogue_text()
	set_current_save("")	#/ So Save asks for a file instead of overwriting the old dialogue's


#* Load a save, after asking to update its symbols if they aren't the profile's:
#? The presets and clipboard must use the profile's symbols too: they stay.
func _load_checked(path: String) -> void:
	CandySymbolPrompt.ensure_dialogue(self, CandyLocale.t("opening a save"), func():
		CandySymbolPrompt.ensure_files(self, [path], CandyLocale.t("opening it"), func():
			var problem := load_save(path)
			#? A file refused for its variations already has its report open.
			if problem != "" and problem != CandyVariationRepair.REFUSED:
				show_error(CandyLocale.t("Can't open this file"), problem)))


#* Replace the dialogue with a save file's:
#? On failure, returns why and leaves the dialogue alone.
func load_save(path: String) -> String:
	if not FileAccess.file_exists(path):
		return CandyLocale.t("The file doesn't exist:\n%s") % path
	var text := FileAccess.get_file_as_string(path)
	var data = str_to_var(text)
	if not data is Dictionary:
		data = JSON.parse_string(text)
	if not data is Dictionary or not data.get("Dialogue") is Dictionary:
		return CandyLocale.t("This isn't a Candy Dialogue Creator save file:\n%s") % path

	var version := str(data.get("Dialogue Version", "unknown")).strip_edges()
	if version != DIALOGUE_VERSION:
		return CandyLocale.t("This file uses the {version} dialogue format. Convert it to the {current} format with Edit > Dialogue Converter... first.").format(
			{"version": version, "current": DIALOGUE_VERSION})
	var problem := CandyDialogueExport.dialogue_symbols_problem()
	if problem == "":
		problem = CandyDialogueExport.file_symbols_problem({"symbols": CandySymbolUpdater.stored_symbols(data)})
	if problem != "":
		return problem

	#Ł Broken variation names are fixed, or the file is refused; either way a report opens:
	var repair := CandyDialogue.load_dialogue(data["Dialogue"])
	CandyVariationReportDialog.open_report(repair, path)
	if repair.has_problems():
		return CandyVariationRepair.REFUSED
	#? Nothing new to auto save.
	_last_auto_text = _dialogue_text()

	if str(data.get("Type", "")) == TYPE_NORMAL and _is_inside(path, folder(KIND_MANUAL)):
		set_current_save(path)
	else:
		set_current_save("")
	print("Loaded dialogue from: ", path)
	return ""			#/ Loaded


#* Check whether path is in folder_path or its subfolders:
func _is_inside(path: String, folder_path: String) -> bool:
	var file_dir := _comparable(path.get_base_dir())
	var root := _comparable(folder_path)
	return file_dir == root or file_dir.begins_with(root + "/")


func _comparable(path: String) -> String:
	var result := ProjectSettings.globalize_path(path).replace("\\", "/").simplify_path()
	result = result.trim_suffix("/")
	#% Windows and macOS paths ignore case:
	if OS.get_name() == "Windows" or OS.get_name() == "macOS":
		result = result.to_lower()
	return result


func show_error(title_text: String, message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title_text
	dialog.dialog_text = message
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	CandyLocale.claim(dialog)
	dialog.theme = CandyTheme.theme
	add_child(dialog)
	dialog.popup_centered()


#& Auto saves

func _on_profile_opened(_user: String, _profile: String) -> void:
	set_current_save("")
	_last_auto_text = _dialogue_text()
	_restart_auto_timer()


func _on_profile_closed() -> void:
	_auto_timer.stop()
	set_current_save("")
	_last_auto_text = ""


func _on_setting_changed(key: String) -> void:
	if key == "auto_save_freq" or key == "auto_saves_max":
		_restart_auto_timer()


func _restart_auto_timer() -> void:
	_auto_timer.stop()
	if not CandyProfiles.is_profile_open() or _max_files("auto_saves_max") < 0:
		return
	var seconds := int(str(CandyProfiles.get_setting("auto_save_freq", DEFAULT_AUTO_SAVE_SECONDS)))
	_auto_timer.wait_time = maxi(seconds, MIN_AUTO_SAVE_SECONDS)
	_auto_timer.start()


func _on_auto_save_timeout() -> void:
	if not CandyProfiles.is_profile_open():
		return
	var max_files := _max_files("auto_saves_max")
	if max_files < 0:
		_auto_timer.stop()
		return
	var text := _dialogue_text()
	if text == _last_auto_text:
		return
	var path := _rotating_path(folder(KIND_AUTO), AUTO_PREFIX, max_files)
	if write_save(path, TYPE_AUTO):
		_last_auto_text = text


#& Quick saves

func quick_save() -> bool:
	if not CandyProfiles.is_profile_open():
		return false
	var max_files := _max_files("quick_saves_max")
	if max_files < 0:
		push_warning("CandySaves: quick saving is turned off in the Save/Load settings.")
		return false
	if not CandyDialogue.symbols_match():
		CandySymbolPrompt.ensure_dialogue(self, CandyLocale.t("saving"), quick_save)
		return false
	CandyLayout.commit_typing()
	return write_save(_rotating_path(folder(KIND_QUICK), QUICK_PREFIX, max_files), TYPE_QUICK)


#* Get the newest quick save ("" if none):
func newest_quick_save() -> String:
	var dir_path := folder(KIND_QUICK)
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return ""
	var newest := ""
	var newest_time := -1
	for file_name in dir.get_files():
		if _slot_of(file_name, QUICK_PREFIX) < 1:
			continue
		var modified := FileAccess.get_modified_time(dir_path.path_join(file_name))
		if modified > newest_time:
			newest = dir_path.path_join(file_name)
			newest_time = modified
	return newest


#* Quick Load - ask, then load the newest quick save:
func ask_quick_load() -> void:
	if not CandyProfiles.is_profile_open():
		return
	var path := newest_quick_save()
	if path == "":
		show_error(CandyLocale.t("Quick Load"), CandyLocale.t("There is no quick save yet."))
		return
	CandyConfirmPrompt.ask(self, CandyLocale.t("Quick Load"),
		CandyLocale.t("Load the last quick save (%s)?\nAnything not saved will be lost.") % path.get_file(),
		CandyLocale.t("Load"), _load_checked.bind(path))


#& Writing

#* Write the dialogue to path (false on failure):
func write_save(path: String, save_type: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("CandySaves: can't write %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(_save_text(save_type))
	file.close()
	saved.emit(path, save_type)
	print("Saved %s to: %s" % [save_type, path])
	return true


func _save_text(save_type: String) -> String:
	var data := {
		"Type": save_type,
		"User": CandyProfiles.current_user,
		"Profile": CandyProfiles.current_profile,
		"Exported By": "Candy Dialogue Creator",
		"Version": CandyProfiles.VERSION,
		"Dialogue Version": DIALOGUE_VERSION,
		CandySymbolUpdater.SYMBOLS_KEY: CandyDialogue.symbols,
		"Dialogue": CandyDialogue.dialogue,
	}
	return CandyVariantFile.stringify(data) + "\n"


func _dialogue_text() -> String:
	return CandyVariantFile.stringify(CandyDialogue.dialogue)


#* Get a rotating save's maximum (-1 = off, 0 = no limit, else files kept):
func _max_files(key: String) -> int:
	return maxi(-1, int(str(CandyProfiles.get_setting(key, 5))))


#* Get a new rotating save's path:
func _rotating_path(dir_path: String, prefix: String, max_files: int) -> String:
	var slots := {}  #/ slot -> [file names]
	var oldest_slot := -1
	var oldest_time := -1
	var dir := DirAccess.open(dir_path)
	if dir != null:
		for file_name in dir.get_files():
			var file_slot := _slot_of(file_name, prefix)
			if file_slot < 1:
				continue
			if not slots.has(file_slot):
				slots[file_slot] = []
			slots[file_slot].append(file_name)
			if max_files > 0 and file_slot > max_files:
				continue  #/ Left over from a higher maximum: never reused
			var modified := FileAccess.get_modified_time(dir_path.path_join(file_name))
			if oldest_slot < 0 or modified < oldest_time:
				oldest_slot = file_slot
				oldest_time = modified

	var slot := 0
	if max_files == 0:
		#¦ 1. No limit - after the highest slot:
		for used in slots:
			slot = maxi(slot, int(used))
		slot += 1
	else:
		#¦ 2. The next free slot, else the oldest (its file deleted):
		for candidate in range(1, max_files + 1):
			if not slots.has(candidate):
				slot = candidate
				break
		if slot == 0:
			slot = maxi(oldest_slot, 1)
		if slots.has(slot):
			for file_name in slots[slot]:
				DirAccess.remove_absolute(dir_path.path_join(str(file_name)))

	return dir_path.path_join("%s_%d_%s.txt" % [prefix, slot, _stamp()])


#* Get the slot of "Prefix_3_....txt" (0 for any other file):
func _slot_of(file_name: String, prefix: String) -> int:
	if not file_name.begins_with(prefix + "_") or file_name.get_extension().to_lower() != "txt":
		return 0
	var rest := file_name.substr(prefix.length() + 1)
	var number := rest.get_slice("_", 0)
	if not number.is_valid_int():
		return 0
	return number.to_int()


#* Make a stamp, D-2026-09-20_T-08-01-00:
func _stamp() -> String:
	var now := Time.get_datetime_dict_from_system()
	return "D-%04d-%02d-%02d_T-%02d-%02d-%02d" % [now["year"], now["month"], now["day"],
		now["hour"], now["minute"], now["second"]]