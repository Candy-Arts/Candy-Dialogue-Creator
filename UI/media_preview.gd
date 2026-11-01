#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyMediaPreview
extends Window

#^ Preview sizes - the settings holding the width and FPS (none for audio):
const SIZES := {
	"audio": {},
	"portraits": {"width": "portrait_preview_width", "fps": "portrait_sprite_fps"},
	"busts": {"width": "bust_preview_width", "fps": "bust_sprite_fps"},
	"backgrounds": {"width": "bg_preview_width", "fps": "bg_sprite_fps"},
	"media_images": {"width": "image_preview_width", "fps": "bg_sprite_fps"},
	"media_videos": {"width": "video_preview_width", "fps": "bg_sprite_fps"},
}
#^ Fallbacks for an unknown size or a non-number setting:
const DEFAULT_WIDTH := 256.0
const DEFAULT_FPS := 30.0
#^ Gap between the pointer and the preview, like a tooltip's:
const POINTER_GAP := Vector2i(16, 16)
#^ A video's shape until its size is known:
const VIDEO_SHAPE := Vector2(16, 9)
#^ SpriteFrames animation played when the item names none:
const DEFAULT_ANIMATION := "default"
#^ Shortest frame time, so a zero-length frame can't stall the loop:
const MIN_FRAME_TIME := 0.001

var _panel: PanelContainer
var _image: TextureRect
var _video: VideoStreamPlayer
var _audio: AudioStreamPlayer

#^ The watched menu under the mouse:
var _hovered: PopupMenu
#^ The "preview" on display, {} for none:
var _shown: Dictionary = {}
#^ The media's own size (one frame's), for the preview's shape:
var _media_size := Vector2.ZERO
var _frames: Array[Texture2D] = []
#^ Each frame's duration, in seconds:
var _frame_times: Array[float] = []
var _frame := 0
var _frame_elapsed := 0.0
#^ Pointer position at the last placement:
var _pointer := Vector2i.ZERO


func _init() -> void:
	visible = false
	borderless = true
	unfocusable = true
	unresizable = true
	transient = true
	transparent = true
	transparent_bg = true
	mouse_passthrough = true

	_panel = PanelContainer.new()
	_panel.theme_type_variation = CandyThemeDefaults.MEDIA_PREVIEW
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	_image = TextureRect.new()
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image.visible = false
	_panel.add_child(_image)

	_video = VideoStreamPlayer.new()
	_video.expand = true
	_video.loop = true
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.visible = false
	_panel.add_child(_video)

	_audio = AudioStreamPlayer.new()
	add_child(_audio)


#* Preview the hovered item of a menu, if its metadata holds a preview:
func watch(menu: PopupMenu) -> void:
	#Ł Track hover through the menu's window (a PopupMenu doesn't report hovered items):
	menu.mouse_entered.connect(func(): _hovered = menu)
	menu.mouse_exited.connect(func():
		if _hovered == menu:
			_hovered = null)
	menu.popup_hide.connect(func():
		if _hovered == menu:
			_hovered = null)


func _process(delta: float) -> void:
	var preview := _hovered_preview()
	if preview.is_empty():
		_clear()
		return
	if preview != _shown:
		_show_preview(preview)
	if not visible:
		return
	_play(delta)
	_place()


#* The hovered item's "preview", {} for none:
func _hovered_preview() -> Dictionary:
	if not is_instance_valid(_hovered) or not _hovered.visible:
		return {}
	var index := _hovered.get_focused_item()
	if index < 0 or index >= _hovered.item_count:
		return {}
	var preview = _hovered.get_item_metadata(index)
	if preview is Dictionary:
		return preview
	return {}


#& Showing

func _show_preview(preview: Dictionary) -> void:
	_clear()
	#? Kept even if unreadable, so it isn't re-read every frame.
	_shown = preview
	if get_parent() != _hovered:
		reparent(_hovered)
	if not _load(preview):
		return
	if _audio.stream != null:
		_audio.play()
		return
	_fit()
	_place(true)
	show()
	if _video.visible:
		_video.play()


#* Hide the preview and release its media:
func _clear() -> void:
	if _shown.is_empty() and not visible:
		return
	hide()
	_shown = {}
	_video.stop()
	_video.stream = null
	_video.visible = false
	_audio.stop()
	_audio.stream = null
	_image.texture = null
	_image.visible = false
	_frames.clear()
	_frame_times.clear()
	_media_size = Vector2.ZERO


#* Load a preview's media (false if unreadable):
func _load(preview: Dictionary) -> bool:
	var path := str(preview.get("path", ""))
	if DirAccess.dir_exists_absolute(path):
		return _load_frames(CandyPortraitMedia.load_frames(path), CandyPortraitMedia.folder_fps(path))
	match CandyMediaTypes.kind_of(path):
		CandyMediaTypes.IMAGE:
			var texture := CandyPortraitMedia.load_texture(path)
			if texture == null:
				return false
			var frames: Array[Texture2D] = [texture]
			return _load_frames(frames, 0.0)
		CandyMediaTypes.SPRITE:
			return _load_sheet(path)
		CandyMediaTypes.SPRITE_FRAMES:
			return _load_animation(path, str(preview.get("animation", "")))
		CandyMediaTypes.VIDEO:
			return _load_video(path)
		CandyMediaTypes.AUDIO:
			_audio.stream = CandyMediaTypes.load_audio(path)
			return _audio.stream != null
	return false


#* Set frames played at own_fps (0 = the size's FPS):
func _load_frames(frames: Array[Texture2D], own_fps: float) -> bool:
	var fps := own_fps
	if fps <= 0.0:
		fps = maxf(_setting("fps", DEFAULT_FPS), 0.1)
	var times: Array[float] = []
	for i in frames.size():
		times.append(1.0 / fps)
	return _set_frames(frames, times)


#* Load a sprite sheet ("Happy_4x5-2.png"), cut into frames:
func _load_sheet(path: String) -> bool:
	var texture := CandyPortraitMedia.load_texture(path)
	var layout := CandyMediaTypes.sheet_layout(path)
	if texture == null or layout.is_empty():
		return false
	var hframes := int(layout["hframes"])
	var cell := texture.get_size() / Vector2(hframes, int(layout["vframes"]))
	var frames: Array[Texture2D] = []
	for i in int(layout["count"]):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(Vector2(i % hframes, floori(i / float(hframes))) * cell, cell)
		frames.append(atlas)
	return _load_frames(frames, 0.0)


#* Load one SpriteFrames animation, at its own speed:
func _load_animation(path: String, animation: String) -> bool:
	var sprite_frames := CandyPortraitMedia.load_sprite_frames(path)
	if sprite_frames == null:
		return false
	var animation_name := StringName(animation)
	if animation == "":
		animation_name = StringName(DEFAULT_ANIMATION)
		var names := sprite_frames.get_animation_names()
		if not sprite_frames.has_animation(animation_name) and not names.is_empty():
			animation_name = StringName(names[0])
	if not sprite_frames.has_animation(animation_name):
		return false
	var speed := sprite_frames.get_animation_speed(animation_name)
	if speed <= 0.0:
		speed = maxf(_setting("fps", DEFAULT_FPS), 0.1)
	var frames: Array[Texture2D] = []
	var times: Array[float] = []
	for i in sprite_frames.get_frame_count(animation_name):
		var texture := sprite_frames.get_frame_texture(animation_name, i)
		if texture != null:
			frames.append(texture)
			times.append(sprite_frames.get_frame_duration(animation_name, i) / speed)
	return _set_frames(frames, times)


func _set_frames(frames: Array[Texture2D], times: Array[float]) -> bool:
	if frames.is_empty():
		return false
	_frames = frames
	_frame_times = times
	_frame = 0
	_frame_elapsed = 0.0
	_image.texture = frames[0]
	_image.visible = true
	_media_size = frames[0].get_size()
	return true


func _load_video(path: String) -> bool:
	var stream := CandyPortraitMedia.load_video(path)
	if stream == null:
		return false
	_video.stream = stream
	_video.visible = true
	#? Size known once the first frame is read, if not already (see _play()).
	var texture := _video.get_video_texture()
	if texture != null:
		_media_size = texture.get_size()
	return true


#* Size the window - the width, the media's proportions, scaled down whole to fit, plus the frame:
func _fit() -> void:
	var shape := _media_size
	if shape.x <= 0.0 or shape.y <= 0.0:
		shape = VIDEO_SHAPE
	var width := maxf(_setting("width", DEFAULT_WIDTH), 1.0)
	var content := Vector2(width, width * shape.y / shape.x)
	var frame := _panel.get_theme_stylebox(&"panel").get_minimum_size()
	var room := Vector2(_bounds().size) - frame
	var factor := minf(1.0, minf(room.x / content.x, room.y / content.y))
	size = Vector2i((content * maxf(factor, 0.0) + frame).round())


#* Place beside the pointer like a tooltip (other side if it doesn't fit):
func _place(force: bool = false) -> void:
	var pointer := _pointer_position()
	#% Only move when the pointer did, unless forced:
	if pointer == _pointer and not force:
		return
	_pointer = pointer
	var bounds := _bounds()
	var spot := pointer + POINTER_GAP
	if spot.x + size.x > bounds.end.x:
		spot.x = pointer.x - POINTER_GAP.x - size.x
	if spot.y + size.y > bounds.end.y:
		spot.y = pointer.y - POINTER_GAP.y - size.y
	spot.x = clampi(spot.x, bounds.position.x, maxi(bounds.position.x, bounds.end.x - size.x))
	spot.y = clampi(spot.y, bounds.position.y, maxi(bounds.position.y, bounds.end.y - size.y))
	position = spot


#* Pointer position, in this window's coordinates (screen, or the embedding viewport):
func _pointer_position() -> Vector2i:
	var menu := get_parent() as Window
	if menu != null and menu.is_embedded():
		return menu.position + Vector2i(menu.get_mouse_position())
	return DisplayServer.mouse_get_position()


#* Where the preview may go - the menu's usable screen, or the main window when embedded:
func _bounds() -> Rect2i:
	var menu := get_parent() as Window
	if menu == null:
		return DisplayServer.screen_get_usable_rect()
	if menu.is_embedded():
		return Rect2i(Vector2i.ZERO, Vector2i(get_tree().root.get_visible_rect().size))
	return DisplayServer.screen_get_usable_rect(menu.current_screen)


#& Playing

#* Advance the looping animation; a video plays by itself (its shape is taken once known):
func _play(delta: float) -> void:
	if _video.visible:
		var texture := _video.get_video_texture()
		if texture != null and texture.get_width() > 0 and texture.get_size() != _media_size:
			_media_size = texture.get_size()
			_fit()
			_place(true)
		return
	if _frames.size() < 2:
		return
	_frame_elapsed += delta
	var changed := false
	while _frame_elapsed >= maxf(_frame_times[_frame], MIN_FRAME_TIME):
		_frame_elapsed -= maxf(_frame_times[_frame], MIN_FRAME_TIME)
		_frame = (_frame + 1) % _frames.size()
		changed = true
	if changed:
		_image.texture = _frames[_frame]


#* One setting of the shown size ("width" or "fps") as a number, else fallback:
func _setting(which: String, fallback: float) -> float:
	var settings: Dictionary = SIZES.get(str(_shown.get("size", "")), {})
	var key := str(settings.get(which, ""))
	if key == "":
		return fallback
	#? Number or string (1.1 profiles).
	var value := str(CandyProfiles.get_setting(key, fallback))
	if not value.is_valid_float():
		return fallback
	return float(value)
