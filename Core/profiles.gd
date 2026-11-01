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

signal users_changed
signal profiles_changed
signal profile_opened(user: String, profile: String)
#^ The open profile is about to close (last chance to store settings):
signal profile_closing
signal profile_closed
signal settings_changed(key: String)

const VERSION := "1.2.0"

const USERS_DIR := "user://Users"
const SETTINGS_FILE := "ProfileSettings.txt"
const SAVES_DIR := "Saves"
const SAVE_FOLDERS := ["Auto_Saves", "Manual_Saves", "Quick_Saves"]
#^ Last opened user/profile, preselected by the landing screen:
const SESSION_FILE := "user://Session.txt"

const INVALID_NAME_CHARS := ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]
#^ The user's saved layouts folder (CandyLayoutLibrary), beside the profiles:
#? Never a profile: not listed as one, and no profile may take its name.
const LAYOUTS_DIR := "Layouts"

var current_user: String = ""
var current_profile: String = ""
var settings: Dictionary = {}


func is_profile_open() -> bool:
	return current_user != "" and current_profile != ""


#& Paths

func user_dir(user: String) -> String:
	return USERS_DIR.path_join(user)


func profile_dir(user: String, profile: String) -> String:
	return user_dir(user).path_join(profile)


func settings_path(user: String, profile: String) -> String:
	return profile_dir(user, profile).path_join(SETTINGS_FILE)


func saves_dir(user: String, profile: String, kind: String = "") -> String:
	var path := profile_dir(user, profile).path_join(SAVES_DIR)
	if kind != "":
		return path.path_join(kind)
	return path


func current_profile_dir() -> String:
	if is_profile_open():
		return profile_dir(current_user, current_profile)
	return ""


func current_saves_dir(kind: String = "") -> String:
	if is_profile_open():
		return saves_dir(current_user, current_profile, kind)
	return ""


#& Listing & validation

func list_users() -> PackedStringArray:
	if not DirAccess.dir_exists_absolute(USERS_DIR):
		return PackedStringArray()
	var users := DirAccess.get_directories_at(USERS_DIR)
	users.sort()
	return users


func list_profiles(user: String) -> PackedStringArray:
	if user == "" or not DirAccess.dir_exists_absolute(user_dir(user)):
		return PackedStringArray()
	var profiles := PackedStringArray()
	for folder in DirAccess.get_directories_at(user_dir(user)):
		if not _is_reserved_profile_name(folder):
			profiles.append(folder)
	profiles.sort()
	return profiles


#* Validate a name ("" if usable, else the reason):
func validate_name(candidate_name: String) -> String:
	var trimmed := candidate_name.strip_edges()
	if trimmed == "":
		return CandyLocale.t("The name can't be empty.")
	if trimmed.length() > 64:
		return CandyLocale.t("The name is too long.")
	if trimmed.begins_with("."):
		return CandyLocale.t("The name can't start with a dot.")
	for c in INVALID_NAME_CHARS:
		if trimmed.contains(c):
			return CandyLocale.t("The name can't contain %s") % " ".join(INVALID_NAME_CHARS)
	return ""


#* Validate a profile name (validate_name() plus reserved names):
func validate_profile_name(candidate_name: String) -> String:
	var problem := validate_name(candidate_name)
	if problem != "":
		return problem
	if _is_reserved_profile_name(candidate_name.strip_edges()):
		return CandyLocale.t("\"%s\" is where this user's layouts are saved. Pick another name.") % LAYOUTS_DIR
	return ""


#* Check for a reserved profile name (case-insensitive, like some file systems):
func _is_reserved_profile_name(folder: String) -> bool:
	return folder.to_lower() == LAYOUTS_DIR.to_lower()


#& Users

func create_user(user: String) -> bool:
	user = user.strip_edges()
	if validate_name(user) != "" or DirAccess.dir_exists_absolute(user_dir(user)):
		return false
	if DirAccess.make_dir_recursive_absolute(user_dir(user)) != OK:
		return false
	users_changed.emit()
	return true


func rename_user(user: String, new_name: String) -> bool:
	new_name = new_name.strip_edges()
	if validate_name(new_name) != "" or DirAccess.dir_exists_absolute(user_dir(new_name)):
		return false
	if DirAccess.rename_absolute(user_dir(user), user_dir(new_name)) != OK:
		return false
	#Ł Keep every project profile's "User Name" in sync:
	for profile in list_profiles(new_name):
		var path := settings_path(new_name, profile)
		var data := read_settings_file(path)
		if not data.is_empty():
			data["User Name"] = new_name
			_write_variant(path, data)
	if current_user == user:
		current_user = new_name
		settings["User Name"] = new_name
	users_changed.emit()
	return true


func delete_user(user: String) -> bool:
	if current_user == user:
		close_profile()
	var ok := _delete_folder_recursive(user_dir(user))
	users_changed.emit()
	return ok


#& Project profiles

func create_profile(user: String, profile: String) -> bool:
	profile = profile.strip_edges()
	if user == "" or validate_profile_name(profile) != "":
		return false
	var dir := profile_dir(user, profile)
	if DirAccess.dir_exists_absolute(dir):
		return false
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		return false
	for folder in SAVE_FOLDERS:
		DirAccess.make_dir_recursive_absolute(saves_dir(user, profile, folder))

	_write_variant(settings_path(user, profile), CandyProfileDefaults.create(user, profile, VERSION))
	profiles_changed.emit()
	return true


func rename_profile(user: String, profile: String, new_name: String) -> bool:
	new_name = new_name.strip_edges()
	if validate_profile_name(new_name) != "" or DirAccess.dir_exists_absolute(profile_dir(user, new_name)):
		return false
	if DirAccess.rename_absolute(profile_dir(user, profile), profile_dir(user, new_name)) != OK:
		return false

	var path := settings_path(user, new_name)
	var data := read_settings_file(path)
	if not data.is_empty():
		data["Profile Name"] = new_name
		_write_variant(path, data)
	if current_user == user and current_profile == profile:
		current_profile = new_name
		settings["Profile Name"] = new_name
	profiles_changed.emit()
	return true


func delete_profile(user: String, profile: String) -> bool:
	if current_user == user and current_profile == profile:
		close_profile()
	var ok := _delete_folder_recursive(profile_dir(user, profile))
	profiles_changed.emit()
	return ok


#& Opening / closing

func open_profile(user: String, profile: String) -> bool:
	if not DirAccess.dir_exists_absolute(profile_dir(user, profile)):
		return false
	if is_profile_open():
		close_profile()

	#Ł Defaults first, then the file - new keys get defaults, retired keys are kept:
	var data := CandyProfileDefaults.merge_file(CandyProfileDefaults.create(user, profile, VERSION),
		read_settings_file(settings_path(user, profile)))
	data = _migrate(data)
	data["User Name"] = user
	data["Profile Name"] = profile

	settings = data
	current_user = user
	current_profile = profile
	_ensure_folders()
	save_settings()
	_write_variant(SESSION_FILE, {"user": user, "profile": profile})
	profile_opened.emit(user, profile)
	return true


func close_profile() -> void:
	if not is_profile_open():
		return
	profile_closing.emit()
	save_settings()
	current_user = ""
	current_profile = ""
	settings = {}
	profile_closed.emit()


func get_last_session() -> Dictionary:
	var data := read_settings_file(SESSION_FILE)
	return data


#& Settings

func get_setting(key: String, default_value: Variant = null) -> Variant:
	return settings.get(key, default_value)


func set_setting(key: String, value: Variant, autosave: bool = true) -> void:
	if not is_profile_open():
		return
	settings[key] = value
	settings_changed.emit(key)
	if autosave:
		save_settings()


func save_settings() -> bool:
	if not is_profile_open():
		return false
	return _write_variant(settings_path(current_user, current_profile), settings)


#* Read a .txt data file ({} if missing or malformed):
func read_settings_file(path: String) -> Dictionary:
	return CandyVariantFile.read(path)


func _migrate(data: Dictionary) -> Dictionary:
	var file_version := str(data.get("Candy DC Version", "1.1.0"))
	if file_version.begins_with("1.1"):
		#% 1.1 -> 1.2 - default_text_direction, languages, line_colors and variants are dropped:
		pass
	data["Candy DC Version"] = VERSION
	return data


#& File helpers

func _ensure_folders() -> void:
	for folder in SAVE_FOLDERS:
		var path := current_saves_dir(folder)
		if path != "" and not DirAccess.dir_exists_absolute(path):
			DirAccess.make_dir_recursive_absolute(path)


func _write_variant(path: String, data: Variant) -> bool:
	return CandyVariantFile.write(path, data)


func _delete_folder_recursive(path: String) -> bool:
	var dir := DirAccess.open(path)
	if dir == null:
		return false
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		var full_path := path.path_join(item)
		if dir.current_is_dir():
			_delete_folder_recursive(full_path)
		else:
			DirAccess.remove_absolute(full_path)
		item = dir.get_next()
	dir.list_dir_end()
	return DirAccess.remove_absolute(path) == OK


#* Get a color setting, stored as a Color or a var_to_str() string (1.1):
func get_color_setting(key: String, default_value: Color = Color.WHITE) -> Color:
	var value = settings.get(key, null)
	if value is Color:
		return value
	if value is String:
		var parsed = str_to_var(value)
		if parsed is Color:
			return parsed
	return default_value


func set_color_setting(key: String, value: Color, as_string: bool = true, autosave: bool = true) -> void:
	var stored: Variant = value
	if as_string:
		stored = var_to_str(value)
	set_setting(key, stored, autosave)