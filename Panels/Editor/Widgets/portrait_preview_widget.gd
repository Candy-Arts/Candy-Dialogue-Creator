#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPortraitPreviewWidget
extends CandyAreaWidget

const SPOKEN_LINE := "Spoken_Line"
const MIN_SIZE := Vector2(64, 64)
const DEFAULT_BACKGROUND := Color(0, 0, 0, 0)
const BUTTON_PLACES := ["hidden", "reveal", "above", "below", "left", "right"]
const DEFAULT_BUTTONS := "hidden"
const FPS_SETTING := "portrait_sprite_fps"
const DEFAULT_FPS := 30.0
const PLAY_TEXT := "▶"
const PAUSE_TEXT := "❚❚"
#^ The fields its pop-up shows, unless its config lists others ("popup_fields"):
const DEFAULT_POPUP_FIELDS: Array = ["Portrait", "Sprite_Frames_File", "Portrait_Play", "Portrait_Stop",
	"Portrait_Mode", "Portrait_Self_Clear", "Portrait_Display", "Keep_Portrait_Space",
	"Keep_Alternate_Portrait_Space"]
#^ Its buttons, in the default order (config "button_order" sorts them), and their names in Options:
const BUTTON_IDS: Array = ["play", "stop", "color", "pick", "fields"]
const BUTTON_TITLES := {
	"play": "Play / Pause",  #/ translatable
	"stop": "Stop",  #/ translatable
	"color": "Background color",  #/ translatable
	"pick": "Pick a portrait (drop-down)",  #/ translatable
	"fields": "Portrait fields (pop-up)",  #/ translatable
}
#^ The field the pick button fills:
const PORTRAIT_FIELD := "Portrait"
#^ The buttons' gap to the view's corner, in Reveal mode:
const CORNER_MARGIN := 4.0

var _view: Control
var _background_color: ColorRect
var _background_texture: TextureRect
var _video: VideoStreamPlayer
var _image: TextureRect
var _sprite: Sprite2D
var _animated: AnimatedSprite2D
var _message: Label
var _play_button: Button
var _stop_button: Button
var _color_button: ColorPickerButton
#^ Opens the pop-up of the line's portrait fields:
var _fields_button: Button
var _fields_popup: CandyFieldsPopup
#^ Picks the line's Portrait file:
var _pick_button: CandyFieldPickButton
#^ The buttons over the view's corner, shown while the pointer is over the widget (Reveal mode), or null:
var _corner: HBoxContainer = null
#^ The portrait's file name, or null when hidden (config "file_name"):
var _file_label: Label = null
var _frame_timer: Timer
var _settings: CandyPortraitPreviewSettings

var _line_path: Array = []
#^ What is on display ({kind, path...} from CandyPortraitMedia.resolve()):
#? Kept so rebinding after an unrelated edit doesn't reload it.
var _shown: Dictionary = {}
var _frames: Array[Texture2D] = []
var _frame := 0
var _playing := false
var _hovered := false
#^ Whether a Voice Preview is playing it (see CandyPortraitSync):
var _driven := false
#^ How the line's portrait plays in game (CandyPortraitMedia.loops_of() / stop_frame_of()):
var _loops := CandyPortraitMedia.DEFAULT_LOOPS
var _stop_frame := CandyPortraitMedia.DEFAULT_STOP_FRAME
#^ The loops played so far, and whether it stopped on its stop frame:
var _loop_count := 0
var _ended := false
#^ Whether a Voice Preview started this playback (the mouse leaving doesn't pause it):
var _from_voice := false
var _video_fps := CandyPortraitMedia.DEFAULT_VIDEO_FPS


#* Only shows anything on Spoken_Line:
func fits_line_type(_config: Dictionary, line_type: String) -> bool:
	return line_type == SPOKEN_LINE


func _on_configured() -> void:
	custom_minimum_size = MIN_SIZE
	clip_contents = true

	var place := _buttons_place()
	var root: BoxContainer = VBoxContainer.new()
	if place == "left" or place == "right":
		root = HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_view = Control.new()
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_view.clip_contents = true
	#? Only the portrait area counts for play_on_hover, not the buttons.
	_view.mouse_filter = Control.MOUSE_FILTER_PASS
	_view.mouse_entered.connect(func(): _set_hovered(true))
	_view.mouse_exited.connect(func(): _set_hovered(false))
	_view.resized.connect(_fit)
	_build_view()

	_fields_popup = CandyFieldsPopup.new()
	add_child(_fields_popup)
	_fields_popup.setup(popup_fields(), context)
	_fields_button = CandyFieldsPopup.make_button(CandyLocale.t("Portrait fields"))
	_fields_button.pressed.connect(func(): _fields_popup.open_beside(_fields_button))
	_pick_button = CandyFieldPickButton.new(PORTRAIT_FIELD, CandyLocale.t("Pick a portrait"))
	_pick_button.setup(context)

	#Ł The portrait, with its file name above or below it:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var name_place := CandyFieldPickButton.file_name_place(config)
	if name_place != "hidden":
		_file_label = CandyFieldPickButton.make_file_label()
	if name_place == "above":
		column.add_child(_file_label)
	column.add_child(_view)
	if name_place == "below":
		column.add_child(_file_label)

	var buttons := _build_buttons(place)
	if buttons != null and (place == "above" or place == "left"):
		root.add_child(buttons)
	root.add_child(column)
	if buttons != null and (place == "below" or place == "right"):
		root.add_child(buttons)

	_frame_timer = Timer.new()
	_frame_timer.timeout.connect(_next_frame)
	add_child(_frame_timer)

	CandyProfiles.settings_changed.connect(_on_setting_changed)

	#? Methods, not lambdas - the sync outlives rebuilt widgets, and freed methods disconnect.
	var sync := portrait_sync()
	if sync != null:
		sync.played.connect(_on_sync_played)
		sync.paused.connect(_on_sync_paused)
		sync.stopped.connect(_on_sync_stopped)
		sync.finished.connect(_on_sync_finished)
		sync.sought.connect(_on_sync_sought)


func _build_view() -> void:
	_background_color = ColorRect.new()
	_background_texture = TextureRect.new()
	_background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_video = VideoStreamPlayer.new()
	_video.expand = true
	#? Not looping, so each loop's end can be counted.
	_video.loop = false
	_video.finished.connect(_on_video_finished)
	_image = TextureRect.new()
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	for control in [_background_color, _background_texture, _video, _image]:
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control.visible = false
		_view.add_child(control)

	_sprite = Sprite2D.new()
	_sprite.visible = false
	_view.add_child(_sprite)
	_animated = AnimatedSprite2D.new()
	_animated.visible = false
	_animated.animation_looped.connect(_on_animation_looped)
	_animated.animation_finished.connect(_on_animation_finished)
	_view.add_child(_animated)

	_message = Label.new()
	_message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.theme_type_variation = CandyThemeDefaults.NOTE
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.add_child(_message)


#* The buttons' row or column, or null when hidden or revealed over the view:
func _build_buttons(place: String) -> Control:
	var by_id := {"pick": _pick_button, "fields": _fields_button}
	#% Hidden - no buttons; the pick and fields ones are kept, out of sight, since other code reads them:
	if place == "hidden":
		for button: Control in [_pick_button, _fields_button]:
			button.visible = false
			add_child(button)
		return null

	_play_button = Button.new()
	_play_button.text = PLAY_TEXT
	_play_button.tooltip_text = CandyLocale.t("Play or pause the portrait")
	_play_button.focus_mode = Control.FOCUS_NONE
	_play_button.pressed.connect(_on_play_pressed)
	by_id["play"] = _play_button

	_stop_button = Button.new()
	_stop_button.text = "■"
	_stop_button.tooltip_text = CandyLocale.t("Stop, back to the first frame")
	_stop_button.focus_mode = Control.FOCUS_NONE
	_stop_button.pressed.connect(_stop)
	by_id["stop"] = _stop_button

	_color_button = ColorPickerButton.new()
	_color_button.custom_minimum_size = Vector2(28, 24)
	_color_button.edit_alpha = true
	_color_button.focus_mode = Control.FOCUS_NONE
	_color_button.tooltip_text = CandyLocale.t("Background color")
	#? Shown as it changes; saved once the picker closes (saving rebuilds the area).
	_color_button.color_changed.connect(func(color: Color):
		_background_color.color = color
		_show_background())
	_color_button.popup_closed.connect(func():
		if var_to_str(_color_button.color) != str(config.get("background_color", "")):
			var new_config := config.duplicate()
			new_config["background_color"] = var_to_str(_color_button.color)
			save_config(new_config))
	by_id["color"] = _color_button

	#% Reveal - every button over the view's corner, shown on hover:
	if place == "reveal":
		_corner = HBoxContainer.new()
		_corner.visible = false
		_corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for id in button_order(config):
			var button: Control = by_id[id]
			button.mouse_filter = Control.MOUSE_FILTER_PASS			#/ Keeps the view hovered (play_on_hover)
			_corner.add_child(button)
		_view.add_child(_corner)
		_view.resized.connect(_place_corner)
		return null

	var box: BoxContainer = HBoxContainer.new()
	if place == "left" or place == "right":
		box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	for id in button_order(config):
		box.add_child(by_id[id])
	return box


#* Its buttons' ids, in the order its config sorts them (unknown ids left out, missing ones added):
static func button_order(widget_config: Dictionary) -> Array:
	var result: Array = []
	var stored = widget_config.get("button_order", [])
	if stored is Array:
		for id in stored:
			if BUTTON_IDS.has(str(id)) and not result.has(str(id)):
				result.append(str(id))
	for id in BUTTON_IDS:
		if not result.has(id):
			result.append(id)
	return result


#* Keep the corner buttons in the view's top-right corner:
func _place_corner() -> void:
	var corner_size := _corner.get_combined_minimum_size()
	_corner.size = corner_size
	_corner.position = Vector2(maxf(0.0, _view.size.x - corner_size.x - CORNER_MARGIN), CORNER_MARGIN)


#* Show the corner buttons while the pointer is over the widget:
#? Not mouse_entered: the buttons themselves would end the hover.
func _input(event: InputEvent) -> void:
	if _corner == null or not event is InputEventMouseMotion:
		return
	var local: InputEventMouseMotion = make_input_local(event)
	var inside := is_visible_in_tree() and Rect2(Vector2.ZERO, size).has_point(local.position)
	#% Its pick menu or color picker open - keep it, so the menu has its button:
	if not inside and (_pick_button.has_open_menu() or _color_button.get_popup().visible):
		return
	if inside != _corner.visible:
		_corner.visible = inside
		_place_corner()


func _buttons_place() -> String:
	var place := str(config.get("buttons", DEFAULT_BUTTONS))
	if not BUTTON_PLACES.has(place):
		return DEFAULT_BUTTONS
	return place


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


func _on_setting_changed(key: String) -> void:
	match key:
		"project_path", "custom_project_paths", CandyPortraitBackgrounds.SETTING, FPS_SETTING, "symbols":
			_shown = {}
			_refresh()


#& Showing

func _refresh() -> void:
	if _view == null:
		return
	var line := CandyDialogue.line_at(_line_path)
	if CandyDialogue.line_type(line) != SPOKEN_LINE:
		_show_nothing("", CandyLocale.t("Portraits are shown for Spoken Lines."))
		_show_background({})
		_show_file_name("", "")
		return
	var data := CandyDialogue.line_data(line)
	_show_background(data)

	var found := CandyPortraitMedia.resolve(data)
	if found.has("error"):
		_show_nothing(str(found["error"]), str(found.get("tooltip", "")))
		#Ł The field's value, since no file was found:
		var typed := str(data.get(PORTRAIT_FIELD, "")).strip_edges()
		_show_file_name(typed, str(found.get("tooltip", "")))
		return
	var file_name := str(found["path"]).get_file()
	if found["kind"] == "animation":
		file_name += " (%s)" % found["animation"]
	_show_file_name(file_name, str(found["path"]))
	var loops := CandyPortraitMedia.loops_of(data.get("Portrait_Play", ""))
	var stop_frame := CandyPortraitMedia.stop_frame_of(data.get("Portrait_Stop", ""))
	var replay := loops != _loops or stop_frame != _stop_frame
	_loops = loops
	_stop_frame = stop_frame
	if found == _shown:
		#Ł Replay to show a new Play Portrait or Portrait Stop:
		if replay and not _driven:
			_play_from_start()
		return
	_clear()
	var shown := false
	match str(found["kind"]):
		"image":
			shown = _show_image(str(found["path"]))
		"frames":
			shown = _show_frames(str(found["path"]))
		"sheet":
			shown = _show_sheet(found)
		"video":
			shown = _show_video(str(found["path"]))
		"animation":
			shown = _show_animation(str(found["path"]), str(found["animation"]))
	if not shown:
		_show_nothing(CandyLocale.t("Can't read this portrait"), str(found["path"]))
		return
	_shown = found
	_message.text = ""
	_view.tooltip_text = str(found["path"])
	if found["kind"] == "animation":
		_view.tooltip_text += " (%s)" % found["animation"]
	_fit()
	_play_from_start()


#* Show the portrait's file name, when the widget shows it:
func _show_file_name(text: String, tooltip: String) -> void:
	if _file_label == null:
		return
	_file_label.text = text
	_file_label.tooltip_text = tooltip


func _show_image(path: String) -> bool:
	var texture := CandyPortraitMedia.load_texture(path)
	if texture == null:
		return false
	_image.texture = texture
	_image.visible = true
	return true


func _show_frames(folder: String) -> bool:
	_frames = CandyPortraitMedia.load_frames(folder)
	if _frames.is_empty():
		return false
	_frame = 0
	_image.texture = _frames[0]
	_image.visible = true
	_frame_timer.wait_time = 1.0 / _fps(CandyPortraitMedia.folder_fps(folder))
	return true


func _show_sheet(found: Dictionary) -> bool:
	var texture := CandyPortraitMedia.load_texture(str(found["path"]))
	if texture == null:
		return false
	_sprite.texture = texture
	_sprite.hframes = int(found["hframes"])
	_sprite.vframes = int(found["vframes"])
	_sprite.frame = 0
	_sprite.visible = true
	_frame_timer.wait_time = 1.0 / _fps(0.0)
	return true


func _show_video(path: String) -> bool:
	var stream := CandyPortraitMedia.load_video(path)
	if stream == null:
		return false
	_video.stream = stream
	_video_fps = CandyPortraitMedia.video_fps(path)
	_video.visible = true
	#? Started and paused, so its first frame shows.
	_video.play()
	_video.paused = true
	return true


func _show_animation(path: String, animation: String) -> bool:
	var frames := CandyPortraitMedia.load_sprite_frames(path)
	if frames == null or not frames.has_animation(animation):
		return false
	_animated.sprite_frames = frames
	_animated.animation = animation
	_animated.frame = 0
	#? At its own speed, as in Candy DE; a speed of 0 at the Portrait FPS.
	if frames.get_animation_speed(animation) <= 0.0:
		frames.set_animation_speed(animation, _fps(0.0))
	_animated.speed_scale = 1.0
	_animated.visible = true
	return true


#* own_fps when a frame folder gives one, else the Portrait FPS setting:
func _fps(own_fps: float) -> float:
	if own_fps > 0.0:
		return own_fps
	return maxf(float(CandyProfiles.get_setting(FPS_SETTING, DEFAULT_FPS)), 0.1)


func _clear() -> void:
	_set_playing(false)
	_frame_timer.stop()
	_frames.clear()
	_image.texture = null
	_image.visible = false
	_sprite.texture = null
	_sprite.visible = false
	_animated.stop()
	_animated.sprite_frames = null
	_animated.visible = false
	_video.stop()
	_video.stream = null
	_video.visible = false
	_shown = {}
	_from_voice = false
	_ended = false
	_loop_count = 0


func _show_nothing(message: String, tooltip: String) -> void:
	_clear()
	_message.text = message
	_view.tooltip_text = tooltip


#* Show the background - the speaker's own, else the widget's; a texture rather than a color:
func _show_background(data: Dictionary = {}) -> void:
	if _background_color == null:
		return
	var own := {"color": null, "texture": ""}
	#? data, else the bound line's speaker.
	if not data.is_empty():
		own = CandyPortraitBackgrounds.for_speaker(str(data.get("Reference", "")))
	elif CandyDialogue.is_line_path(_line_path):
		own = CandyPortraitBackgrounds.for_speaker(str(CandyDialogue.get_field(_line_path, ["Reference"], "")))

	var texture: Texture2D = null
	var color = own["color"]
	if str(own["texture"]) != "":
		texture = CandyPortraitMedia.load_texture(str(own["texture"]))
	elif color == null:
		var widget_texture := str(config.get("background_texture", "")).strip_edges()
		if widget_texture != "":
			texture = CandyPortraitMedia.load_texture(widget_texture)
		if texture == null:
			color = CandySpeechEditorSettings.to_color(config.get("background_color", ""), DEFAULT_BACKGROUND)
			if _color_button != null and _color_button.get_popup().visible:
				color = _color_button.color  #/ Being picked right now

	_background_texture.texture = texture
	_background_texture.visible = texture != null
	if color is Color:
		_background_color.color = color
	_background_color.visible = texture == null and color is Color
	if _color_button != null and not _color_button.get_popup().visible:
		_color_button.color = CandySpeechEditorSettings.to_color(config.get("background_color", ""), DEFAULT_BACKGROUND)
		if own["color"] != null or str(own["texture"]) != "":
			_color_button.tooltip_text = CandyLocale.t("Background color (the speaker's own background is shown instead, see Settings > UI > Portrait Backgrounds)")
		else:
			_color_button.tooltip_text = CandyLocale.t("Background color")


#* Center sprites (Node2Ds) and scale them to fit the area, keeping their shape:
func _fit() -> void:
	if _view == null:
		return
	var area := _view.size
	var frame_size := Vector2.ZERO
	var node: Node2D = null
	if _sprite.visible and _sprite.texture != null:
		node = _sprite
		frame_size = _sprite.texture.get_size() / Vector2(_sprite.hframes, _sprite.vframes)
	elif _animated.visible and _animated.sprite_frames != null:
		node = _animated
		var texture := _animated.sprite_frames.get_frame_texture(_animated.animation, 0)
		if texture != null:
			frame_size = texture.get_size()
	if node == null or frame_size.x <= 0.0 or frame_size.y <= 0.0:
		return
	var factor := minf(area.x / frame_size.x, area.y / frame_size.y)
	node.scale = Vector2(factor, factor)
	node.position = area * 0.5


#& Playing

#* Back to the first frame, playing unless it only shows that frame or play_on_hover:
func _play_from_start() -> void:
	_stop()
	_set_playing(not bool(config.get("play_on_hover", false)))


#* Pause, resume, or play again once it ended:
func _on_play_pressed() -> void:
	if _playing:
		_set_playing(false)
		return
	_resume()


func _set_hovered(value: bool) -> void:
	_hovered = value
	if not bool(config.get("play_on_hover", false)) or _driven:
		return
	if value:
		_resume()
	elif not _from_voice:
		_set_playing(false)


#* Play on from where it is, or from the start once it ended:
func _resume() -> void:
	if _ended:
		_stop()
	_from_voice = false
	_set_playing(true)


func _on_sync_played(seconds: float) -> void:
	_driven = true
	_on_sync_sought(seconds)


func _on_sync_paused() -> void:
	_driven = false
	_set_playing(false)


func _on_sync_stopped() -> void:
	_driven = false
	_stop()


#* The voice ended:
func _on_sync_finished() -> void:
	_driven = false
	#% "-1" stops there (the nearest to the player moving on), "-3" too; loops left or "-2" carry on:
	var until_end := _loops == CandyPortraitMedia.PLAY_UNTIL_ADVANCE or _loops == CandyPortraitMedia.PLAY_UNTIL_VOICE
	if _from_voice and not _ended and until_end:
		_stop_on_frame()


#* Put the portrait where it is seconds into the line, in game:
func _on_sync_sought(seconds: float) -> void:
	_from_voice = true
	_ended = false
	_show_media(true)
	var at := maxf(seconds, 0.0)
	var length := _loop_length()
	if _loops == 0 or length <= 0.0:
		#% First frame only, or nothing that plays (an image):
		_loop_count = 0
		_set_playing(false)
		_show_frame(0)
		return
	#% Loops done - on its stop frame:
	if _loops > 0 and at >= length * _loops:
		_loop_count = _loops
		_stop_on_frame()
		return
	_loop_count = int(at / length)
	_seek_within(fmod(at, length))
	#? Plays on while the voice plays.
	_set_playing(_driven)


#* Count a loop that just ended:
func _loop_ended() -> bool:
	if _loops <= 0:
		return false
	_loop_count += 1
	if _loop_count < _loops:
		return false
	_stop_on_frame()
	return true			#/ The last: stopped on its stop frame


#* End a playback as Candy DE does - on Portrait Stop's frame, or removed for 0:
func _stop_on_frame() -> void:
	_set_playing(false)
	_ended = true
	if _stop_frame == CandyPortraitMedia.STOP_REMOVE:
		_show_media(false)
		return
	_show_frame(CandyPortraitMedia.frame_index(_stop_frame, _frame_count()))


#* One loop's length, in seconds; 0 for what doesn't play:
func _loop_length() -> float:
	match str(_shown.get("kind", "")):
		"frames":
			return _frames.size() * _frame_timer.wait_time
		"sheet":
			return int(_shown.get("count", 1)) * _frame_timer.wait_time
		"video":
			return _video.get_stream_length()
		"animation":
			var total := 0.0
			for length in _animation_frame_lengths():
				total += length
			return total
	return 0.0


func _frame_count() -> int:
	match str(_shown.get("kind", "")):
		"frames":
			return _frames.size()
		"sheet":
			return int(_shown.get("count", 1))
		"video":
			return maxi(roundi(_video.get_stream_length() * _video_fps), 1)
		"animation":
			return _animation_frame_lengths().size()
	return 1


#* Each frame's length in the AnimatedSprite2D's animation, in seconds:
func _animation_frame_lengths() -> Array[float]:
	var lengths: Array[float] = []
	var frames := _animated.sprite_frames
	if frames == null:
		return lengths
	var animation := _animated.animation
	var rate := frames.get_animation_speed(animation) * _animated.speed_scale
	if rate <= 0.0:
		return lengths
	for i in frames.get_frame_count(animation):
		lengths.append(frames.get_frame_duration(animation, i) / rate)
	return lengths


#* Put the portrait at seconds into one loop:
func _seek_within(seconds: float) -> void:
	match str(_shown.get("kind", "")):
		"frames", "sheet":
			_show_frame(mini(int(seconds / _frame_timer.wait_time), _frame_count() - 1))
		"video":
			_video_at(seconds)
		"animation":
			var left := seconds
			var lengths := _animation_frame_lengths()
			for i in lengths.size():
				if left < lengths[i]:
					_animated.set_frame_and_progress(i, left / lengths[i])
					return
				left -= lengths[i]
			_show_frame(lengths.size() - 1)


#* Show frame index (from 0), paused unless it plays:
func _show_frame(index: int) -> void:
	match str(_shown.get("kind", "")):
		"frames":
			if not _frames.is_empty():
				_frame = clampi(index, 0, _frames.size() - 1)
				_image.texture = _frames[_frame]
		"sheet":
			_sprite.frame = clampi(index, 0, int(_shown.get("count", 1)) - 1)
		"video":
			_video_at(index / _video_fps)
		"animation":
			_animated.set_frame_and_progress(maxi(index, 0), 0.0)


#* A video at seconds:
func _video_at(seconds: float) -> void:
	#% A video that played to its end must play again to show a frame:
	if not _video.is_playing():
		_video.play()
	_video.paused = not _playing
	_video.stream_position = clampf(seconds, 0.0, maxf(_video.get_stream_length(), 0.0))


#* Show or hide the portrait's node (Portrait Stop 0 removes the portrait):
func _show_media(shown: bool) -> void:
	match str(_shown.get("kind", "")):
		"image", "frames":
			_image.visible = shown
		"sheet":
			_sprite.visible = shown
		"video":
			_video.visible = shown
		"animation":
			_animated.visible = shown


func _set_playing(value: bool) -> void:
	_playing = value and _plays()
	match str(_shown.get("kind", "")):
		"frames", "sheet":
			if _playing:
				_frame_timer.start()
			else:
				_frame_timer.stop()
		"video":
			_video.paused = not _playing
		"animation":
			if _playing:
				_animated.play()
			else:
				_animated.pause()
	if _play_button != null:
		_play_button.disabled = not _plays()
		_stop_button.disabled = not _plays()
		if _playing:
			_play_button.text = PAUSE_TEXT
		else:
			_play_button.text = PLAY_TEXT


#* Paused on the first frame, with no loops played:
func _stop() -> void:
	_set_playing(false)
	_from_voice = false
	_ended = false
	_loop_count = 0
	_show_media(true)
	_show_frame(0)


#* Whether it has something to play, and Play Portrait isn't "0":
func _plays() -> bool:
	return _is_animated() and _loops != 0


func _is_animated() -> bool:
	match str(_shown.get("kind", "")):
		"frames":
			return _frames.size() > 1
		"sheet":
			return int(_shown.get("count", 1)) > 1
		"video", "animation":
			return true
	return false


func _next_frame() -> void:
	var next := 0
	match str(_shown.get("kind", "")):
		"frames":
			next = _frame + 1
		"sheet":
			next = _sprite.frame + 1
		_:
			return
	if next >= _frame_count():
		if _loop_ended():
			return
		next = 0
	_show_frame(next)


#* Count a video loop, and play again unless done:
func _on_video_finished() -> void:
	if not _loop_ended():
		_video.play()
		_video.paused = false


func _on_animation_looped() -> void:
	_loop_ended()


#* Restart an animation that doesn't loop by itself, until its loops are done:
func _on_animation_finished() -> void:
	if not _loop_ended():
		_animated.set_frame_and_progress(0, 0.0)
		_animated.play()


#& Settings

func has_settings() -> bool:
	return true


func open_settings() -> void:
	if _settings == null:
		_settings = CandyPortraitPreviewSettings.new()
		_settings.applied.connect(func(changes: Dictionary):
			var new_config := config.duplicate()
			for key in changes:
				new_config[key] = changes[key]
			if new_config != config:
				save_config(new_config))
		add_child(_settings)
	_settings.open(config)
