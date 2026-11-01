#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVoicePreviewWidget
extends CandyAreaWidget

const SPOKEN_LINE := "Spoken_Line"
const LAYOUTS := ["row", "row_stacked", "rows", "columns"]
const LAYOUT_LABELS := {
	"row": "One row",  #/ translatable
	"row_stacked": "One row, sliders stacked",  #/ translatable
	"rows": "Three rows",  #/ translatable
	"columns": "Buttons stacked, sliders stacked",  #/ translatable
}
const AUDIO_EXTENSIONS := ["mp3", "ogg", "wav"]
#^ The least width of both sliders, seek and volume:
const SLIDER_MIN_WIDTH := 60
const SEPARATION := 4
#^ The field the pick button fills:
const VOICE_FIELD := "Voice"
#^ The fields its pop-up shows, unless its config lists others ("popup_fields"):
const DEFAULT_POPUP_FIELDS: Array = ["Voice", "Enable_Voice", "Await_Voice_Playback", "Sync_Write_Speed_Voice"]

#^ Shared by every Voice Preview for the session, so layout rebuilds don't reset it:
static var _volume: float = 1.0

var _player: AudioStreamPlayer
var _play_button: Button
var _stop_button: Button
#^ Opens the pop-up of the line's voice fields:
var _fields_button: Button
var _fields_popup: CandyFieldsPopup
#^ Picks the line's Voice file:
var _pick_button: CandyFieldPickButton
#^ The voice's file name, or null when hidden (config "file_name"):
var _file_label: Label = null
#^ What fills the widget: the controls, or a column of them and the file name:
var _outer: Control
var _file_place_button: OptionButton
var _show_pick_check: CheckBox
var _show_fields_check: CheckBox
var _seek: HSlider
var _volume_slider: HSlider
#^ Each slider with its icon:
var _seek_row: HBoxContainer
var _volume_row: HBoxContainer
var _seek_icon: TextureRect
var _volume_icon: TextureRect
var _stacked_buttons: Array = []   #/ Buttons as tall as two slider rows
var _root: BoxContainer
var _settings_dialog: ConfirmationDialog
var _reference_edit: LineEdit
var _layout_button: OptionButton
var _sync_check: CheckBox
var _min_size_fields: CandyMinSizeFields
#^ Whether a playback was started and not stopped since, and whether it drives the portrait:
var _started := false
var _synced := false

var _line_path: Array = []
var _loaded_path: String = ""
var _seeking := false


#* Only shows anything on Spoken_Line:
func fits_line_type(_config: Dictionary, line_type: String) -> bool:
	return line_type == SPOKEN_LINE


#* Plays the Group's variation:
func variation_group_config(p_config: Dictionary, refs: Dictionary, _mode: String) -> Variant:
	var result := p_config.duplicate(true)
	result["reference"] = refs["variation"]
	return result


func _on_configured() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = linear_to_db(_volume)
	_player.finished.connect(_on_finished)
	add_child(_player)

	_play_button = _make_button("▶", CandyLocale.t("Play"), _on_play_pressed)
	_stop_button = _make_button("■", CandyLocale.t("Stop"), _on_stop_pressed)
	_fields_button = CandyFieldsPopup.make_button(CandyLocale.t("Voice fields"))
	_fields_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_fields_button.pressed.connect(func(): _fields_popup.open_beside(_fields_button))
	_fields_popup = CandyFieldsPopup.new()
	add_child(_fields_popup)
	_fields_popup.setup(popup_fields(), context)
	_pick_button = CandyFieldPickButton.new(VOICE_FIELD, CandyLocale.t("Pick a voice"))
	_pick_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pick_button.setup(context)
	#Ł Each can be hidden in Options:
	_pick_button.visible = bool(config.get("show_pick", true))
	_fields_button.visible = bool(config.get("show_fields", true))

	_seek = HSlider.new()
	_seek.step = 0.01
	_seek.custom_minimum_size.x = SLIDER_MIN_WIDTH
	_seek.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seek.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_seek.tooltip_text = CandyLocale.t("Position")
	_seek_icon = _make_icon()
	_seek_row = _slider_row(_seek_icon, _seek)
	_seek_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_seek.drag_started.connect(func(): _seeking = true)
	_seek.drag_ended.connect(_on_seek_drag_ended)
	#? Track clicks change the value without a drag signal.
	#? While dragging, only a synced portrait follows; the voice seeks at the end of the drag.
	_seek.value_changed.connect(func(value: float):
		if not _seeking:
			_seek_to(value)
		elif _drives_portrait():
			portrait_sync().seek(value))

	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 1.0
	_volume_slider.step = 0.01
	_volume_slider.value = _volume
	_volume_slider.custom_minimum_size.x = SLIDER_MIN_WIDTH
	_volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_volume_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume_slider.tooltip_text = CandyLocale.t("Volume")
	_volume_slider.value_changed.connect(_on_volume_changed)
	_volume_icon = _make_icon()
	_volume_row = _slider_row(_volume_icon, _volume_slider)
	_update_icons()

	_build_layout(_layout())

	var shared := selection()
	if shared != null:
		shared.changed.connect(func(changed_reference: String, _variation_name: String):
			if changed_reference == reference():
				_refresh())
	CandyProfiles.settings_changed.connect(func(key: String):
		if key == "project_path" or key == "custom_project_paths":
			_refresh())


func bind_line(line_path: Array) -> void:
	_line_path = line_path.duplicate()
	_fields_popup.bind_line(_line_path)
	_pick_button.bind_line(_line_path)
	_refresh()


#* The fields its pop-up shows:
func popup_fields() -> Array:
	var listed = config.get("popup_fields", DEFAULT_POPUP_FIELDS)
	if listed is Array:
		return listed
	return DEFAULT_POPUP_FIELDS


#& Layout

func _layout() -> String:
	var value := str(config.get("layout", "row"))
	if not LAYOUTS.has(value):
		return "row"
	return value


func _make_button(text: String, tooltip: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(handler)
	return button


func _make_icon() -> TextureRect:
	var icon := TextureRect.new()
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	#? Its slider's tooltip, or why nothing plays, comes from what's under it.
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


#* A slider with its icon on the left (the row's size flags set its width):
func _slider_row(icon: TextureRect, slider: HSlider) -> HBoxContainer:
	var row := _box(false) as HBoxContainer
	row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	row.add_child(slider)
	return row


func _update_icons() -> void:
	if _seek_icon == null:
		return
	_seek_icon.texture = get_theme_icon(&"position", CandyThemeDefaults.ICONS)
	_volume_icon.texture = get_theme_icon(&"volume", CandyThemeDefaults.ICONS)


func _build_layout(layout: String) -> void:
	var root: BoxContainer
	match layout:
		"row_stacked":
			root = _box(false)
			root.add_child(_play_button)
			root.add_child(_stop_button)
			root.add_child(_pick_button)
			root.add_child(_fields_button)
			root.add_child(_stack([_seek_row, _volume_row], true))
			_stacked_buttons = [_play_button, _stop_button, _pick_button, _fields_button]
		"rows":
			root = _box(true)
			var buttons := _box(false)
			buttons.add_child(_play_button)
			buttons.add_child(_stop_button)
			buttons.add_child(_pick_button)
			buttons.add_child(_fields_button)
			root.add_child(buttons)
			root.add_child(_seek_row)
			_volume_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			root.add_child(_volume_row)
		"columns":
			root = _box(false)
			root.add_child(_stack([_play_button, _stop_button], false))
			root.add_child(_stack([_seek_row, _volume_row], true))
			root.add_child(_stack([_pick_button, _fields_button], false))
		_:
			root = _box(false)
			root.add_child(_play_button)
			root.add_child(_stop_button)
			root.add_child(_pick_button)
			root.add_child(_fields_button)
			root.add_child(_seek_row)
			root.add_child(_volume_row)
	_root = root
	#Ł The file name above or below the controls:
	var name_place := CandyFieldPickButton.file_name_place(config)
	_outer = root
	if name_place != "hidden":
		var column := _box(true)
		_file_label = CandyFieldPickButton.make_file_label()
		if name_place == "above":
			column.add_child(_file_label)
		column.add_child(root)
		if name_place == "below":
			column.add_child(_file_label)
		_outer = column
	_outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_outer)
	#? The controls' size is this widget's minimum size.
	_outer.minimum_size_changed.connect(update_minimum_size)
	_update_sizes()


func _box(vertical: bool) -> BoxContainer:
	var box: BoxContainer
	if vertical:
		box = VBoxContainer.new()
	else:
		box = HBoxContainer.new()
	box.add_theme_constant_override("separation", SEPARATION)
	return box


func _stack(controls: Array, expand: bool) -> VBoxContainer:
	var column := _box(true) as VBoxContainer
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	if expand:
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for control in controls:
		if expand:
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(control)
	return column


#* Size the controls to one row's height (what a button needs for its text):
func _update_sizes() -> void:
	if _play_button == null:
		return
	var unit := 0.0
	for button in [_play_button, _stop_button, _pick_button, _fields_button]:
		button.custom_minimum_size = Vector2.ZERO
		var natural: Vector2 = button.get_combined_minimum_size()
		unit = maxf(unit, maxf(natural.x, natural.y))
	#Ł Square buttons:
	var side := unit
	for button in [_play_button, _stop_button, _pick_button, _fields_button]:
		side = unit
		#% Beside two stacked sliders - span both rows:
		if _stacked_buttons.has(button):
			side = unit * 2.0 + SEPARATION
		button.custom_minimum_size = Vector2(side, side)
	_seek.custom_minimum_size.y = unit
	_volume_slider.custom_minimum_size.y = unit
	update_minimum_size()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_icons()
		_update_sizes()


func _get_minimum_size() -> Vector2:
	if _outer == null:
		return Vector2.ZERO
	return _outer.get_combined_minimum_size()


#& Playback

func _refresh() -> void:
	if _player == null:
		return
	var line := CandyDialogue.line_at(_line_path)
	if CandyDialogue.line_type(line) != SPOKEN_LINE:
		_show_file_name("", "")
		_set_unavailable(CandyLocale.t("Voices are played for Spoken Lines."))
		return
	var variation := _selected_variation()
	var data := CandyDialogue.line_data(line)
	var path := CandyResources.voice_path(_line_path, data, variation)
	#Ł Its file, or the field's value when no file is known:
	if path != "":
		_show_file_name(path.get_file(), path)
	else:
		_show_file_name(str(data.get(VOICE_FIELD, "")).strip_edges(), "")
	if CandyVariations.is_tts(variation):
		_set_unavailable(CandyLocale.t("TTS variations have no voice file."))
		return
	if path == "":
		if str(data.get("Voice", "")).strip_edges() == "":
			_set_unavailable(CandyLocale.t("This line has no Voice."))
		else:
			_set_unavailable(CandyLocale.t("Set the Speaker to an actor (a role's actor is only known in game), and the Voice files folder in Settings > Project > Paths."))
		return
	if path == _loaded_path:
		return  #/ The same file: keep playing

	_stop()
	if path.get_extension() == "":
		_set_unavailable(CandyLocale.t("No file to preview: a Voice without an extension is only found in game."))
		return
	if not FileAccess.file_exists(path):
		_set_unavailable(CandyLocale.t("Voice file not found:\n%s") % path)
		return
	var stream := CandyMediaTypes.load_audio(path)
	if stream == null:
		_set_unavailable(CandyLocale.t("Can't play this file:\n%s") % path)
		return
	_player.stream = stream
	_loaded_path = path
	_seek.max_value = maxf(stream.get_length(), 0.01)
	_seek.set_value_no_signal(0.0)
	_set_controls_enabled(true)
	tooltip_text = "%s (%s)" % [path, variation]


#* Show the voice's file name, when the widget shows it:
func _show_file_name(text: String, tooltip: String) -> void:
	if _file_label == null:
		return
	_file_label.text = text
	_file_label.tooltip_text = tooltip


func _selected_variation() -> String:
	var shared := selection()
	if shared != null:
		return shared.get_selected(reference())
	return CandyVariationSelection.DEFAULT_VARIATION


func _set_unavailable(reason: String) -> void:
	_stop()
	_player.stream = null
	_loaded_path = ""
	_seek.set_value_no_signal(0.0)
	tooltip_text = reason
	_set_controls_enabled(false)


func _set_controls_enabled(enabled: bool) -> void:
	_play_button.disabled = not enabled
	_stop_button.disabled = not enabled
	_seek.editable = enabled
	if enabled:
		_set_playing_look(false)
		_stop_button.tooltip_text = CandyLocale.t("Stop")
		_seek.tooltip_text = CandyLocale.t("Position")
		return
	#? The controls cover most of the widget, so they carry the reason too.
	for control in [_play_button, _stop_button, _seek]:
		control.tooltip_text = tooltip_text


func _on_play_pressed() -> void:
	if _player.stream == null:
		return
	if _player.playing and not _player.stream_paused:
		_player.stream_paused = true
		_set_playing_look(false)
		if _drives_portrait():
			portrait_sync().pause()
		return
	#? Ctrl plays the other way than the option, for this playback.
	_synced = _sync_option() != Input.is_key_pressed(KEY_CTRL)
	_started = true
	if _player.playing:
		_player.stream_paused = false
	else:
		_player.play(_seek.value)
	_set_playing_look(true)
	if _drives_portrait():
		portrait_sync().play(_seek.value)


func _on_stop_pressed() -> void:
	_stop()


func _stop() -> void:
	if _player == null:
		return
	var synced := _drives_portrait()
	_rewind()
	if synced:
		portrait_sync().stop()


#* Back at the start, not playing, without telling the portrait:
func _rewind() -> void:
	_player.stop()
	_player.stream_paused = false
	_seek.set_value_no_signal(0.0)
	_set_playing_look(false)
	_started = false
	_synced = false


func _sync_option() -> bool:
	return bool(config.get("sync_portrait", false))


#* Whether the voice drives the portrait - the playback's own choice once started, else the option:
func _drives_portrait() -> bool:
	if portrait_sync() == null:
		return false
	if _started:
		return _synced
	return _sync_option()


#* The voice ended (not a Stop - a synced portrait carries on as in game):
func _on_finished() -> void:
	if _drives_portrait():
		portrait_sync().finish()
	_rewind()


func _set_playing_look(playing: bool) -> void:
	if playing:
		_play_button.text = "||"
		_play_button.tooltip_text = CandyLocale.t("Pause")
	else:
		_play_button.text = "▶"
		_play_button.tooltip_text = CandyLocale.t("Play (Ctrl+click: with the portrait)")
		if _sync_option():
			_play_button.tooltip_text = CandyLocale.t("Play with the portrait (Ctrl+click: voice only)")


func _process(_delta: float) -> void:
	if _player != null and _player.playing and not _player.stream_paused and not _seeking:
		_seek.set_value_no_signal(_player.get_playback_position())


func _on_seek_drag_ended(_value_changed: bool) -> void:
	_seeking = false
	_seek_to(_seek.value)


#* Move playback (or where the next Play starts), and a driven portrait with it:
func _seek_to(position_seconds: float) -> void:
	if _player.playing:
		_player.seek(position_seconds)
	if _drives_portrait():
		portrait_sync().seek(position_seconds)


func _on_volume_changed(value: float) -> void:
	_volume = value
	_player.volume_db = linear_to_db(maxf(value, 0.0001))


#& Settings

func has_settings() -> bool:
	return true


func open_settings() -> void:
	if _settings_dialog == null:
		_build_settings_dialog()
	_reference_edit.text = reference()
	_layout_button.select(LAYOUTS.find(_layout()))
	_sync_check.button_pressed = _sync_option()
	_show_pick_check.button_pressed = bool(config.get("show_pick", true))
	_show_fields_check.button_pressed = bool(config.get("show_fields", true))
	_file_place_button.select(maxi(CandyFieldPickButton.FILE_NAME_PLACES.find(CandyFieldPickButton.file_name_place(config)), 0))
	_min_size_fields.load_config(config)
	_settings_dialog.reset_size()
	_settings_dialog.popup_centered()


func _build_settings_dialog() -> void:
	_settings_dialog = ConfirmationDialog.new()
	_settings_dialog.title = CandyLocale.t("Voice Preview Options")
	_settings_dialog.confirmed.connect(_on_settings_confirmed)
	add_child(_settings_dialog)

	var box := VBoxContainer.new()
	_settings_dialog.add_child(box)

	var grid := GridContainer.new()
	grid.columns = 2
	box.add_child(grid)

	var reference_label := Label.new()
	reference_label.text = CandyLocale.t("Reference")
	grid.add_child(reference_label)
	_reference_edit = LineEdit.new()
	_reference_edit.custom_minimum_size.x = 200
	_reference_edit.tooltip_text = CandyLocale.t("Follows the Variation Selector with this reference.")
	grid.add_child(_reference_edit)

	var layout_label := Label.new()
	layout_label.text = CandyLocale.t("Layout")
	grid.add_child(layout_label)
	_layout_button = OptionButton.new()
	for layout in LAYOUTS:
		_layout_button.add_item(CandyLocale.t(str(LAYOUT_LABELS[layout])))
	grid.add_child(_layout_button)

	var file_label := Label.new()
	file_label.text = CandyLocale.t("File name")
	grid.add_child(file_label)
	_file_place_button = OptionButton.new()
	_file_place_button.tooltip_text = CandyLocale.t("The name of the voice's file (its whole path in the tooltip).")
	CandyFieldPickButton.fill_place_options(_file_place_button, CandyLocale.t("Above the controls"),
		CandyLocale.t("Below the controls"))
	grid.add_child(_file_place_button)

	grid.add_child(Control.new())
	_sync_check = CheckBox.new()
	_sync_check.text = CandyLocale.t("Sync portrait")
	_sync_check.tooltip_text = CandyLocale.t("Playing, pausing, stopping and seeking the voice do the same to the Portrait Previews of this Editor. Ctrl+Play plays the other way.")
	grid.add_child(_sync_check)

	grid.add_child(Control.new())
	_show_pick_check = CheckBox.new()
	_show_pick_check.text = CandyLocale.t("Voice drop-down button")
	_show_pick_check.tooltip_text = CandyLocale.t("A drop-down arrow that picks the line's Voice file.")
	grid.add_child(_show_pick_check)

	grid.add_child(Control.new())
	_show_fields_check = CheckBox.new()
	_show_fields_check.text = CandyLocale.t("Voice fields button")
	_show_fields_check.tooltip_text = CandyLocale.t("Opens a pop-up with the line's voice fields.")
	grid.add_child(_show_fields_check)

	_min_size_fields = CandyMinSizeFields.new()
	box.add_child(_min_size_fields)


func _on_settings_confirmed() -> void:
	var merged := config.duplicate(true)
	merged["reference"] = _reference_edit.text.strip_edges()
	merged["layout"] = str(LAYOUTS[maxi(_layout_button.selected, 0)])
	merged["sync_portrait"] = _sync_check.button_pressed
	merged["show_pick"] = _show_pick_check.button_pressed
	merged["show_fields"] = _show_fields_check.button_pressed
	merged["file_name"] = str(_file_place_button.get_item_metadata(maxi(_file_place_button.selected, 0)))
	_min_size_fields.write_config(merged)
	save_config(merged)