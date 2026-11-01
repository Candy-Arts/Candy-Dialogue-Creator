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

#^ An action's key was pressed, in window:
signal triggered(action_id: String, window: Window)
#^ The keys changed (the setting, or the generated actions):
signal shortcuts_changed

const SETTING := "shortcuts"

const SCOPE_WINDOW := "window"
const SCOPE_NAVIGATOR := "navigator"
const SCOPE_SPEECH := "speech"

const GROUP_GENERAL := "General"	#/ translatable
const GROUP_LAYOUT := "Windows & Layouts"	#/ translatable
const GROUP_NAVIGATOR := "Navigator"	#/ translatable
const GROUP_EDITOR := "Editor"	#/ translatable
const GROUP_COMMANDS := "Commands"	#/ translatable
const GROUP_PRESETS := "Presets"	#/ translatable
const GROUP_INSERTS := "Inserts"	#/ translatable
#^ The Settings pages, in order (see CandySettingsPages):
const GROUPS := [GROUP_GENERAL, GROUP_LAYOUT, GROUP_NAVIGATOR, GROUP_EDITOR,
	GROUP_COMMANDS, GROUP_PRESETS, GROUP_INSERTS]

const LINE_PREFIX := "line:"
const PRESET_PREFIX := "preset:"
const INSERT_PREFIX := "insert:"

#^ The built-in actions ("run" is added in _ready() for those run here):
const BUILT_IN := [
	#% General:
	{"id": "undo", "group": GROUP_GENERAL, "default": ["Ctrl+Z"],
		"label": "Undo",	#/ translatable
		"tooltip": "Undo the last dialogue edit. In a text field, Ctrl+Z undoes the typing instead."},	#/ translatable
	{"id": "redo", "group": GROUP_GENERAL, "default": ["Ctrl+Y", "Ctrl+Shift+Z"],
		"label": "Redo"},	#/ translatable
	{"id": "new_dialogue", "group": GROUP_GENERAL, "default": ["Ctrl+N"],
		"label": "New Dialogue",	#/ translatable
		"tooltip": "Asks first, like File > New Dialogue."},	#/ translatable
	{"id": "load", "group": GROUP_GENERAL, "default": ["Ctrl+O"],
		"label": "Load Dialogue..."},	#/ translatable
	{"id": "save", "group": GROUP_GENERAL, "default": ["Ctrl+S"],
		"label": "Save"},	#/ translatable
	{"id": "save_as", "group": GROUP_GENERAL, "default": ["Ctrl+Shift+S"],
		"label": "Save As..."},	#/ translatable
	{"id": "save_incremental", "group": GROUP_GENERAL, "default": ["Ctrl+Alt+S"],
		"label": "Save Incremental"},	#/ translatable
	{"id": "quick_save", "group": GROUP_GENERAL, "default": ["F5"],
		"label": "Quick Save"},	#/ translatable
	{"id": "quick_load", "group": GROUP_GENERAL, "default": ["F9"],
		"label": "Quick Load",	#/ translatable
		"tooltip": "Loads the newest quick save, after asking."},	#/ translatable
	{"id": "export", "group": GROUP_GENERAL, "default": ["Ctrl+E"],
		"label": "Export Dialogue..."},	#/ translatable
	{"id": "import", "group": GROUP_GENERAL, "default": ["Ctrl+I"],
		"label": "Import Dialogue..."},	#/ translatable
	{"id": "test", "group": GROUP_GENERAL, "default": ["F6"],
		"label": "Test",	#/ translatable
		"tooltip": "Export and test the dialogue in the Godot editor, like the top bar's Test button."},	#/ translatable
	{"id": "test_export", "group": GROUP_GENERAL, "default": ["Ctrl+F6"],
		"label": "Export Test Dialogue",	#/ translatable
		"tooltip": "Only export the test dialogue, like Ctrl+Click on Test."},	#/ translatable
	{"id": "refresh", "group": GROUP_GENERAL, "default": ["Ctrl+R"],
		"label": "Refresh",	#/ translatable
		"tooltip": "Rescan the Godot project's folders."},	#/ translatable
	{"id": "settings", "group": GROUP_GENERAL, "default": ["Ctrl+Comma"],
		"label": "Settings..."},	#/ translatable
	#% Windows & Layouts:
	{"id": "edit_layout", "group": GROUP_LAYOUT, "default": ["Ctrl+L"],
		"label": "Edit Layout",	#/ translatable
		"tooltip": "Turn Edit Layout on or off."},	#/ translatable
	{"id": "new_window", "group": GROUP_LAYOUT, "default": ["Ctrl+Shift+N"],
		"label": "New Window"},	#/ translatable
	{"id": "reset_layout", "group": GROUP_LAYOUT, "default": [],
		"label": "Reset Layout"},	#/ translatable
	{"id": "quick_layout_next", "group": GROUP_LAYOUT, "default": [],
		"label": "Next Quick Layout",	#/ translatable
		"tooltip": "Load the next of the quick layouts chosen in Settings > UI > Layouts."},	#/ translatable
	{"id": "quick_layout_previous", "group": GROUP_LAYOUT, "default": [],
		"label": "Previous Quick Layout"},	#/ translatable
	#% Navigator:
	{"id": "nav_cut", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Ctrl+X"],
		"label": "Cut"},	#/ translatable
	{"id": "nav_copy", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Ctrl+C"],
		"label": "Copy"},	#/ translatable
	{"id": "nav_paste", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Ctrl+V"],
		"label": "Paste"},	#/ translatable
	{"id": "nav_duplicate", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Ctrl+D"],
		"label": "Duplicate"},	#/ translatable
	{"id": "nav_delete", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Delete"],
		"label": "Delete"},	#/ translatable
	{"id": "nav_rename", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["F2"],
		"label": "Rename",	#/ translatable
		"tooltip": "Rename the selected conversation or block."},	#/ translatable
	{"id": "nav_select_all", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Ctrl+A"],
		"label": "Select All Lines",	#/ translatable
		"tooltip": "Select every line of the selected blocks."},	#/ translatable
	{"id": "nav_up", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Up"],
		"label": "Select Previous Row"},	#/ translatable
	{"id": "nav_down", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Down"],
		"label": "Select Next Row"},	#/ translatable
	{"id": "nav_extend_up", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Shift+Up"],
		"label": "Extend Selection Up"},	#/ translatable
	{"id": "nav_extend_down", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Shift+Down"],
		"label": "Extend Selection Down"},	#/ translatable
	{"id": "nav_previous_block", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Ctrl+Up"],
		"label": "Select Previous Block"},	#/ translatable
	{"id": "nav_next_block", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Ctrl+Down"],
		"label": "Select Next Block"},	#/ translatable
	{"id": "nav_move_up", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Alt+Up"],
		"label": "Move Lines Up"},	#/ translatable
	{"id": "nav_move_down", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Alt+Down"],
		"label": "Move Lines Down"},	#/ translatable
	{"id": "nav_test_here", "group": GROUP_NAVIGATOR, "scope": SCOPE_NAVIGATOR, "default": ["Shift+F6"],
		"label": "Test Here",	#/ translatable
		"tooltip": "Test from the selected line, block or conversation."},	#/ translatable
	#% Editor:
	{"id": "line_previous", "group": GROUP_EDITOR, "default": ["Alt+PageUp"],
		"label": "Previous Line",	#/ translatable
		"tooltip": "Open the line before the one being edited, in the Navigators and Editors last used."},	#/ translatable
	{"id": "line_next", "group": GROUP_EDITOR, "default": ["Alt+PageDown"],
		"label": "Next Line"},	#/ translatable
	{"id": "editor_previous_tab", "group": GROUP_EDITOR, "default": ["Ctrl+PageUp"],
		"label": "Previous Tab",	#/ translatable
		"tooltip": "The line UI's previous tab, in the Dialogue Editors last used."},	#/ translatable
	{"id": "editor_next_tab", "group": GROUP_EDITOR, "default": ["Ctrl+PageDown"],
		"label": "Next Tab"},	#/ translatable
	{"id": "variation_previous", "group": GROUP_EDITOR, "default": [],
		"label": "Previous Variation",	#/ translatable
		"tooltip": "Pick the previous variation in the Variation Selectors of the Dialogue Editors last used."},	#/ translatable
	{"id": "variation_next", "group": GROUP_EDITOR, "default": [],
		"label": "Next Variation"},	#/ translatable
	{"id": "edit_tags", "group": GROUP_EDITOR, "scope": SCOPE_SPEECH, "default": ["Shift+Enter", "Shift+Kp Enter"],
		"label": "Edit Tags",	#/ translatable
		"tooltip": "In an Advanced Speech Editor: edit the tags around the caret in the popup above the text, and go back to the text."},	#/ translatable
]

#^ Actions added with register_action(), in order:
var _registered: Array = []
#^ id -> definition, of every action (built-in, registered and generated):
var _actions: Dictionary = {}
#^ Key code with modifiers -> action id:
var _lookup: Dictionary = {}
var _dirty := true
#^ What claim() handed out during the current trigger:
var _claims: Dictionary = {}
#^ The quick layout the Next / Previous Quick Layout actions loaded last:
var _quick_layout_index := -1


func _ready() -> void:
	CandyProfiles.profile_opened.connect(func(_user: String, _profile: String): _mark_dirty())
	CandyProfiles.settings_changed.connect(func(key: String):
		if key == SETTING:
			_mark_dirty())
	CandyInserts.inserts_changed.connect(_mark_dirty)
	CandyInserts.insert_deleted.connect(_on_insert_deleted)
	CandyDialogue.dialogue_changed.connect(_on_presets_maybe_changed)
	CandyDialogue.blocks_renamed.connect(_on_blocks_renamed)


#* Add (or replace) a mod's or panel's action:
#? definition: see the header; "run" is optional (listen to triggered() instead).
func register_action(definition: Dictionary) -> void:
	for i in _registered.size():
		if _registered[i]["id"] == definition["id"]:
			_registered[i] = definition
			_mark_dirty()
			return
	_registered.append(definition)
	_mark_dirty()


#& Actions

#* List every action, in display order:
func actions() -> Array:
	_ensure_built()
	return _actions.values()


#* List one Settings page's actions, in display order:
func actions_in(group: String) -> Array:
	var result: Array = []
	for action in actions():
		if str(action["group"]) == group:
			result.append(action)
	return result


func get_action(id: String) -> Dictionary:
	_ensure_built()
	return _actions.get(id, {})


func label_of(id: String) -> String:
	return str(get_action(id).get("label", id))


#* Get an action's keys, from settings (a "shortcuts" dictionary, the profile's if null), else its defaults:
func keys_of(id: String, settings: Variant = null) -> Array:
	if settings == null:
		settings = CandyProfiles.get_setting(SETTING, {})
	if settings is Dictionary and settings.get(id) is Array:
		return (settings[id] as Array).duplicate()
	return (get_action(id).get("default", []) as Array).duplicate()


#* Get an action's keys as a tooltip shows them, "Ctrl+Y, Ctrl+Shift+Z" ("" if none):
func keys_text(id: String) -> String:
	if id == "" or not CandyProfiles.is_profile_open():
		return ""
	var shown := PackedStringArray()
	for key in keys_of(id):
		var text := normalized(str(key))
		if text != "":
			shown.append(text)
	return ", ".join(shown)


#* Add an action's keys to a button's tooltip, "Shortcut: F6" on a line of its own:
func with_keys(tooltip: String, id: String) -> String:
	var keys := keys_text(id)
	if keys == "":
		return tooltip
	var line := CandyLocale.t("Shortcut: %s") % keys
	if keys.contains(", "):
		line = CandyLocale.t("Shortcuts: %s") % keys
	if tooltip == "":
		return line
	return tooltip + "\n" + line


#* Show the keys of a menu's actions, right of its items:
#? items: { item id: action id }.
#! Call as the menu opens (about_to_popup).
func show_keys_in(menu: PopupMenu, items: Dictionary) -> void:
	for item_id in items:
		var index := menu.get_item_index(int(item_id))
		if index < 0:
			continue
		menu.set_item_shortcut(index, _shortcut_of(str(items[item_id])))
		#? Display only, so a key runs its action once, through here.
		menu.set_item_shortcut_disabled(index, true)


#* Make a Shortcut of an action's keys:
func _shortcut_of(id: String) -> Shortcut:
	if not CandyProfiles.is_profile_open():
		return null
	var events: Array = []
	for key in keys_of(id):
		var code: int = OS.find_keycode_from_string(normalized(str(key)))
		if code == KEY_NONE:
			continue
		var event := InputEventKey.new()
		event.keycode = (code & KEY_CODE_MASK) as Key
		event.ctrl_pressed = (code & KEY_MASK_CTRL) != 0
		event.shift_pressed = (code & KEY_MASK_SHIFT) != 0
		event.alt_pressed = (code & KEY_MASK_ALT) != 0
		event.meta_pressed = (code & KEY_MASK_META) != 0
		events.append(event)
	if events.is_empty():
		return null			#/ An empty Shortcut would read "None"
	var shortcut := Shortcut.new()
	shortcut.events = events
	return shortcut


#* Get the action holding key in settings (as keys_of()), "" if none:
func action_with_key(key: String, settings: Variant = null, except: String = "") -> String:
	for action in actions():
		var id := str(action["id"])
		if id != except and keys_of(id, settings).has(key):
			return id
	return ""


#* Get a key event as stored ("Ctrl+Shift+Z"):
func key_text(event: InputEventKey) -> String:
	var keycode := event.keycode
	if keycode == KEY_NONE:
		keycode = event.physical_keycode
	if keycode == KEY_NONE or keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
		return ""			#/ Can't be a shortcut alone
	var with_modifiers: int = keycode
	if event.ctrl_pressed:
		with_modifiers |= KEY_MASK_CTRL
	if event.shift_pressed:
		with_modifiers |= KEY_MASK_SHIFT
	if event.alt_pressed:
		with_modifiers |= KEY_MASK_ALT
	if event.meta_pressed:
		with_modifiers |= KEY_MASK_META
	return OS.get_keycode_string(with_modifiers as Key)


#* Normalize a stored key, so hand-written ones ("ctrl+z") read like the rest:
static func normalized(key: String) -> String:
	var code := OS.find_keycode_from_string(key.strip_edges())
	if code == KEY_NONE:
		return ""
	return OS.get_keycode_string(code)


#& Matching

#* Run a key's window-scope action, from CandyAreaHost (true if one ran):
func handle_window_event(event: InputEvent, window: Window) -> bool:
	var id := _match(event, SCOPE_WINDOW)
	if id == "":
		return false
	run(id, window)
	return true


#* Get a key's navigator-scope action ("" if none). The Navigator runs it:
func navigator_action(event: InputEvent) -> String:
	return _match(event, SCOPE_NAVIGATOR)


#* Get a key's speech-scope action ("" if none). The Advanced Speech Editor runs it:
func speech_action(event: InputEvent) -> String:
	return _match(event, SCOPE_SPEECH)


func _match(event: InputEvent, scope: String) -> String:
	var key := event as InputEventKey
	if key == null or not key.pressed or not CandyProfiles.is_profile_open():
		return ""
	_ensure_built()
	var id := str(_lookup.get(key_text(key), ""))
	if id == "" or str(_actions[id].get("scope", SCOPE_WINDOW)) != scope:
		return ""
	#% Held keys only repeat moves (Navigator, Editor's lines and variations) and undo / redo:
	if key.echo and not _repeats(id):
		return ""
	return id


func _repeats(id: String) -> bool:
	return id in ["nav_up", "nav_down", "nav_extend_up", "nav_extend_down", "nav_previous_block",
		"nav_next_block", "nav_move_up", "nav_move_down", "line_previous", "line_next",
		"variation_previous", "variation_next", "undo", "redo"]


#* Run an action - its "run" Callable, then triggered():
func run(id: String, window: Window = null) -> void:
	var action := get_action(id)
	if action.is_empty():
		return
	_claims.clear()
	if action.get("run") is Callable:
		(action["run"] as Callable).call()
	triggered.emit(id, window)


#* Claim key for the current trigger (true the first time only):
#? For panels sharing what they act on (Variation Selectors with one reference), so it moves once.
func claim(key: String) -> bool:
	if _claims.has(key):
		return false
	_claims[key] = true
	return true


#& Building

func _mark_dirty() -> void:
	_dirty = true
	shortcuts_changed.emit()


func _ensure_built() -> void:
	if not _dirty:
		return
	_dirty = false
	_actions.clear()
	for definition in BUILT_IN:
		var action: Dictionary = definition.duplicate(true)
		var runner := _built_in_runner(str(action["id"]))
		if runner.is_valid():
			action["run"] = runner
		_add(action)
	for definition in _registered:
		_add(definition.duplicate())
	_add_generated()

	_lookup.clear()
	var settings = CandyProfiles.get_setting(SETTING, {})
	for id in _actions:
		for key in keys_of(str(id), settings):
			var text := normalized(str(key))
			if text != "" and not _lookup.has(text):
				_lookup[text] = id


func _add(action: Dictionary) -> void:
	if not action.has("scope"):
		action["scope"] = SCOPE_WINDOW
	if not action.has("default"):
		action["default"] = []
	_actions[str(action["id"])] = action


#* Add one action per line type, preset and insert, keyless by default:
func _add_generated() -> void:
	for type in CandySchemas.line_types():
		var category := CandySchemas.get_category(str(type))
		_add({
			"id": LINE_PREFIX + str(type),
			"label": CandyLocale.t("Add %s") % CandyLocale.command_title(CandySchemas.get_title(str(type))),
			"group": GROUP_COMMANDS,
			"section": category,
			"tooltip": CandyLocale.t("Add a %s line after the selection.") % type,
			"run": CandyDialogue.add_lines.bind(str(type), false),
		})
	for preset_id in CandyPresets.all_ids():
		var path := CandyPresets.id_path(str(preset_id))
		var section := CandyLocale.t("User Presets")
		var category := CandyPresets.category_of(str(preset_id))
		if category != "":
			section = CandyLocale.t("User Presets: %s") % category
		if path[0] == CandyDialogue.PROFILE_PRESETS:
			section = CandyLocale.t("Profile Presets")
			if category != "":
				section = CandyLocale.t("Profile Presets: %s") % category
		_add({
			"id": PRESET_PREFIX + str(preset_id),
			"label": CandyPresets.button_label(str(preset_id)),
			"group": GROUP_PRESETS,
			"section": section,
			"tooltip": CandyLocale.t("Insert this preset's lines after the selection."),
			"run": CandyDialogue.insert_preset.bind(str(path[0]), str(path[1]), false),
		})
	for insert_id in CandyInserts.all_ids():
		var insert := CandyInserts.get_insert(str(insert_id))
		var insert_label := str(insert.get("label", insert_id))
		var insert_section := str(insert.get("category", ""))
		#% Built-in inserts' names are translated, the user's never:
		if insert.get("type", "") == CandyInserts.TYPE_NATIVE:
			insert_label = CandyLocale.t(insert_label)
			insert_section = CandyLocale.t(insert_section)
		_add({
			"id": INSERT_PREFIX + str(insert_id),
			"label": insert_label,
			"group": GROUP_INSERTS,
			"section": insert_section,
			"tooltip": CandyLocale.t("Type this insert into the field being typed in."),
			"run": CandyInserts.apply.bind(str(insert_id)),
		})


#* Get a built-in action's Callable (empty for those a panel runs, see triggered()):
func _built_in_runner(id: String) -> Callable:
	match id:
		"undo":
			return _undo.bind(true)
		"redo":
			return _undo.bind(false)
		"load":
			return CandySaves.open_load_dialog
		"save":
			return CandySaves.save.bind(-1)
		"save_as":
			return CandySaves.save_as.bind(-1)
		"save_incremental":
			return CandySaves.save_incremental
		"quick_save":
			return CandySaves.quick_save
		"quick_load":
			return CandySaves.ask_quick_load
		"test":
			return _test.bind(false)
		"test_export":
			return _test.bind(true)
		"refresh":
			return CandyResources.scan
		"edit_layout":
			return func(): CandyLayout.set_editing(not CandyLayout.is_editing())
		"new_window":
			return func(): CandyLayout.open_window()
		"reset_layout":
			return CandyLayout.reset_layout
		"quick_layout_next":
			return _step_quick_layout.bind(1)
		"quick_layout_previous":
			return _step_quick_layout.bind(-1)
		"line_next":
			return _step_line.bind(1)
		"line_previous":
			return _step_line.bind(-1)
	return Callable()


#& Built-in actions

#* Undo or redo, committing the text being typed first, like the Undo button:
func _undo(undoing: bool) -> void:
	CandyLayout.release_focus()
	if undoing:
		CandyDialogue.undo()
	else:
		CandyDialogue.redo()


func _test(export_only: bool) -> void:
	if not CandyTestRun.is_running():
		CandyTestRun.run(CandyTestRun.saved_start(), export_only)


func _step_quick_layout(step: int) -> void:
	var layouts := CandyLayoutLibrary.quick_layouts()
	if layouts.is_empty():
		return
	_quick_layout_index = wrapi(_quick_layout_index + step, 0, layouts.size())
	var data := CandyLayoutLibrary.read(str(layouts[_quick_layout_index]["path"])).duplicate(true)
	if CandyLayout.apply_layout_data(data):
		CandyLayout.save_layout()


#* Open the line before or after the active line, across blocks and conversations:
func _step_line(step: int) -> void:
	var active := CandyDialogue.active_path_of(CandyDialogue.current_reference)
	if not CandyDialogue.is_line_path(active):
		return
	active = CandyDialogue.root_line_path(active)
	var conversation := str(active[0])
	#? Presets and the dialogue are stepped through apart.
	var conversations := CandyDialogue.conversation_names()
	if CandyDialogue.is_preset_conversation(conversation):
		conversations = CandyDialogue.preset_conversation_names()
	var paths: Array = []
	for each in conversations:
		for block in CandyDialogue.block_names(str(each)):
			for i in CandyDialogue.lines(str(each), str(block)).size():
				paths.append([str(each), str(block), i])
	var index := paths.find(active)
	if index < 0 or index + step < 0 or index + step >= paths.size():
		return
	var target: Array = paths[index + step]
	#Ł Select it alone:
	CandyDialogue.set_selection([target])
	CandyDialogue.set_active_path(target)


#& Following the data

#* Rebuild if presets were added, removed or renamed:
func _on_presets_maybe_changed() -> void:
	var count := 0
	for id in _actions:
		if str(id).begins_with(PRESET_PREFIX):
			count += 1
	if _dirty or count != CandyPresets.all_ids().size():
		_mark_dirty()
	else:
		#Ł Renamed presets keep their count - check the ids:
		for preset_id in CandyPresets.all_ids():
			if not _actions.has(PRESET_PREFIX + str(preset_id)):
				_mark_dirty()
				return


#* Move a renamed preset's keys to its new id:
func _on_blocks_renamed(renames: Array) -> void:
	var settings = CandyProfiles.get_setting(SETTING, {})
	if not settings is Dictionary or settings.is_empty():
		return
	var updated: Dictionary = settings.duplicate(true)
	var changed := false
	for id in settings:
		if not str(id).begins_with(PRESET_PREFIX):
			continue
		var preset_id := str(id).substr(PRESET_PREFIX.length())
		var new_id := CandyPresets.renamed_id(preset_id, renames)
		if new_id != "" and new_id != preset_id:
			updated.erase(id)
			updated[PRESET_PREFIX + new_id] = settings[id]
			changed = true
	if changed:
		CandyProfiles.set_setting(SETTING, updated)


#* Remove a deleted insert's keys:
func _on_insert_deleted(id: String) -> void:
	var settings = CandyProfiles.get_setting(SETTING, {})
	if settings is Dictionary and settings.has(INSERT_PREFIX + id):
		var updated: Dictionary = settings.duplicate(true)
		updated.erase(INSERT_PREFIX + id)
		CandyProfiles.set_setting(SETTING, updated)
