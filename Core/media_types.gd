#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyMediaTypes

const IMAGE := "image"
const SPRITE := "sprite"
const ANIMATED_IMAGES := "animated_images"
const SPRITE_FRAMES := "sprite_frames"
const VIDEO := "video"
const AUDIO := "audio"

const LABELS := {
	IMAGE: "Image",	#/ translatable
	SPRITE: "Sprite",	#/ translatable
	ANIMATED_IMAGES: "Animated Images",	#/ translatable
	SPRITE_FRAMES: "Animated Sprite",	#/ translatable
	VIDEO: "Video",	#/ translatable
	AUDIO: "Audio",	#/ translatable
}

const IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "bmp", "tga", "webp", "svg", "ktx"]
const AUDIO_EXTENSIONS := ["ogg", "oga", "mp3", "wav"]
const VIDEO_EXTENSIONS := ["ogv"]
const SPRITE_FRAMES_EXTENSIONS := ["tres", "res"]
#^ "Happy_4x5-2.png" - columns, rows, unused cells:
const SHEET_PATTERN := "(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)"


#* A file's kind, from its name ("" if Candy DE can't use it):
#? Not for folders: see holds_images().
static func kind_of(file_name: String) -> String:
	var extension := file_name.get_extension().to_lower()
	if IMAGE_EXTENSIONS.has(extension):
		if sheet_layout(file_name).is_empty():
			return IMAGE
		return SPRITE
	if VIDEO_EXTENSIONS.has(extension):
		return VIDEO
	if AUDIO_EXTENSIONS.has(extension):
		return AUDIO
	if SPRITE_FRAMES_EXTENSIONS.has(extension):
		return SPRITE_FRAMES
	return ""


#* A kind's extensions:
static func extensions_of(kind: String) -> Array:
	match kind:
		IMAGE, SPRITE, ANIMATED_IMAGES:
			return IMAGE_EXTENSIONS
		VIDEO:
			return VIDEO_EXTENSIONS
		AUDIO:
			return AUDIO_EXTENSIONS
		SPRITE_FRAMES:
			return SPRITE_FRAMES_EXTENSIONS
	return []


#* Whether a file is an image (sprite sheets included):
static func is_image(file_name: String) -> bool:
	return IMAGE_EXTENSIONS.has(file_name.get_extension().to_lower())


#* Load an audio file from disk (null if unreadable):
static func load_audio(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null
	match path.get_extension().to_lower():
		"mp3":
			return AudioStreamMP3.load_from_file(path)
		"ogg", "oga":
			return AudioStreamOggVorbis.load_from_file(path)
		"wav":
			return AudioStreamWAV.load_from_file(path)
	return null


#* A sprite sheet's grid from its name: {"hframes", "vframes", "count"}:
static func sheet_layout(file_name: String) -> Dictionary:
	if not is_image(file_name):
		return {}
	var sheet := RegEx.create_from_string(SHEET_PATTERN).search(file_name.get_file())
	if sheet == null:
		return {}
	var hframes := maxi(absi(int(sheet.get_string(1))), 1)
	var vframes := maxi(absi(int(sheet.get_string(2))), 1)
	var unused := 0
	if sheet.get_string(3) != "":
		unused = absi(int(sheet.get_string(3)))
	return {"hframes": hframes, "vframes": vframes, "count": maxi(hframes * vframes - unused, 1)}


#* Whether a scanned folder holds images directly (an ANIMATED_IMAGES):
static func holds_images(folder: Dictionary) -> bool:
	for entry_name in folder:
		if not folder[entry_name] is Dictionary and is_image(str(entry_name)):
			return true
	return false


#* A scanned folder's path, found from a file inside ("" if none):
static func folder_path(folder: Dictionary) -> String:
	for entry_name in folder:
		var entry = folder[entry_name]
		if not entry is Dictionary:
			return str(entry).get_base_dir()
		var inner := folder_path(entry)
		if inner != "":
			return inner.get_base_dir()
	return ""
