#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyShortcutsPage
extends CandySettingsPage

const KEY_SLOTS := 2
const KEY_BUTTON_WIDTH := 150
const NO_KEY_TEXT := "-"

const NOTES := {
	CandyShortcuts.GROUP_GENERAL: "These work in every window, except while a text field uses the key: in a text field, Ctrl+Z undoes the typing.",		#/ translatable
	CandyShortcuts.GROUP_LAYOUT: "These work in every window. The quick layouts are chosen in Settings > UI > Layouts.",		#/ translatable
	CandyShortcuts.GROUP_NAVIGATOR: "These work while a Dialogue Navigator has the focus: click it first. They act on its selection.",		#/ translatable
	CandyShortcuts.GROUP_EDITOR: "These act on the Dialogue Editors of the Navigator clicked last.",		#/ translatable
	CandyShortcuts.GROUP_COMMANDS: "Each adds a line of its command after the selection, in the Navigator clicked last.",		#/ translatable
	CandyShortcuts.GROUP_PRESETS: "Each inserts its preset's lines after the selection, in the Navigator clicked last.",		#/ translatable
	CandyShortcuts.GROUP_INSERTS: "Each types its insert into the text field being typed in.",		#/ translatable
}

var group: String = ""

#^ Action id -> its key buttons:
var _key_buttons: Dictionary = {}
var _capture: CandyShortcutCaptureDialog


static func for_group(p_group: String) -> CandyShortcutsPage:
	var page := CandyShortcutsPage.new()
	page.group = p_group
	return page


func build() -> void:
	_capture = CandyShortcutCaptureDialog.new()
	add_child(_capture)

	if NOTES.has(group):
		add_note(CandyLocale.t(str(NOTES[group])))
	var reset_page := Button.new()
	reset_page.text = CandyLocale.t("Reset Page")
	reset_page.focus_mode = Control.FOCUS_NONE
	reset_page.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset_page.tooltip_text = CandyLocale.t("Give every shortcut of this page its default keys back.")
	reset_page.pressed.connect(_reset_page)
	add_custom(reset_page)

	var actions := CandyShortcuts.actions_in(group)
	if actions.is_empty():
		add_note(CandyLocale.t("Nothing here yet."))
		return
	var section := ""
	for action in actions:
		var action_section := str(action.get("section", ""))
		if action_section != section:
			section = action_section
			if section != "":
				add_heading(_shown(action, "section"))
		_add_action_row(action)


func _add_action_row(action: Dictionary) -> void:
	var id := str(action["id"])
	var row := HBoxContainer.new()
	add_custom(row)

	var label := Label.new()
	label.text = _shown(action, "label")
	label.tooltip_text = _shown(action, "tooltip")
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = LABEL_WIDTH
	label.clip_text = true
	row.add_child(label)

	var buttons: Array = []
	for slot in KEY_SLOTS:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size.x = KEY_BUTTON_WIDTH
		button.tooltip_text = CandyLocale.t("Click, then press the key.")
		button.pressed.connect(_on_key_pressed.bind(id, slot))
		row.add_child(button)
		buttons.append(button)
	_key_buttons[id] = buttons

	var reset := Button.new()
	reset.text = CandyLocale.t("Reset")
	reset.focus_mode = Control.FOCUS_NONE
	reset.tooltip_text = _defaults_tooltip(action)
	reset.pressed.connect(_reset.bind([id]))
	row.add_child(reset)


func _defaults_tooltip(action: Dictionary) -> String:
	var defaults: Array = action.get("default", [])
	if defaults.is_empty():
		return CandyLocale.t("Back to no key.")
	return CandyLocale.t("Back to: %s") % ", ".join(PackedStringArray(defaults))


#* Get an action's label, tooltip or section as shown:
func _shown(action: Dictionary, key: String) -> String:
	var text := str(action.get(key, ""))
	var id := str(action.get("id", ""))
	if id.begins_with(CandyShortcuts.LINE_PREFIX):
		if key == "section":
			return CandyLocale.t(text)
		return text
	if id.begins_with(CandyShortcuts.PRESET_PREFIX) or id.begins_with(CandyShortcuts.INSERT_PREFIX):
		return text
	return CandyLocale.t(text)


func refresh() -> void:
	super.refresh()
	var settings := _settings()
	for id in _key_buttons:
		var keys := CandyShortcuts.keys_of(str(id), settings)
		var buttons: Array = _key_buttons[id]
		for slot in buttons.size():
			var button: Button = buttons[slot]
			if slot < keys.size():
				button.text = str(keys[slot])
			else:
				button.text = NO_KEY_TEXT


#& Editing

func _settings() -> Dictionary:
	return draft.get_dictionary(CandyShortcuts.SETTING)


func _on_key_pressed(id: String, slot: int) -> void:
	var settings := _settings()
	var keys := CandyShortcuts.keys_of(id, settings)
	var current := ""
	if slot < keys.size():
		current = str(keys[slot])
	_capture.open(_shown(CandyShortcuts.get_action(id), "label"), current, settings, id,
		func(key: String): _set_key(id, slot, key))


#* Give a slot's key to the action, taking it from any other ("" removes it):
func _set_key(id: String, slot: int, key: String) -> void:
	var settings := _settings()
	var keys := CandyShortcuts.keys_of(id, settings)
	if slot < keys.size():
		keys[slot] = key
	elif key != "":
		keys.append(key)
	var cleaned: Array = []
	for each in keys:
		if str(each) != "" and not cleaned.has(each):
			cleaned.append(each)
	_store(settings, id, cleaned)
	if key != "":
		_take_from_others(settings, [key], id)
	_save(settings)


func _reset(ids: Array) -> void:
	var settings := _settings()
	for id in ids:
		settings.erase(id)
	#Ł Take default keys back from other actions:
	for id in ids:
		_take_from_others(settings, CandyShortcuts.keys_of(str(id), settings), str(id))
	_save(settings)


func _reset_page() -> void:
	var ids: Array = []
	for action in CandyShortcuts.actions_in(group):
		ids.append(str(action["id"]))
	_reset(ids)


func _take_from_others(settings: Dictionary, keys: Array, except: String) -> void:
	for key in keys:
		var holder := CandyShortcuts.action_with_key(str(key), settings, except)
		while holder != "":
			var others := CandyShortcuts.keys_of(holder, settings)
			others.erase(key)
			_store(settings, holder, others)
			holder = CandyShortcuts.action_with_key(str(key), settings, except)


#* Store an action's keys (not stored when equal to its defaults):
func _store(settings: Dictionary, id: String, keys: Array) -> void:
	var defaults: Array = CandyShortcuts.get_action(id).get("default", [])
	if keys == defaults:
		settings.erase(id)
	else:
		settings[id] = keys


func _save(settings: Dictionary) -> void:
	draft.replace_dictionary(CandyShortcuts.SETTING, settings)
	refresh()
