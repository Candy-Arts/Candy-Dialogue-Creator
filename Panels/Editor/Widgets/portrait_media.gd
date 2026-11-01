#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPortraitMedia

const ANIMATED_FOLDER := "Animated"
const DEFAULT_NAME := "Default"
const FRAMES_CONFIG := "config.txt"
#^ The animation a SpriteFrames has when it stores none:
const DEFAULT_ANIMATION := "default"
const DEFAULT_VIDEO_FPS := 30.0
#^ Portrait_Play and Portrait_Stop values, as in Candy DE's CandyPortrait:
const PLAY_UNTIL_ADVANCE := -1
const PLAY_ALWAYS := -2
const PLAY_UNTIL_VOICE := -3
const STOP_REMOVE := 0
const STOP_LAST := -1
const DEFAULT_LOOPS := 1
const DEFAULT_STOP_FRAME := 1


#* What a Spoken_Line's data shows as its portrait:
#?   { "kind": "image" | "frames" | "sheet" | "video" | "animation",
#?     "path": the file or folder (the SpriteFrames for "animation"),
#?     "animation": for "animation", "hframes", "vframes", "count" for "sheet" }
#? or { "error": why nothing can be shown, "tooltip": details }.
static func resolve(data: Dictionary) -> Dictionary:
	var value := str(data.get("Portrait", "")).strip_edges()
	if value == "":
		value = DEFAULT_NAME
	var expression := CandyDropdowns.symbol("expression")
	if expression != "" and value.begins_with(expression):
		return {"error": CandyLocale.t("Portrait set by an expression"), "tooltip": CandyLocale.t("Only the game knows what it gives.")}

	if CandyResources.is_project_path(value):
		return _from_path(CandyResources.to_file_path(value), value.get_extension() == "")

	var actor := CandyResources.voice_actor(str(data.get("Reference", "")))
	if actor == "":
		return {"error": CandyLocale.t("No portrait"), "tooltip": CandyLocale.t("Set the Speaker to an actor: a role's actor is only known in game.")}
	var root := CandyResources.resource_folder("*Portraits")
	if root == "":
		return {"error": CandyLocale.t("No portrait"), "tooltip": CandyLocale.t("Set the Portraits folder in Settings > Project > Paths.")}
	var folder := root.path_join(actor)

	for candidate in [folder.path_join(ANIMATED_FOLDER).path_join(value), folder.path_join(value)]:
		if DirAccess.dir_exists_absolute(candidate):
			return {"kind": "frames", "path": candidate}
	var found := _file_in(folder, value)
	if not found.is_empty():
		return found
	var frames_path := _sprite_frames_of(data, actor)
	if _has_animation(frames_path, value):
		return {"kind": "animation", "path": frames_path, "animation": value}
	if value.get_extension() == "":
		return {"error": CandyLocale.t("No file to preview"), "tooltip": CandyLocale.t("A Portrait without an extension is only found in game.")}
	found = _file_in(folder, DEFAULT_NAME + "." + value.get_extension())
	if not found.is_empty():
		found["fallback"] = true	#/ Shown as Default (found nowhere)
		return found
	return {"error": CandyLocale.t("Portrait not found"), "tooltip": folder.path_join(value)}


#* The portrait's kind, as resolve() finds it ("image", "frames", "sheet", "video", "animation"):
#? "" when only the game can tell.
static func kind_of(data: Dictionary) -> String:
	var found := resolve(data)
	if found.has("error") or bool(found.get("fallback", false)):
		return ""		#/ Not found, expression or role
	var found_kind := str(found.get("kind", ""))
	if found_kind == "animation" or CandyResources.is_project_path(str(data.get("Portrait", "")).strip_edges()):
		return found_kind
	var value := str(data.get("Portrait", "")).strip_edges()
	if value == "":
		value = DEFAULT_NAME
	var actor := CandyResources.voice_actor(str(data.get("Reference", "")))
	if _has_animation(_sprite_frames_of(data, actor), value):
		return ""		#/ Also an animation of the line's SpriteFrames: the game's portrait node decides
	return found_kind


#* The SpriteFrames file a Portrait animation is looked up in:
static func _sprite_frames_of(data: Dictionary, actor: String) -> String:
	var frames_file := str(data.get("Sprite_Frames_File", "")).strip_edges()
	if frames_file == "":
		frames_file = actor		#/ The speaker's own (no extension: only found in game)
	return CandyDropdowns.sprite_frames_path(frames_file, actor, "*Portraits")


static func _has_animation(frames_path: String, animation: String) -> bool:
	return FileAccess.file_exists(frames_path) and CandyDropdowns.sprite_frames_animations(frames_path).has(animation)


#* The file file_name in folder, as {kind, path...}:
static func _file_in(folder: String, file_name: String) -> Dictionary:
	if file_name.get_extension() == "":
		return {}		#/ No extension (see the header)
	var path := folder.path_join(file_name)
	if not FileAccess.file_exists(path):
		return {}
	return _describe_file(path)


static func _from_path(path: String, no_extension: bool) -> Dictionary:
	if DirAccess.dir_exists_absolute(path):
		return {"kind": "frames", "path": path}
	if no_extension:
		return {"error": CandyLocale.t("No file to preview"), "tooltip": CandyLocale.t("A Portrait without an extension is only found in game.")}
	if FileAccess.file_exists(path):
		return _describe_file(path)
	return {"error": CandyLocale.t("Portrait not found"), "tooltip": path}


static func _describe_file(path: String) -> Dictionary:
	match CandyMediaTypes.kind_of(path):
		CandyMediaTypes.VIDEO:
			return {"kind": "video", "path": path}
		CandyMediaTypes.SPRITE:
			var found := CandyMediaTypes.sheet_layout(path)
			found["kind"] = "sheet"
			found["path"] = path
			return found
	return {"kind": "image", "path": path}


#& Loading

#* An image file as a texture, or null:
static func load_texture(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


#* The images of a frame folder, in natural order:
static func load_frames(folder: String) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var files: Array = []
	for file_name in DirAccess.get_files_at(folder):
		if CandyMediaTypes.is_image(file_name):
			files.append(file_name)
	files.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	for file_name in files:
		var texture := load_texture(folder.path_join(file_name))
		if texture != null:
			frames.append(texture)
	return frames


#* A frame folder's frame rate, from its config.txt's "fps = N", or 0:
static func folder_fps(folder: String) -> float:
	var path := folder.path_join(FRAMES_CONFIG)
	if not FileAccess.file_exists(path):
		return 0.0
	var line := FileAccess.get_file_as_string(path).strip_edges()
	if "=" in line:
		var fps := line.split("=")[1].strip_edges()
		if fps.is_valid_float():
			return maxf(float(fps), 0.0)
	return 0.0


static func load_video(path: String) -> VideoStream:
	if not FileAccess.file_exists(path):
		return null
	var stream := VideoStreamTheora.new()
	stream.file = path
	return stream


#* A .ogv video's frame rate, from its Theora header (like CandyPlayback.video_fps()):
static func video_fps(path: String, fallback: float = DEFAULT_VIDEO_FPS) -> float:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback
	var fps := fallback
	#? Beginning-of-stream pages come first, so a few pages are enough.
	for page in 32:
		var capture := file.get_buffer(4)
		if capture.size() < 4 or capture.get_string_from_ascii() != "OggS":
			break
		#Ł Skip version, header type, granule, serial, sequence, crc:
		file.seek(file.get_position() + 22)
		var segment_count := file.get_8()
		if segment_count <= 0:
			break
		var segments := file.get_buffer(segment_count)
		if segments.size() < segment_count:
			break
		var payload_size := 0
		for segment in segments:
			payload_size += segment
		var payload := file.get_buffer(payload_size)
		if payload.size() < payload_size:
			break
		#% Theora identification header - 0x80, "theora", fps numerator (bytes 22-25) and denominator (26-29), big-endian:
		if payload.size() >= 30 and payload[0] == 0x80 and payload.slice(1, 7).get_string_from_ascii() == "theora":
			var numerator: int = (payload[22] << 24) | (payload[23] << 16) | (payload[24] << 8) | payload[25]
			var denominator: int = (payload[26] << 24) | (payload[27] << 16) | (payload[28] << 8) | payload[29]
			if numerator > 0 and denominator > 0:
				fps = float(numerator) / float(denominator)
			break
	file.close()
	return fps


#& Playing

#* A Portrait_Play as a loop count (CandyPortrait.loops_of()):
static func loops_of(value: Variant) -> int:
	var text := str(value).strip_edges().get_slice("/", 0).strip_edges()		#/ "-3/2": -3
	if not text.is_valid_int():
		return DEFAULT_LOOPS		#/ Not a whole number: once
	return maxi(int(text), PLAY_UNTIL_VOICE)	#/ N, 0 (first frame only), PLAY_UNTIL_ADVANCE, PLAY_ALWAYS or PLAY_UNTIL_VOICE


#* A Portrait_Stop as a frame (CandyPortrait.stop_frame_of()):
static func stop_frame_of(value: Variant) -> int:
	var text := str(value).strip_edges()
	if not text.is_valid_int():
		return DEFAULT_STOP_FRAME	#/ Not a whole number: the first frame
	return maxi(int(text), STOP_LAST)	#/ N counted from 1, STOP_REMOVE or STOP_LAST


#* A stop frame (from 1, or STOP_LAST) as an index among count frames:
static func frame_index(stop_frame: int, count: int) -> int:
	if count <= 0:
		return 0
	if stop_frame == STOP_LAST:
		return count - 1
	return clampi(stop_frame - 1, 0, count - 1)


#* A text SpriteFrames (.tres) of the game project, with its textures loaded from its files:
static func load_sprite_frames(path: String) -> SpriteFrames:
	if path.get_extension().to_lower() != "tres" or not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)

	var textures: Dictionary = {}    #/ "ext:<id>" / "sub:<id>" -> Texture2D
	#@ Step 1 - ext_resource textures, by res:// path:
	for found in RegEx.create_from_string("\\[ext_resource ([^\\]]*)\\]").search_all(text):
		var attributes := found.get_string(1)
		var id := _attribute(attributes, "id")
		var resource_path := _attribute(attributes, "path")
		if id != "" and resource_path != "":
			var texture := load_texture(CandyResources.to_file_path(resource_path))
			if texture != null:
				textures["ext:" + id] = texture
	#@ Step 2 - AtlasTexture sub_resources, cut from them:
	var sub_pattern := RegEx.create_from_string("\\[sub_resource ([^\\]]*)\\]\\s*\\n((?:[^\\[].*\\n?)*)")
	for found in sub_pattern.search_all(text):
		if _attribute(found.get_string(1), "type") != "AtlasTexture":
			continue
		var body := found.get_string(2)
		var atlas := RegEx.create_from_string("atlas\\s*=\\s*ExtResource\\(\"([^\"]+)\"\\)").search(body)
		var region := RegEx.create_from_string("region\\s*=\\s*(Rect2\\([^)]*\\))").search(body)
		if atlas == null or not textures.has("ext:" + atlas.get_string(1)):
			continue
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = textures["ext:" + atlas.get_string(1)]
		if region != null:
			var rect = str_to_var(region.get_string(1))
			if rect is Rect2:
				atlas_texture.region = rect
		textures["sub:" + _attribute(found.get_string(1), "id")] = atlas_texture

	var frames := SpriteFrames.new()
	var literal := _animations_literal(text)
	if literal == "":
		return frames    #/ Its initial "default" animation, with no frames
	#@ Step 3 - References become strings str_to_var reads - ExtResource("2_x") -> "ext:2_x":
	literal = RegEx.create_from_string("ExtResource\\(\"([^\"]+)\"\\)").sub(literal, "\"ext:$1\"", true)
	literal = RegEx.create_from_string("SubResource\\(\"([^\"]+)\"\\)").sub(literal, "\"sub:$1\"", true)
	var animations = str_to_var(literal)
	if not animations is Array:
		return null
	frames.remove_animation(DEFAULT_ANIMATION)
	for animation in animations:
		if not animation is Dictionary:
			continue
		var animation_name := StringName(str(animation.get("name", DEFAULT_ANIMATION)))
		if frames.has_animation(animation_name):
			continue
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, float(animation.get("speed", 5.0)))
		frames.set_animation_loop(animation_name, bool(animation.get("loop", true)))
		var frame_list = animation.get("frames", [])
		if frame_list is Array:
			for frame in frame_list:
				if frame is Dictionary and textures.has(str(frame.get("texture", ""))):
					frames.add_frame(animation_name, textures[str(frame["texture"])], float(frame.get("duration", 1.0)))
	if frames.get_animation_names().is_empty():
		frames.add_animation(DEFAULT_ANIMATION)
	return frames


static func _attribute(attributes: String, key: String) -> String:
	var found := RegEx.create_from_string("\\b%s=\"([^\"]*)\"" % key).search(attributes)
	if found == null:
		return ""
	return found.get_string(1)


#* The "animations = [...]" value of the [resource] section, brackets matched:
static func _animations_literal(text: String) -> String:
	var found := RegEx.create_from_string("(?m)^animations\\s*=\\s*").search(text)
	if found == null:
		return ""
	var start := found.get_end()
	var depth := 0
	var in_string := false
	for i in range(start, text.length()):
		var character := text[i]
		if in_string:
			if character == "\"" and text[i - 1] != "\\":
				in_string = false
			continue
		match character:
			"\"":
				in_string = true
			"[", "{", "(":
				depth += 1
			"]", "}", ")":
				depth -= 1
				if depth == 0:
					return text.substr(start, i - start + 1)
	return ""
