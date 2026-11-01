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

#^ The databases were found again:
signal library_changed
#^ state, status_text or updates_waiting() changed:
signal status_changed

enum State { IDLE, CHECKING, DOWNLOADING }

const FOLDER := "user://Documentation"
const DATABASES_FOLDER := "user://Documentation/Databases"
const USER_THEMES_FOLDER := "user://Documentation/Themes"
const BACKUPS_FOLDER := "user://Documentation/Backups"
const STATE_FILE := "user://Documentation/Downloads.txt"
#^ Built-in documentation themes:
const BUILTIN_THEMES_FOLDER := "res://Documentation/Themes"

#^ The only documentation downloaded, a signed zip of the repository's DOCUMENTATION folder each (<folder>.zip, CandyDocsZip):
#? A database's folder lands in DATABASES_FOLDER under the same name.
const SETS := [
	{"id": "candy_de", "repository": "Candy-Arts/Candy-Arts", "repository_id": 1177938775, "branch": "main", "folder": "DOCUMENTATION/Candy_Dialogue_Engine",
		"title": "Candy DE Docs"},  #/ translatable
	{"id": "candy_dc", "repository": "Candy-Arts/Candy-Arts", "repository_id": 1177938775, "branch": "main", "folder": "DOCUMENTATION/Candy_Dialogue_Creator",
		"title": "Candy DC Docs"},  #/ translatable
]
#^ The only file types downloaded:
const EXTENSIONS := ["txt", "json", "md", "png", "jpg", "jpeg", "webp", "svg", "bmp", "ttf", "otf", "woff", "woff2", "gitkeep"]
#^ Seconds between two look_if_due() looks:
const CHECK_INTERVAL := 24 * 60 * 60
const DEFAULT_AUTO_CHECK := true

var state := State.IDLE
#^ What is going on, or how the last check or download went:
var status_text := ""
#^ Whether status_text is a problem:
var status_failed := false

#^ Where GitHub is (only tests change them):
var api_base := "":
	set(value):
		api_base = value
		if _source != null and value != "":
			_source.api_base = value
var raw_base := "":
	set(value):
		raw_base = value
		if _source != null and value != "":
			_source.raw_base = value

var _source: CandyGitHubSource
var _record: Dictionary = {}
var _databases: Array[Dictionary] = []
var _scanned := false
var _looked := false


func _ready() -> void:
	_source = CandyGitHubSource.new()
	add_child(_source)
	if api_base != "":
		_source.api_base = api_base
	if raw_base != "":
		_source.raw_base = raw_base
	_record = CandyVariantFile.read(STATE_FILE)


#& The databases

#* Every database found, sorted by title (CandyDocsLibrary.scan()):
func databases() -> Array[Dictionary]:
	if not _scanned:
		_scanned = true
		_databases = CandyDocsLibrary.scan([DATABASES_FOLDER])
	return _databases


#* Look for databases again:
func rescan() -> void:
	_scanned = false
	library_changed.emit()


#* The databases folder's file system path (made if missing):
func databases_folder() -> String:
	if not DirAccess.dir_exists_absolute(DATABASES_FOLDER):
		DirAccess.make_dir_recursive_absolute(DATABASES_FOLDER)
	return ProjectSettings.globalize_path(DATABASES_FOLDER)


#& Settings

#* Whether look_if_due() looks at GitHub:
func auto_check() -> bool:
	return CandyVariantFile.to_bool(_record.get("auto_check", DEFAULT_AUTO_CHECK), DEFAULT_AUTO_CHECK)


func set_auto_check(value: bool) -> void:
	_record["auto_check"] = value
	_save()


#& What GitHub has

func is_busy() -> bool:
	return state != State.IDLE


#* Whether any documentation was ever downloaded:
func has_downloads() -> bool:
	return not _sets().is_empty()


#* Titles of the sets GitHub has newer, as last looked:
func updates_waiting() -> PackedStringArray:
	var waiting: PackedStringArray = []
	var checked: Variant = _record.get("checked", {})
	if not checked is Dictionary or not checked.get("trees") is Dictionary:
		return waiting
	var sets := _sets()
	for docs_set: Dictionary in SETS:
		var seen := str(checked["trees"].get(docs_set["id"], ""))
		if seen == "":
			continue
		var downloaded: Variant = sets.get(docs_set["id"], {})
		if not downloaded is Dictionary or str(downloaded.get("zip_hash", "")) != seen:
			waiting.append(CandyLocale.t(str(docs_set["title"])))
	return waiting


#* Look at GitHub if due (see the header):
func look_if_due() -> void:
	if _looked or is_busy() or not auto_check() or not has_downloads():
		return
	_looked = true
	var checked: Variant = _record.get("checked", {})
	var last := 0.0
	if checked is Dictionary:
		last = float(checked.get("time", 0.0))
	var elapsed := Time.get_unix_time_from_system() - last
	if elapsed >= 0.0 and elapsed < CHECK_INTERVAL:
		return
	_check(true)


#* Look at GitHub, and say in status_text whether it's newer:
func check() -> void:
	_check(false)


#* Look at GitHub:
func _check(quiet: bool) -> void:
	if is_busy():
		return
	_set_status(State.CHECKING, CandyLocale.t("Checking GitHub…"), false)
	var trees := await _fetch_trees()
	var problems := _remember_trees(trees)
	var waiting := updates_waiting()
	if not waiting.is_empty():
		_set_status(State.IDLE, CandyLocale.t("Updated documentation is available: %s.") % ", ".join(waiting), false)
	elif quiet:			#/ The daily look: only speaks when something newer is found
		_set_status(State.IDLE, "", false)
	elif not problems.is_empty():
		_set_status(State.IDLE, "\n".join(problems), true)
	else:
		_set_status(State.IDLE, CandyLocale.t("The documentation is up to date."), false)


#* Download every set that differs from what's here:
func download() -> void:
	if is_busy():
		return
	_set_status(State.DOWNLOADING, CandyLocale.t("Checking GitHub…"), false)
	var trees := await _fetch_trees()
	var lines: PackedStringArray = _remember_trees(trees)
	var failed := not lines.is_empty()
	var changed := false
	for docs_set: Dictionary in SETS:
		var tree: Dictionary = trees.get(int(docs_set["repository_id"]), {})
		if tree.has("error"):
			continue
		var files := _files_for(docs_set, tree)
		var title := CandyLocale.t(str(docs_set["title"]))
		if files.is_current():
			lines.append(CandyLocale.t("%s is up to date.") % title)
			continue
		_set_status(State.DOWNLOADING, CandyLocale.t("Downloading %s…") % title, false)
		await files.fetch(_source)
		if files.problem != "":
			lines.append(files.problem)
			failed = true
			continue
		if not files.changes_something() and _sets().has(docs_set["id"]):
			lines.append(CandyLocale.t("%s is up to date.") % title)
			_record_set(docs_set, files)
			continue
		var error := files.apply()
		if error != "":
			lines.append(CandyLocale.t("{set}: {error}").format({"set": title, "error": error}))
			failed = true
			continue
		changed = true
		_record_set(docs_set, files)
		var line := CandyLocale.t("%s was downloaded.") % title
		if not files.changed_here.is_empty():
			var count := files.changed_here.size()
			line = CandyLocale.tn("{set} was downloaded. {count} file changed here was replaced; a copy is in {folder}.", "{set} was downloaded. {count} files changed here were replaced; copies are in {folder}.", count)
			line = line.format({"set": title, "count": count, "folder": ProjectSettings.globalize_path(files.backup_folder)})
		lines.append(line)
	if changed:
		rescan()
	_set_status(State.IDLE, "\n".join(lines), failed)


#* Clear the status:
func clear_status() -> void:
	if not is_busy() and status_text != "":
		_set_status(State.IDLE, "", false)


#& Internals

#* Fetch each repository's files once: { repository id: fetch_tree() answer }:
func _fetch_trees() -> Dictionary:
	var trees := {}
	for docs_set: Dictionary in SETS:
		var repo_id := int(docs_set["repository_id"])
		if trees.has(repo_id):
			continue
		trees[repo_id] = await _source.fetch_tree(str(docs_set["repository"]), repo_id, str(docs_set["branch"]))
	return trees


#* Remember each set's zip hash, for updates_waiting():
func _remember_trees(trees: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	var seen := {}
	var complete := true
	for repo_id: int in trees:
		if trees[repo_id].has("error"):
			problems.append(str(trees[repo_id]["error"]))
			complete = false
	for docs_set: Dictionary in SETS:
		var tree: Dictionary = trees.get(int(docs_set["repository_id"]), {})
		if tree.has("error"):
			continue
		seen[docs_set["id"]] = str(tree.get("files", {}).get(CandyDocsFiles.zip_path_of(docs_set), ""))
	#% A failed look isn't kept:
	if complete:
		_record["checked"] = {"time": Time.get_unix_time_from_system(), "trees": seen}
		_save()
	return problems			#/ One per repository


func _files_for(docs_set: Dictionary, tree: Dictionary) -> CandyDocsFiles:
	var files := CandyDocsFiles.new()
	files.docs_set = docs_set
	files.tree = tree
	files.target_folder = DATABASES_FOLDER
	files.backups_folder = BACKUPS_FOLDER
	files.extensions = EXTENSIONS
	var recorded: Variant = _sets().get(docs_set["id"], {})
	if recorded is Dictionary:
		files.recorded = recorded
	return files


#* Keep a set's record from what it downloaded (files.record), or as the zip it found matches:
func _record_set(docs_set: Dictionary, files: CandyDocsFiles) -> void:
	var sets := _sets()
	if files.record.is_empty():
		var kept: Variant = sets.get(docs_set["id"], {})
		if not kept is Dictionary:
			return
		kept["zip_hash"] = files.zip_hash
		kept["commit"] = files.tree["commit"]
		kept["files"] = files.upstream.duplicate()
		sets[docs_set["id"]] = kept
	else:
		sets[docs_set["id"]] = files.record
	_record["sets"] = sets
	_save()


#* The downloaded sets' records, by set id:
func _sets() -> Dictionary:
	var sets: Variant = _record.get("sets", {})
	if sets is Dictionary:
		return sets
	return {}


func _set_status(new_state: State, text: String, failed: bool) -> void:
	state = new_state
	status_text = text
	status_failed = failed
	status_changed.emit()


func _save() -> void:
	CandyVariantFile.write(STATE_FILE, _record)
