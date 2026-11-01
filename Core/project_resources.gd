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

signal resources_scanned

#^ Every key of project_resources:
#? All but the last three are filled from the custom_project_paths folder of the same key;
#? node lists are read from the scenes, Project_Scenes from the whole project.
const RESOURCE_KEYS := [
	"*Portraits", "*Busts", "*Voice_Files", "*Sprites",
	"Backgrounds", "Images", "Audio", "Videos", "Effects",
	"BG_Scenes", "VN_Scenes", "Player_Input_Scenes",
	"Choice_Menu_Scenes", "Choice_Category_Scenes", "Choice_Button_Scenes",
	"Dialogue_UI_Scenes", "Dialogue_Box_Scenes", "Subtitles_Scenes",
	"Speech_Bubble_2D_Scenes", "Speech_Bubble_3D_Scenes", "Bark_2D_Scenes", "Bark_3D_Scenes",
	"History_Menu_Scenes", "Image_Player_Scenes",
	"Chat_Box_Scenes", "Chat_Channel_Scenes", "Chat_Line_Scenes", "Chat_Separator_Scenes",
	"Testing_Scenes", "Dialogue_Modes",
	"BG_Layer_Nodes", "VN_Bust_Nodes", "Project_Scenes",
]
const SKIPPED_EXTENSIONS := ["import", "uid"]
const ALL_KEY := "All"

#^ The Speech Inserts tables, keyed in the INSERT_TABLES_KEY setting:
#? { "Script": path, "Variable": name } each.
const INSERT_TABLES_KEY := "speech_insert_scripts"
const LEXICON := "Lexicon"
const TEXT_EVENTS := "Text_Events"

var project_resources: Dictionary = {}

#^ The Lexicon's keywords and text events' names by variation pattern, read at each scan:
#/   { LEXICON: { "*": ["Alice"], "Default*": ["Alice", "_June"] }, TEXT_EVENTS: { ... } }
#? Names only (see speech_insert_names()).
var speech_insert_tables: Dictionary = {}

var _scan_queued := false


func _ready() -> void:
	_reset()
	CandySchemas.register_type_provider("media_player", media_player_types)
	CandySchemas.register_value_provider("portrait_kind", portrait_kind)
	CandyProfiles.profile_opened.connect(func(_user: String, _profile: String): _queue_scan())
	CandyProfiles.profile_closed.connect(func():
		_reset()
		resources_scanned.emit())
	CandyProfiles.settings_changed.connect(func(key: String):
		if key == "project_path" or key == "custom_project_paths" or key == INSERT_TABLES_KEY:
			_queue_scan())


#* Queue one scan at the end of the frame (several settings can change at once):
func _queue_scan() -> void:
	if _scan_queued:
		return
	_scan_queued = true
	(func():
		_scan_queued = false
		if CandyProfiles.is_profile_open():
			scan()).call_deferred()


func _reset() -> void:
	project_resources = {}
	for key in RESOURCE_KEYS:
		project_resources[key] = {}
	speech_insert_tables = {LEXICON: {}, TEXT_EVENTS: {}}


#* Rescan everything, with the profile's settings or the given unsaved ones:
func scan(project_path: String = "", custom_paths: Dictionary = {}) -> int:
	if project_path == "":
		project_path = str(CandyProfiles.get_setting("project_path", ""))
	if custom_paths.is_empty():
		var stored = CandyProfiles.get_setting("custom_project_paths", {})
		if stored is Dictionary:
			custom_paths = stored

	_reset()
	var count := 0
	if project_path != "" and DirAccess.dir_exists_absolute(project_path):
		for key in custom_paths:
			if not project_resources.has(key):
				continue  #/ E.g. "Dialogues", not a resource list
			var folder_path := _resolve(project_path, str(custom_paths[key]))
			if folder_path == "" or not DirAccess.dir_exists_absolute(folder_path):
				continue
			if str(key).begins_with("*"):
				count += _scan_character_folder(project_resources[key], folder_path)
			else:
				count += _scan_folder_recursive(project_resources[key], folder_path)

		_collect_nodes("BG_Scenes", "BG_Layer_Nodes", "bg_container")
		_collect_nodes("VN_Scenes", "VN_Bust_Nodes", "busts_container")
		_scan_scenes(project_resources["Project_Scenes"], project_path)
		_read_insert_tables(project_path)

	for key in project_resources:
		project_resources[key] = _sorted(project_resources[key])
	resources_scanned.emit()
	return count			#/ Files found


#* Resolve a folder - relative ones are under the project root:
func _resolve(project_path: String, folder: String) -> String:
	if folder == "":
		return ""
	if folder.is_absolute_path():
		return folder
	return project_path.path_join(folder)


#& Paths

#* Get the project root (the folder holding project.godot), or "":
func project_root() -> String:
	return str(CandyProfiles.get_setting("project_path", ""))


#* Get a custom_project_paths key's folder ("*Portraits"...) as a file system path:
func resource_folder(key: String) -> String:
	var paths = CandyProfiles.get_setting("custom_project_paths", {})
	if not paths is Dictionary:
		return ""
	var root := project_root()
	if root == "":
		return ""
	return _resolve(root, str(paths.get(key, "")))


#* Check whether a value is a res:// or user:// path:
func is_project_path(value: String) -> bool:
	return value.begins_with("res://") or value.begins_with("user://")


#* Convert the Godot project's res:// or user:// path to a file system path:
func to_file_path(value: String) -> String:
	if value.begins_with("res://"):
		var root := project_root()
		if root == "":
			return ""
		return root.path_join(value.substr("res://".length()))
	if value.begins_with("user://"):
		var user_dir := project_user_dir()
		if user_dir == "":
			return ""
		return user_dir.path_join(value.substr("user://".length()))
	return value			#/ Other values as they are


#* Get where the Godot project's user:// is on this computer:
func project_user_dir() -> String:
	var root := project_root()
	var settings_file := root.path_join("project.godot")
	if root == "" or not FileAccess.file_exists(settings_file):
		return ""
	var project := ConfigFile.new()
	if project.load(settings_file) != OK:
		return ""
	var data_dir := OS.get_data_dir()
	if bool(project.get_value("application", "config/use_custom_user_dir", false)):
		var custom := str(project.get_value("application", "config/custom_user_dir_name", ""))
		if custom != "":
			return data_dir.path_join(custom)			#/ Its custom user folder
	var project_name := str(project.get_value("application", "config/name", ""))
	if project_name == "":
		return ""
	return _app_userdata_dir().path_join(project_name)			#/ app_userdata/<project name>


#* Get Godot's shared app_userdata folder:
func _app_userdata_dir() -> String:
	if not bool(ProjectSettings.get_setting("application/config/use_custom_user_dir", false)):
		return OS.get_user_data_dir().get_base_dir()			#/ Candy DC's own user:// is inside it
	#? Godot's naming: "godot" in lowercase on Linux and BSD.
	var godot_folder := "Godot"
	if OS.get_name() == "Linux" or OS.get_name().ends_with("BSD"):
		godot_folder = "godot"
	return OS.get_data_dir().path_join(godot_folder).path_join("app_userdata")


#& Speech inserts

#* Read the Lexicon and the text events table into speech_insert_tables:
func _read_insert_tables(project_path: String) -> void:
	var stored = CandyProfiles.get_setting(INSERT_TABLES_KEY, {})
	if not stored is Dictionary:
		return
	for table in [LEXICON, TEXT_EVENTS]:
		var entry = stored.get(table, {})
		if not entry is Dictionary:
			continue
		var script_path := _resolve(project_path, str(entry.get("Script", "")))
		var tables := CandyProjectScripts.read_nested_keys(script_path, str(entry.get("Variable", "")))
		var names := {}
		for pattern in tables:
			var sorted: Array = Array(tables[pattern])
			sorted.sort_custom(func(a, b): return str(a).naturalnocasecmp_to(str(b)) < 0)
			names[pattern] = sorted
		speech_insert_tables[table] = names


#* List the names of a speech_insert_tables table a variation can use:
func speech_insert_names(table: String, variation: String) -> Array:
	var entries = speech_insert_tables.get(table, {})
	if not entries is Dictionary:
		return []
	return names_matching(entries, variation)			#/ Matched as Candy DE matches them (variation_matches()): case-sensitive


#* List the names of the entries ({ pattern = [names] }) matching variation:
func names_matching(entries: Dictionary, variation: String) -> Array:
	var result: Array = []
	for pattern in entries:
		if not variation_matches(str(pattern), variation):
			continue
		for entry_name in entries[pattern]:
			if not result.has(str(entry_name)):
				result.append(str(entry_name))
	result.sort_custom(func(a, b): return str(a).naturalnocasecmp_to(str(b)) < 0)
	return result


#* Check whether a Lexicon / text event pattern matches a variation:
func variation_matches(pattern: String, variation: String) -> bool:
	if pattern == "*":
		return true
	if pattern.ends_with("*"):
		return variation.begins_with(pattern.trim_suffix("*"))
	return pattern == variation


#& Dialogue modes

#^ The dialogue modes Candy DE ships, in menu order:
const BUILT_IN_DIALOGUE_MODES := ["Box", "Subtitles", "Chat", "Bubbles", "VN_Bubbles", "Barks", "Voice"]


#* List the project's dialogue modes, from its Dialogue_Modes folder (sub-folders included):
func dialogue_modes() -> Array:
	var found: Array = []
	_collect_script_names(project_resources.get("Dialogue_Modes", {}), found)			#/ Named like the file ("Phone.gd" -> "Phone")
	#Ł Built-in ones first, in BUILT_IN_DIALOGUE_MODES' order:
	var modes: Array = []
	for mode in BUILT_IN_DIALOGUE_MODES:
		if mode in found:
			modes.append(mode)
	for mode in found:
		if not mode in modes:
			modes.append(mode)
	return modes


func _collect_script_names(folder: Variant, names: Array) -> void:
	if not folder is Dictionary:
		return
	for entry_name in folder:
		if folder[entry_name] is Dictionary:
			_collect_script_names(folder[entry_name], names)
		elif str(entry_name).get_extension() == "gd":
			var mode := str(entry_name).get_basename()
			if not mode in names:
				names.append(mode)
	names.sort()


#& Media players

#^ Media folders by player type - a player's files are in a folder named after it inside one:
const MEDIA_PLAYER_FOLDERS := {"audio": "Audio", "video": "Videos", "image": "Images"}


#^ Each type's name for menus, in menu order (alphabetical):
const MEDIA_TYPE_LABELS := {"audio": "Audio", "image": "Image", "video": "Video"}	#/ translatable


#* Get a media player's types ("Music" -> ["audio"]), from the folders with its subfolder:
func media_player_types(player_name: String) -> Array:
	var types: Array = []
	for type in MEDIA_PLAYER_FOLDERS:
		var folder = project_resources.get(MEDIA_PLAYER_FOLDERS[type], {})
		if folder is Dictionary and folder.get(player_name) is Dictionary:
			types.append(type)
	return types			#/ [] when none has it (a ¢ expression), several when several have


#* List one media type's players ("audio" -> ["Ambient", "Music"...]), its folder's subfolders:
func media_players(type: String) -> Array:
	var players: Array = []
	var folder = project_resources.get(str(MEDIA_PLAYER_FOLDERS.get(type, "")), {})
	if not folder is Dictionary:
		return players
	for entry_name in folder:
		if folder[entry_name] is Dictionary:
			players.append(str(entry_name))
	return players


#* Get one player's folder of a media type, as project_resources holds it:
func media_player_folder(type: String, player_name: String) -> Dictionary:
	var folder = project_resources.get(str(MEDIA_PLAYER_FOLDERS.get(type, "")), {})
	if folder is Dictionary and folder.get(player_name) is Dictionary:
		return folder[player_name]			#/ { file_name: full_path, subfolder: { ... } }
	return {}


#& Spoken line media

const DEFAULT_VARIATION := "Default"
#^ Candy DE's voice_logic and voice_path, for a Candy_Properties.gd without them:
const DEFAULT_VOICE_LOGIC := "Folder"
const DEFAULT_VOICE_PATH := "{actor}/{dialogue}/{conversation}/{block}"
#^ The setting holding the project's Candy_Properties.gd path (Project > Paths, or Symbols):
const PROPERTIES_SCRIPT_KEY := "symbol_script_path"
const REGEX_SPECIAL := "\\^$.|?*+()[]{}"


#? A Spoken_Line's portrait is found by CandyPortraitMedia.resolve().


#* Value provider "portrait_kind" - a Spoken_Line portrait's media kind:
#? See CandySchemas.register_value_provider().
func portrait_kind(read: Callable) -> String:
	var found_kind := CandyPortraitMedia.kind_of({
		"Portrait": read.call("Portrait"),
		"Reference": read.call("Reference"),
		"Sprite_Frames_File": read.call("Sprite_Frames_File"),
	})
	if found_kind == "":
		return "null"			#/ Only the game can tell
	return found_kind


#* Get a Spoken_Line variation's voice file ("" if none; TTS variations never have one):
func voice_path(line_path: Array, data: Dictionary, variation: String) -> String:
	if CandyVariations.is_tts(variation):
		return ""
	var value := str(data.get("Voice", "")).strip_edges()
	if value == "":
		return ""
	if is_project_path(value):			#/ res:// or user:// path: the Default file, other variations in subfolders beside it
		var default_file := to_file_path(value)
		return _variation_file(default_file.get_base_dir(), default_file.get_file(), variation)

	#% A file name, found through the "Folder" voice_logic (voice_folders()):
	#? Without an extension, used as is: the game sets the extension, the Creator never guesses.
	var actor := voice_actor(str(data.get("Reference", "")))
	var root := resource_folder("*Voice_Files")
	if actor == "" or root == "" or line_path.size() < 2:
		return ""			#/ A speaker the Creator can't name (°role, ¢ expression) has no file
	var candidates: Array = []
	for found in voice_folders(line_path, actor):
		candidates.append(_variation_file(root.path_join("/".join(found[0])), value, variation))			#/ <*Voice_Files folder>/<voice_path>/(<variation>/)<file>
	for candidate in candidates:
		if FileAccess.file_exists(candidate):
			return candidate			#/ The first holding the file
	if not candidates.is_empty():
		return candidates[0]			#/ Else the first path, to show where it looked
	#% No folder matches - where Candy DE would look, without tags only the game knows ({dialogue}):
	var folder := root
	for segment in _voice_segments():
		var filled := _fill_voice_tags(segment, line_path, actor, true)
		if filled.strip_edges() != "":
			folder = folder.path_join(filled)
	return _variation_file(folder, value, variation)


#* Get a speaker as a voice folder name:
func voice_actor(reference: String) -> String:
	var actor := reference.strip_edges()
	for symbol_key in ["role", "expression"]:
		var symbol := CandyDropdowns.symbol(symbol_key)
		if symbol != "" and actor.begins_with(symbol):
			return ""			#/ °role or ¢ expression: only the game knows the actor
	return actor


#* Find the *Voice_Files folders holding a Spoken_Line's voices, per the "Folder" voice_logic:
func voice_folders(line_path: Array, actor: String) -> Array:
	var matches: Array = []
	var root = project_resources.get("*Voice_Files", {})
	if not root is Dictionary or line_path.size() < 2:
		return matches
	if properties_value("voice_logic", DEFAULT_VOICE_LOGIC) != DEFAULT_VOICE_LOGIC:
		return matches			#/ [] for another voice_logic
	_walk_voice_folders(root, _voice_segments(), 0, line_path, actor, [], matches)			#/ voice_path: the project's Candy_Properties.gd, else Candy DE's default
	return matches			#/ [[path in the voice folder: Array of folder names, folder: Dictionary as project_resources holds it], ...]


#* Read a String variable of the project's Candy_Properties.gd, as text, or fallback:
func properties_value(variable: String, fallback: String) -> String:
	var script_path := str(CandyProfiles.get_setting(PROPERTIES_SCRIPT_KEY, ""))
	if script_path == "":
		return fallback
	var root := project_root()
	if not script_path.is_absolute_path():
		if root == "":
			return fallback
		script_path = root.path_join(script_path)
	var value := CandyProjectScripts.read_string(script_path, variable)
	if value == "":
		return fallback
	return value


func _voice_segments() -> PackedStringArray:
	return properties_value("voice_path", DEFAULT_VOICE_PATH).split("/", false)


#* Fill the tags a line gives in a voice_path segment:
func _fill_voice_tags(segment: String, line_path: Array, actor: String, drop_open: bool) -> String:
	var line_number := ""
	if line_path.size() > 2:
		line_number = str(line_path[2])			#/ {line}: from 0, a nested line's is its block line's, as in Candy DE
	var tags := {"{actor}": actor, "{dialogue}": "", "{conversation}": str(line_path[0]), "{block}": str(line_path[1]), "{line}": line_number}
	for tag in tags:
		if str(tags[tag]) != "" or drop_open:			#/ drop_open: remove the tags it doesn't give ({dialogue}, an unknown {actor})
			segment = segment.replace(tag, str(tags[tag]))
	return segment


#* Follow voice_path's segments down the folder tree, adding each folder reached to matches:
func _walk_voice_folders(folder: Dictionary, segments: PackedStringArray, index: int,
		line_path: Array, actor: String, path: Array, matches: Array) -> void:
	if index >= segments.size():
		matches.append([path, folder])
		return
	var segment := _fill_voice_tags(segments[index], line_path, actor, false)
	var open_tags: Array = []
	for tag in ["{actor}", "{dialogue}", "{conversation}", "{block}", "{line}"]:
		if segment.contains(tag):
			open_tags.append(tag)

	if open_tags.is_empty():
		if folder.get(segment) is Dictionary:
			_walk_voice_folders(folder[segment], segments, index + 1, line_path, actor, path + [segment], matches)
		return

	#% Any folder matches an open tag ({dialogue}, only the game knows it; {actor} when actor is ""):
	var pattern := _tag_pattern(segment, open_tags)
	for entry_name in folder:
		if folder[entry_name] is Dictionary and pattern.search(str(entry_name)) != null:
			_walk_voice_folders(folder[entry_name], segments, index + 1, line_path, actor,
				path + [str(entry_name)], matches)
	#? Candy DE leaves out a tag with no value, and a folder made of nothing else.
	#? As for {dialogue} when a dialogue wasn't loaded from a file.
	var rest := segment
	for tag in open_tags:
		rest = rest.replace(tag, "")
	if rest.strip_edges() == "":
		_walk_voice_folders(folder, segments, index + 1, line_path, actor, path, matches)


#* Turn a segment with open tags into a pattern (each tag matches any part of a name):
func _tag_pattern(segment: String, open_tags: Array) -> RegEx:
	var text := "^"
	var rest := segment
	while rest != "":
		var first := -1
		var first_tag := ""
		for tag in open_tags:
			var at := rest.find(tag)
			if at >= 0 and (first < 0 or at < first):
				first = at
				first_tag = tag
		if first < 0:
			text += _escape_regex(rest)
			break
		text += _escape_regex(rest.substr(0, first)) + ".+"
		rest = rest.substr(first + first_tag.length())
	return RegEx.create_from_string(text + "$")


func _escape_regex(text: String) -> String:
	var escaped := ""
	for character in text:
		if REGEX_SPECIAL.contains(character):
			escaped += "\\"
		escaped += character
	return escaped


#* Get a variation's voice file in folder:
func _variation_file(folder: String, file_name: String, variation: String) -> String:
	if variation == "" or variation == DEFAULT_VARIATION:
		return folder.path_join(file_name)
	return folder.path_join(variation.replace(":", "=")).path_join(file_name)			#/ Non-Default: a subfolder named after it, ":" written "=", like Candy DE


#& Folders

#* Scan a character folder, one entry per actor subfolder:
func _scan_character_folder(target: Dictionary, folder_path: String) -> int:
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return 0
	var count := 0
	for actor in dir.get_directories():
		target[actor] = {}
		count += _scan_folder_recursive(target[actor], folder_path.path_join(actor))
	return count


func _scan_folder_recursive(target: Dictionary, folder_path: String) -> int:
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return 0
	var count := 0
	for subfolder in dir.get_directories():
		target[subfolder] = {}
		count += _scan_folder_recursive(target[subfolder], folder_path.path_join(subfolder))
	for file_name in dir.get_files():
		if SKIPPED_EXTENSIONS.has(file_name.get_extension().to_lower()):
			continue
		target[file_name] = folder_path.path_join(file_name)
		count += 1
	return count


#* Collect every .tscn under folder_path, keeping only folders holding one:
func _scan_scenes(target: Dictionary, folder_path: String) -> void:
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return
	for subfolder in dir.get_directories():
		var subfolder_path := folder_path.path_join(subfolder)
		if subfolder.begins_with(".") or FileAccess.file_exists(subfolder_path.path_join(".gdignore")):			#/ Like Godot: hidden folders (.godot, .git), folders with a .gdignore
			continue
		var scenes := {}
		_scan_scenes(scenes, subfolder_path)
		if not scenes.is_empty():
			target[subfolder] = scenes
	for file_name in dir.get_files():
		if file_name.get_extension().to_lower() == "tscn":
			target[file_name] = folder_path.path_join(file_name)


#& Scene nodes

#* List, per scene at the top of scenes_key, the children of its container_variable node:
func _collect_nodes(scenes_key: String, nodes_key: String, container_variable: String) -> void:
	var scenes: Dictionary = project_resources[scenes_key]
	var nodes: Dictionary = project_resources[nodes_key]
	for scene_name in scenes:
		var scene_path = scenes[scene_name]
		if not scene_path is String:
			continue  #/ A subfolder
		var children := _container_children(scene_path, container_variable)
		nodes[scene_name] = children
		#Ł Every name under "All" too:
		if not nodes.has(ALL_KEY):
			nodes[ALL_KEY] = []
		for child in children:
			if not nodes[ALL_KEY].has(child):
				nodes[ALL_KEY].append(child)


#* Read a .tscn as text for the children of its container node:
func _container_children(scene_path: String, container_variable: String) -> Array:
	var children: Array = []
	if not FileAccess.file_exists(scene_path):
		return children
	var content := FileAccess.get_file_as_string(scene_path)

	#@ Step 1 - Find `<container_variable> = NodePath("...")`:
	var path_regex := RegEx.new()
	path_regex.compile(container_variable + "\\s*=\\s*NodePath\\(\"([^\"]+)\"\\)")
	var found := path_regex.search(content)
	if found == null:
		return children
	var parent_attribute := "parent=\"%s\"" % found.get_string(1)

	#@ Step 2 - Then the nodes whose parent is that path:
	var name_regex := RegEx.new()
	name_regex.compile("name=\"([^\"]+)\"")
	for line in content.split("\n"):
		if line.begins_with("[node") and line.contains(parent_attribute):
			var node_name := name_regex.search(line)
			if node_name != null:
				children.append(node_name.get_string(1))
	return children


#& Sorting

#* Sort keys and arrays alphabetically, at every level:
func _sorted(value: Variant) -> Variant:
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort()
		var result := {}
		for key in keys:
			result[key] = _sorted(value[key])
		return result
	if value is Array:
		var copy: Array = value.duplicate()
		copy.sort()
		return copy
	return value