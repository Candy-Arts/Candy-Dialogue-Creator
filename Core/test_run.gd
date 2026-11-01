#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyTestRun
extends RefCounted

const START_KEY := "test_start"
const START_FIELDS := ["Scene", "Conversation", "Block", "Line"]
const DATA_FOLDER := ".godot"
#^ The data folder's name when project.godot asks for a visible one:
const VISIBLE_DATA_FOLDER := "godot"
const FOLDER_NAME := "candy_wizard"
const REQUEST_FILE := "test_request.json"
const RESPONSE_FILE := "test_response.json"
const FORMAT := 1
const ANSWER_SECONDS := 3.0
const POLL_SECONDS := 0.1

enum State { WAITING, STARTED, EXPORTED, FAILED }


#^ Emits state_changed(State) as a run goes:
#! A scene tree node, freed with it: a static-only object outlives the scripts at exit,
#! and a lambda still connected to it crashes Godot.
class Notifier:
	extends Node
	signal state_changed(state: int)


static var _notifier: Notifier = null
#^ One run at a time (a click while waiting is ignored):
static var _running := false


static func notifier() -> Notifier:
	if _notifier == null or not is_instance_valid(_notifier):
		_notifier = Notifier.new()
		_notifier.name = "CandyTestRunNotifier"
		#? Deferred - the root may be busy adding the main scene.
		(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_notifier)
	return _notifier


static func is_running() -> bool:
	return _running


#& Starting point

#* Get the Test button's start from the profile (every START_FIELDS key, as a String):
static func saved_start() -> Dictionary:
	var start := {}
	var stored = CandyProfiles.get_setting(START_KEY, {})
	for field in START_FIELDS:
		start[field] = ""
		if stored is Dictionary:
			start[field] = str(stored.get(field, "")).strip_edges()
	return start


static func save_start(start: Dictionary) -> void:
	var stored := {}
	for field in START_FIELDS:
		stored[field] = str(start.get(field, "")).strip_edges()
	if stored != saved_start():
		CandyProfiles.set_setting(START_KEY, stored)


#* Describe a start, e.g. "Intro › Start › line 3, in Test.tscn":
static func describe_start(start: Dictionary) -> String:
	var parts: PackedStringArray = []
	parts.append(_or_first(str(start.get("Conversation", "")), CandyLocale.t("first conversation")))
	parts.append(_or_first(str(start.get("Block", "")), CandyLocale.t("first block")))
	parts.append(CandyLocale.t("line %s") % _or_first(str(start.get("Line", "")), "0"))
	var scene := _or_first(str(start.get("Scene", "")), CandyLocale.t("Candy Wizard's testing scene"))
	return CandyLocale.t("{start}, in {scene}").format({"start": " › ".join(parts), "scene": scene})


static func _or_first(value: String, empty_text: String) -> String:
	if value == "":
		return empty_text
	return value


#* Get a start's scene as a res:// path ("" for Candy Wizard's):
static func scene_path(start: Dictionary) -> String:
	var scene := str(start.get("Scene", "")).strip_edges()
	if scene == "" or scene.begins_with("res://"):
		return scene
	#% A name without res:// is in the Testing scenes folder:
	var root := CandyResources.project_root().trim_suffix("/")
	var path := CandyResources.resource_folder("Testing_Scenes").path_join(scene)
	if root != "" and path.begins_with(root + "/"):
		return "res://" + path.trim_prefix(root + "/")
	return path


#& Running

#* Export the dialogue, then ask the Godot editor to test it from start:
#? export_only: just the export (Ctrl+Click on Test).
static func run(start: Dictionary, export_only: bool = false) -> void:
	if _running:
		return
	#Ł Commit the text being typed (Test doesn't take the focus):
	CandyLayout.commit_typing()
	#% The profile's symbols changed - the dialogue is updated first, or nothing is tested:
	if CandyProfiles.is_profile_open() and not CandyDialogue.symbols_match():
		var tree := Engine.get_main_loop() as SceneTree
		CandySymbolPrompt.ensure_dialogue(tree.root, CandyLocale.t("testing it"), run.bind(start, export_only))
		return
	var problem := CandyDialogueExport.test_export()
	if problem != "":
		_finish(State.FAILED, CandyLocale.t("Test export failed"), problem)
		return
	if export_only:
		_finish(State.EXPORTED)
		return

	var folder := _exchange_folder()
	if folder == "":
		_finish(State.FAILED, CandyLocale.t("Test not started"), CandyLocale.t("The dialogue was exported, but the project has no %s folder yet: open the project in the Godot editor first.\n\n(Ctrl+Click Test to export only.)") % _data_folder(_project_root()))
		return
	var request := {
		"format": FORMAT,
		"id": "%d-%d" % [Time.get_ticks_usec(), randi()],
		"sent": Time.get_unix_time_from_system(),
		"dialogue_file": CandyDialogueExport.test_path(),
		"scene": scene_path(start),
		"conversation": str(start.get("Conversation", "")),
		"block": str(start.get("Block", "")),
		"line": str(start.get("Line", "")),
	}
	var response_path := folder.path_join(RESPONSE_FILE)
	DirAccess.remove_absolute(response_path)
	problem = _write_atomically(folder.path_join(REQUEST_FILE), JSON.stringify(request))
	if problem != "":
		_finish(State.FAILED, CandyLocale.t("Test not started"), problem)
		return

	_running = true
	notifier().state_changed.emit(State.WAITING)
	var answer := await _wait_for_answer(response_path, str(request["id"]))
	_running = false
	if answer.is_empty():
		#% Unanswered - it mustn't start a test once the editor opens:
		DirAccess.remove_absolute(folder.path_join(REQUEST_FILE))
		_finish(State.FAILED, CandyLocale.t("Test not started"), CandyLocale.t("The dialogue was exported, but the Godot editor didn't answer.\n\nOpen the project in the Godot editor, with Candy Wizard enabled.\n\n(Ctrl+Click Test to export only.)"))
	elif str(answer.get("status", "")) != "started":
		_finish(State.FAILED, CandyLocale.t("Test not started"), CandyLocale.t("The dialogue was exported, but Candy Wizard couldn't test it:\n\n%s") % str(answer.get("message", "")))
	else:
		_finish(State.STARTED)


#* Wait for Candy Wizard's answer to this id ({} if none came in time):
static func _wait_for_answer(response_path: String, id: String) -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	var waited := 0.0
	while waited < ANSWER_SECONDS:
		await tree.create_timer(POLL_SECONDS).timeout
		waited += POLL_SECONDS
		if not FileAccess.file_exists(response_path):
			continue
		var answer = JSON.parse_string(FileAccess.get_file_as_string(response_path))
		DirAccess.remove_absolute(response_path)
		if answer is Dictionary and str(answer.get("id", "")) == id:
			return answer
	return {}


static func _finish(state: int, title_text: String = "", message: String = "") -> void:
	notifier().state_changed.emit(state)
	if message != "":
		CandySaves.show_error(title_text, message)


#* Get <project>/.godot/candy_wizard:
static func _exchange_folder() -> String:
	var root := _project_root()
	var data_folder := _data_folder(root)
	if root == "" or not DirAccess.dir_exists_absolute(root.path_join(data_folder)):
		return ""			#/ No root, or never opened in the editor
	return root.path_join(data_folder).path_join(FOLDER_NAME)


static func _project_root() -> String:
	return str(CandyProfiles.get_setting(CandyDialogueExport.ROOT_KEY, "")).strip_edges()


#* Get the data folder's name, as project.godot says (".godot" or "godot"):
static func _data_folder(root: String) -> String:
	var project := ConfigFile.new()
	if root == "" or project.load(root.path_join("project.godot")) != OK:
		return DATA_FOLDER
	if bool(project.get_value("application", "config/use_hidden_project_data_directory", true)):
		return DATA_FOLDER
	return VISIBLE_DATA_FOLDER


static func _write_atomically(path: String, text: String) -> String:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return CandyLocale.t("Can't write the file:\n{path}\n({error})").format({"path": temporary_path, "error": error_string(FileAccess.get_open_error())})
	file.store_string(text)
	file.close()
	var error := DirAccess.rename_absolute(temporary_path, path)
	if error != OK:
		return CandyLocale.t("Can't write the file:\n{path}\n({error})").format({"path": path, "error": error_string(error)})
	return ""
