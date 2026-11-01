#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationSelectorWidget
extends CandyAreaWidget

const VARIATIONS_FIELD := "Variations"

var _list: CandyVariationList
var _title: Label
var _message: Label
var _settings: CandyVariationSelectorSettings
var _data: CandyVariationData
var _line_path: Array = []
#^ Languages whose sub-variations are collapsed (kept in config):
var _folded: Dictionary = {}
#^ The ids of the rows listed, in order, for the shortcuts:
var _row_ids: Array = []


#* Needs the line's Variations:
func fits_line_type(_config: Dictionary, line_type: String) -> bool:
	return has_top_field(line_type, VARIATIONS_FIELD)


func _on_configured() -> void:
	#? A draft with nothing pending reads the profile, the database the settings pages write.
	_data = CandyVariationData.new(CandySettingsDraft.new())
	_read_folded()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme_type_variation = CandyThemeDefaults.COMPACT_VBOX
	add_child(root)

	var header := HBoxContainer.new()
	header.visible = CandyVariantFile.to_bool(config.get("show_header", true), true)
	root.add_child(header)

	_title = Label.new()
	header.add_child(_title)

	_message = CandyChecks.new_message_label()
	header.add_child(_message)

	var settings_button := Button.new()
	settings_button.text = "..."
	settings_button.focus_mode = Control.FOCUS_NONE
	settings_button.tooltip_text = CandyLocale.t("Reference and filters")
	settings_button.pressed.connect(_open_settings)
	header.add_child(settings_button)

	_list = CandyVariationList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.show_guides = true
	_list.row_pressed.connect(_on_row_pressed)
	_list.fold_pressed.connect(_on_fold_pressed)
	root.add_child(_list)

	var shared := selection()
	if shared != null:
		shared.changed.connect(_on_selection_changed)
	#? Languages and tags edited in Settings, written when the window closes.
	CandyProfiles.settings_changed.connect(_on_setting_changed)
	CandyShortcuts.triggered.connect(_on_shortcut)


func bind_line(line_path: Array) -> void:
	_line_path = line_path.duplicate()
	_rebuild()
	_show_checks()


#* Show the Variations checks beside the title:
func _show_checks() -> void:
	if _message == null or not CandyDialogue.is_line_path(_line_path):
		return
	var line := CandyDialogue.line_at(_line_path)
	var line_type := CandyDialogue.line_type(line)
	var spec := {}
	for field in CandySchemas.field_specs(line_type, CandyDialogue.line_data(line)):
		if field is Dictionary and str(field.get("id", "")) == VARIATIONS_FIELD:
			spec = field
	var check_context := CandyCheckContext.new("", spec)
	check_context.checks_value = false
	check_context.line_type = line_type
	check_context.line_path = _line_path
	check_context.field_path = [VARIATIONS_FIELD]
	check_context.data = CandyDialogue.get_field(_line_path, [VARIATIONS_FIELD], [])
	CandyChecks.show_messages(_message, CandyChecks.messages(spec, check_context))


#& Rows

func _rebuild() -> void:
	if _list == null:
		return
	_title.text = CandyLocale.t("Variations")

	var custom := _filtered_tags()
	var randoms: Array = []
	if not bool(config.get("hide_randoms", false)):
		randoms = _data.random_tags()
	var disabled := _data.disabled()
	var tag_variations := CandyVariations.ordered_tag_variations(custom, randoms, disabled)
	var existing := _existing_variations()
	var show_tts := not bool(config.get("hide_tts", false))

	var rows: Array = []
	for entry in _data.languages():
		if bool(entry.get("hidden", false)):
			continue  #/ A language the translator switched off
		var language := str(entry.get("name", ""))
		if disabled.has(language):
			continue

		var folded := _folded.has(language)
		rows.append({
			"id": language,
			"text": language,
			"indent": 0,
			"foldable": true,
			"folded": folded,
			"disableable": false,
			"muted": not existing.has(language),
		})
		if folded:
			continue
		if show_tts:
			rows.append(_tts_row(language, 1, existing))

		for tags in tag_variations:
			var variation_name = language + CandyVariations.SEPARATOR + tags
			if disabled.has(variation_name):
				continue
			rows.append({
				"id": variation_name,
				"text": tags,
				"indent": 1,
				"disableable": false,
				"muted": not existing.has(variation_name),
			})
			if show_tts:
				rows.append(_tts_row(variation_name, 2, existing))

	_list.set_rows(rows)
	_row_ids.clear()
	for row in rows:
		_row_ids.append(str(row["id"]))
	var shared := selection()
	if shared != null:
		_list.selected_id = shared.get_selected(reference())


#* The TTS twin of a variation, listed right under it:
func _tts_row(variation_name: String, indent: int, existing: Dictionary) -> Dictionary:
	var tts_name = CandyVariations.tts_of(variation_name)
	return {
		"id": tts_name,
		"text": CandyVariations.TTS_TAG,
		"indent": indent,
		"disableable": false,
		"muted": not existing.has(tts_name),
	}


#* Variation names the line already holds text for:
func _existing_variations() -> Dictionary:
	var result := {}
	if not CandyDialogue.is_line_path(_line_path):
		return result
	var variations = CandyDialogue.get_field(_line_path, [VARIATIONS_FIELD], [])
	if not variations is Array:
		return result
	for entry in variations:
		if entry is Dictionary and entry.size() > 0:
			result[str(entry.keys()[0])] = true
	return result


#* Custom tags minus those filtered out ("S" alone drops every value of S):
func _filtered_tags() -> Array:
	var hidden_tags = config.get("hidden_tags", [])
	if not hidden_tags is Array or hidden_tags.is_empty():
		return _data.custom_tags()

	var result: Array = []
	for tag in _data.custom_tags():
		var text := str(tag)
		if hidden_tags.has(text) or hidden_tags.has(CandyVariations.tag_key(text)):
			continue
		result.append(text)
	return result


#& Input

func _on_row_pressed(id: String) -> void:
	var shared := selection()
	if shared == null:
		return
	shared.select(reference(), id)
	_list.selected_id = id


#* Previous / Next Variation - pick the row before / after, in the Editors of the view used last:
func _on_shortcut(action_id: String, _window: Window) -> void:
	var step := 0
	if action_id == "variation_next":
		step = 1
	elif action_id == "variation_previous":
		step = -1
	var shared := selection()
	if step == 0 or shared == null or _row_ids.is_empty() or not _in_current_editor():
		return
	#% Selectors sharing a reference move it once:
	if not CandyShortcuts.claim("variation:%d:%s" % [shared.get_instance_id(), reference()]):
		return
	var index := _row_ids.find(shared.get_selected(reference()))
	if index < 0:
		index = 0
	else:
		index = clampi(index + step, 0, _row_ids.size() - 1)
	_on_row_pressed(str(_row_ids[index]))


#* Whether a Dialogue Editor it sits in edits the line of the view used last:
func _in_current_editor() -> bool:
	if not is_visible_in_tree():
		return false
	var node := get_parent()
	while node != null:
		if node is CandyDialogueEditorPanel and (node as CandyDialogueEditorPanel).is_current():
			return true
		node = node.get_parent()
	return false


func _on_fold_pressed(language: String) -> void:
	if _folded.has(language):
		_folded.erase(language)
	else:
		_folded[language] = true
	_write_folded()
	_rebuild()


func _on_selection_changed(changed_reference: String, variation_name: String) -> void:
	if changed_reference == reference():
		_list.selected_id = variation_name


func _on_setting_changed(key: String) -> void:
	if key == CandyVariationData.DATA_KEY:
		_rebuild()


func has_settings() -> bool:
	return true


func open_settings() -> void:
	_open_settings()


func _open_settings() -> void:
	if _settings == null:
		_settings = CandyVariationSelectorSettings.new()
		_settings.applied.connect(_on_settings_applied)
		add_child(_settings)
	_settings.open(config, _data.custom_tags())


func _on_settings_applied(new_config: Dictionary) -> void:
	var merged := config.duplicate(true)
	for key in new_config:
		merged[key] = new_config[key]
	save_config(merged)
	_read_folded()
	_rebuild()


func _read_folded() -> void:
	_folded = {}
	var folded = config.get("folded", [])
	if folded is Array:
		for language in folded:
			_folded[str(language)] = true


func _write_folded() -> void:
	var merged := config.duplicate(true)
	merged["folded"] = _folded.keys()
	save_config(merged)