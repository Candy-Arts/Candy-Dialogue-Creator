#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDocsFiles
extends RefCounted

#& Set before fetch()
var docs_set: Dictionary = {}     #/ An entry of CandyDocs.SETS
var tree: Dictionary = {}         #/ CandyGitHubSource.fetch_tree()'s answer
var recorded: Dictionary = {}     #/ The set's last record ("files"), or empty
var target_folder := ""           #/ Where the databases go
var extensions: Array = []        #/ The only file types taken
var backups_folder := ""

#& The checked zip (fetch(); paths inside the databases folder)
var zip_hash := ""                #/ The zip's git hash on GitHub
var contents: Dictionary = {}     #/ path -> bytes

#& The plan (filled by plan(); paths inside the databases folder)
var problem := ""
var upstream: Dictionary = {}     #/ Every file of the zip: path -> git hash
var to_download: PackedStringArray = []
var to_remove: PackedStringArray = []
var changed_here: PackedStringArray = []
var left_out: PackedStringArray = []    #/ Types never downloaded

#& What apply() did
var backup_folder := ""
var record: Dictionary = {}


#* The set's zip in its repository ("DOCUMENTATION/Candy_Dialogue_Engine.zip"):
static func zip_path_of(of_set: Dictionary) -> String:
	return str(of_set["folder"]) + ".zip"


#* Check whether the zip on GitHub is the one last downloaded, and every file it brought is still here as it was:
func is_current() -> bool:
	var on_github := str(tree.get("files", {}).get(zip_path_of(docs_set), ""))
	if on_github == "" or str(recorded.get("zip_hash", "")) != on_github:
		return false
	var known := safe_files(recorded.get("files"))
	for relative: String in known:
		var target := target_folder.path_join(relative)
		if not FileAccess.file_exists(target) or not _has_hash(relative, FileAccess.get_file_as_bytes(target), str(known[relative])):
			return false
	return not known.is_empty()


#* Download the set's zip and check it, then plan() (sets problem on failure):
#? source must be in the scene tree.
func fetch(source: CandyGitHubSource) -> void:
	problem = ""
	contents = {}
	var title := CandyLocale.t(str(docs_set["title"]))
	var zip_path := zip_path_of(docs_set)
	if not tree.get("files", {}).has(zip_path):
		problem = CandyLocale.t("%s isn't on GitHub yet.") % title
		return
	zip_hash = str(tree["files"][zip_path])
	var downloaded: Dictionary = await source.download_files(str(docs_set["repository"]), str(tree["commit"]), {zip_path: zip_hash})
	if downloaded.has("error"):
		problem = CandyLocale.t("{error} Nothing was changed.").format({"error": str(downloaded["error"])})
		return
	var unpacked := CandyDocsZip.read(downloaded["files"][zip_path], str(docs_set["folder"]).get_file(), title, extensions)
	if unpacked.has("error"):
		problem = CandyLocale.t("{error} Nothing was changed.").format({"error": str(unpacked["error"])})
		return
	contents = unpacked["files"]
	left_out = unpacked["left_out"]
	plan()


#* Work out what writing the checked zip changes, changing nothing:
func plan() -> void:
	upstream.clear()
	to_download.clear()
	to_remove.clear()
	changed_here.clear()
	for relative: String in contents:
		upstream[relative] = CandyGitHubSource.git_blob_hash(relative, contents[relative], false)

	var known := safe_files(recorded.get("files"))
	for relative: String in upstream:
		var target := target_folder.path_join(relative)
		if not FileAccess.file_exists(target):
			to_download.append(relative)
			continue
		var bytes := FileAccess.get_file_as_bytes(target)
		if _has_hash(relative, bytes, upstream[relative]):
			continue
		to_download.append(relative)
		if not _has_hash(relative, bytes, str(known.get(relative, ""))):
			changed_here.append(relative)
	for relative: String in known:
		if upstream.has(relative):
			continue
		var target := target_folder.path_join(relative)
		if not FileAccess.file_exists(target):
			continue
		to_remove.append(relative)
		if not _has_hash(relative, FileAccess.get_file_as_bytes(target), str(known[relative])):
			changed_here.append(relative)
	to_download.sort()
	to_remove.sort()
	changed_here.sort()


#* Check whether the download would change anything:
func changes_something() -> bool:
	return not to_download.is_empty() or not to_remove.is_empty()


#* Write the zip's differing files, remove dropped ones, fill record:
func apply() -> String:
	if contents.is_empty():
		return CandyLocale.t("Download the documentation first.")
	plan()
	var error := _back_up()
	if error != "":
		return error
	for relative in to_download:
		error = write_file(target_folder.path_join(relative), contents[relative])
		if error != "":
			return CandyLocale.t("{error} The documentation is only partly updated: download it again.").format({"error": error})
	for relative in to_remove:
		if DirAccess.remove_absolute(target_folder.path_join(relative)) != OK:
			return CandyLocale.t("Couldn't remove %s. The documentation is only partly updated: download it again.") % target_folder.path_join(relative)
	_remove_emptied_folders()

	record = {
		"repository": docs_set["repository"],
		"folder": docs_set["folder"],
		"commit": tree["commit"],
		"zip_hash": zip_hash,
		"date": Time.get_datetime_string_from_system(false, true),
		"files": upstream.duplicate(),
	}
	return ""			#/ No error


#* Check a file against a git hash, as is or with normalized line endings:
static func _has_hash(relative: String, bytes: PackedByteArray, git_hash: String) -> bool:
	if git_hash == "":
		return false
	#? GitHub files with "\r\n" endings download with them.
	return CandyGitHubSource.git_blob_hash(relative, bytes, false) == git_hash \
		or CandyGitHubSource.git_blob_hash(relative, bytes) == git_hash


#* Get a record's files without paths that leave the folder:
#! The record can be edited by anyone: a "../../..." path must never be removed.
static func safe_files(listed: Variant) -> Dictionary:
	var safe := {}
	if not listed is Dictionary:
		return safe
	for path in listed:
		if CandyGitHubSource.is_safe_relative_path(str(path)):
			safe[str(path)] = str(listed[path])
	return safe


#* Write a file, making its folder (returns an error message, or ""):
static func write_file(path: String, bytes: PackedByteArray) -> String:
	var dir_error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if dir_error != OK:
		return CandyLocale.t("Couldn't create the folder {folder} ({error}).").format({"folder": path.get_base_dir(), "error": error_string(dir_error)})
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return CandyLocale.t("Couldn't write {file} ({error}).").format({"file": path, "error": error_string(FileAccess.get_open_error())})
	file.store_buffer(bytes)
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return CandyLocale.t("Couldn't write {file} ({error}).").format({"file": path, "error": error_string(write_error)})
	return ""


#* Back up the files changed here that the download replaces or removes:
func _back_up() -> String:
	backup_folder = ""
	if changed_here.is_empty():
		return ""
	var base := backups_folder.path_join("%s %s" % [docs_set["id"],
		Time.get_datetime_string_from_system(false, true).replace(":", "-")])
	backup_folder = base
	var number := 2
	while DirAccess.dir_exists_absolute(backup_folder):
		backup_folder = "%s (%d)" % [base, number]
		number += 1
	for relative in changed_here:
		var copy := backup_folder.path_join(relative)
		DirAccess.make_dir_recursive_absolute(copy.get_base_dir())
		var error := DirAccess.copy_absolute(target_folder.path_join(relative), copy)
		if error != OK:
			return CandyLocale.t("Couldn't keep a copy of the files changed here (%s), so nothing was changed.") % error_string(error)
	return ""


#* Remove the folders emptied by removed files, deepest first:
func _remove_emptied_folders() -> void:
	for relative in to_remove:
		var folder := relative.get_base_dir()
		while folder != "":
			var path := target_folder.path_join(folder)
			var dir := DirAccess.open(path)
			if dir == null:
				break
			dir.include_hidden = true
			if not dir.get_files().is_empty() or not dir.get_directories().is_empty():
				break
			if DirAccess.remove_absolute(path) != OK:
				break
			folder = folder.get_base_dir()
