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

signal theme_changed

const DEFAULT_THEME := "candy_arts_blue"
#^ The landing screen's theme, whatever the profile's:
const LANDING_THEME := "candy_arts_blue"
const THEME_SETTING := "theme"
const OVERRIDES_SETTING := "theme_overrides"

const BUILTIN_THEMES := "res://Themes"
const USER_THEMES := "user://Themes"
const BUILTIN_OPTIONS := "res://Theme_Options"
const MODS_DIR := "user://Mods"
const MOD_THEMES := "Themes"
const MOD_OPTIONS := "Theme_Options"
const CANDY_EXTENSIONS := ["txt"]
const GODOT_EXTENSIONS := ["tres", "res", "theme"]
#^ Fallback fonts, for the characters a theme's fonts lack (Chinese...):
const BUILTIN_FONTS := "res://Fonts"
const USER_FONTS := "user://Fonts"
const MOD_FONTS := "Fonts"
const FONT_EXTENSIONS := ["ttf", "otf", "woff", "woff2", "ttc", "otc"]
#^ The language whose fonts come next, after those of the language shown:
#? Chinese, Japanese and Korean share characters drawn differently; in any other language,
#? they're drawn in their Simplified Chinese forms, the most widely written.
const DEFAULT_FONT_LANGUAGE := "zh"
#^ Godot sizes buttons by the tallest of a font and its fallbacks, so the UI's fonts get trimmed copies of
#^ the taller fallbacks (Myanmar, Arabic...): the font's ascent and descent at every size up to this one:
const MAX_TRIMMED_SIZE := 96
#^ The size a fallback is measured at, to tell whether it's taller:
const FALLBACK_TEST_SIZE := 16
#^ RichTextLabel's fonts:
const RICH_FONT_ITEMS: Array[StringName] = [&"normal_font", &"bold_font", &"italics_font", &"bold_italics_font", &"mono_font"]
#^ Theme types that show the user's text get the fallbacks untrimmed, for the line height their scripts need - { type: [font items] }:
const TEXT_FONT_TYPES := {
	CandyThemeDefaults.SPEECH_EDITOR: [&"font"],
	CandyThemeDefaults.TAG_POPUP_EDIT: [&"font"],
	CandyThemeDefaults.ADVANCED_SPEECH_EDITOR: [&"font", &"normal_font", &"bold_font", &"italics_font", &"bold_italics_font", &"mono_font"],
	CandyThemeDefaults.SPEECH_VIEWER: [&"normal_font", &"bold_font", &"italics_font", &"bold_italics_font", &"mono_font"],
}
#^ Max "base" chain depth, against loops:
const MAX_BASE_DEPTH := 8
#^ Generated icons - Godot's checkbox icon size, and line width:
const ICON_SIZE := 16
const ICON_LINE := 1.5
#^ Types whose "panel" is a popup window's background:
const POPUP_PANELS := [&"TooltipPanel", &"PopupMenu", &"PopupPanel"]
#^ Minimum rounded corner segments:
const CORNER_DETAIL := 8
#^ Button metas - kept wide, its code's minimum width, the width _keep_wide() set:
const SHAPE_TRACKED_META := &"candy_shape_tracked"
const CODE_WIDTH_META := &"candy_code_min_width"
const SHAPE_WIDTH_META := &"candy_shape_min_width"

#^ The theme every Candy DC window uses. Rebuilt in place:
var theme := Theme.new()
#^ The landing screen's theme:
var landing_theme := Theme.new()

var _options: Array = []          #/ Option dictionaries, in load order
var _option_index: Dictionary = {}    #/ id -> option
var _themes: Dictionary = {}      #/ id -> { id, name, path, kind: "candy" | "godot", source, category }
var _theme_id := DEFAULT_THEME
var _overrides: Dictionary = {}
#^ Theme file entries with defaults for colors that aren't theme items:
const COLOR_DEFAULT_KEYS := ["navigator_colors", "counter_colors", "speech_colors"]
var _color_defaults: Dictionary = {}    #/ COLOR_DEFAULT_KEYS key -> the theme's, or empty
var _owned_styles: Dictionary = {}    #/ "type/name" -> true: styleboxes this build owns
#^ Fallback fonts, first tried first:
var _fallback_fonts: Array[Font] = []
var _ui_copies: Dictionary = {}    #/ Font -> its copy with the fallback fonts, the taller ones trimmed
var _all_copies: Dictionary = {}    #/ Font -> its copy with the fallback fonts as they are
var _copy_sources: Dictionary = {}    #/ Copy -> the font it was made from
var _trimmed: Dictionary = {}    #/ [fallback, metrics font] -> the fallback trimmed to that font's height
#^ The fonts picked by file name (font_files()), loaded once:
var _picked_fonts: Dictionary = {}    #/ file name -> FontFile


func _ready() -> void:
	CandyLayout.window_theme = theme
	reload()
	_apply_last_session()
	CandyProfiles.profile_opened.connect(func(_user: String, _profile: String): apply_settings())
	CandyProfiles.settings_changed.connect(func(key: String):
		if key == THEME_SETTING or key == OVERRIDES_SETTING:
			apply_settings())
	get_tree().node_added.connect(_on_node_added)


#& Public

#* Reload themes and options, and rebuild:
func reload() -> void:
	_load_options()
	_find_themes()
	_load_fallback_fonts()
	build(_theme_id, _overrides)
	_build_into(landing_theme, resolved_id(LANDING_THEME), {})


#* Apply the profile's theme and overrides:
func apply_settings() -> void:
	var theme_id := str(CandyProfiles.get_setting(THEME_SETTING, DEFAULT_THEME))
	build(theme_id, overrides_of(CandyProfiles.get_setting(OVERRIDES_SETTING, {}), theme_id))


#* One theme's overrides, out of the "theme_overrides" setting:
func overrides_of(all_overrides: Variant, theme_id: String) -> Dictionary:
	if all_overrides is Dictionary and all_overrides.get(theme_id) is Dictionary:
		return all_overrides[theme_id]
	return {}


#* Show a theme without saving, for Settings:
func preview(theme_id: String, overrides: Dictionary) -> void:
	build(theme_id, overrides)


#* Themes for a menu:
#? [ { id, name, kind, source, category } ]
func theme_list() -> Array:
	var result: Array = _themes.values()
	#Ł Uncategorized first, then by category; built-in first in each:
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["category"] != b["category"]:
			if a["category"] == "" or b["category"] == "":
				return a["category"] == ""
			return str(a["category"]).naturalnocasecmp_to(str(b["category"])) < 0
		if (a["source"] == "Built-in") != (b["source"] == "Built-in"):
			return a["source"] == "Built-in"
		return str(a["name"]).naturalnocasecmp_to(str(b["name"])) < 0)
	return result


func current_theme_id() -> String:
	return _theme_id


#* The theme's default Navigator row colors, or empty:
func navigator_colors() -> Dictionary:
	return _color_defaults.get("navigator_colors", {})


#* The theme's Counters colors, or empty:
func counter_colors() -> Dictionary:
	return _color_defaults.get("counter_colors", {})


#* The theme's Speech Editor / Viewer colors, or empty:
func speech_colors() -> Dictionary:
	return _color_defaults.get("speech_colors", {})


func options() -> Array:
	return _options


func option(id: String) -> Dictionary:
	return _option_index.get(id, {})


#* Option pages, in first-seen order:
func option_pages() -> Array:
	var pages: Array = []
	for entry in _options:
		var page := str(entry.get("page", "Other"))
		if not pages.has(page):
			pages.append(page)
	return pages


#* An option's value in a theme, before overrides:
func theme_value(theme_id: String, option_id: String) -> Variant:
	var values := _candy_values(theme_id, 0)
	var entry := option(option_id)
	return coerce(entry, values.get(option_id, entry.get("default")))


#* The user's themes folder (made if missing), as an OS path:
func user_themes_folder() -> String:
	if not DirAccess.dir_exists_absolute(USER_THEMES):
		DirAccess.make_dir_recursive_absolute(USER_THEMES)
	return ProjectSettings.globalize_path(USER_THEMES)


#& Fonts

#* The user's fonts folder (made if missing), as an OS path:
func user_fonts_folder() -> String:
	if not DirAccess.dir_exists_absolute(USER_FONTS):
		DirAccess.make_dir_recursive_absolute(USER_FONTS)
	return ProjectSettings.globalize_path(USER_FONTS)


#* The font files that can be picked as a font (the Font theme option, Speech Editors), by file name:
#? The user's and the mods', not the built-in ones, which only give missing characters.
func font_files() -> PackedStringArray:
	var result := PackedStringArray()
	for folder: String in _picked_font_folders():
		for file_name in _files_in(folder, FONT_EXTENSIONS):
			if not result.has(file_name):
				result.append(file_name)
	result.sort()
	return result


#* A font of font_files(), by file name, or null if there's none:
#? Without the fallback fonts: give it through with_fallbacks() where it's used.
func picked_font(file_name: String) -> Font:
	if file_name == "":
		return null
	if _picked_fonts.has(file_name):
		return _picked_fonts[file_name]
	for folder: String in _picked_font_folders():
		var path := folder.path_join(file_name)
		if not FileAccess.file_exists(path):
			continue
		var font := FontFile.new()
		if font.load_dynamic_font(path) != OK:
			push_warning("CandyTheme: couldn't load the font %s" % path)
			return null
		_picked_fonts[file_name] = font
		return font
	return null


func _picked_font_folders() -> Array:
	var folders: Array = [USER_FONTS]
	folders.append_array(_mod_folders(MOD_FONTS))
	return folders


#& Button shape

func _on_node_added(node: Node) -> void:
	if not node is Button or node.has_meta(SHAPE_TRACKED_META):
		return
	var button: Button = node
	if not _uses_theme(button):
		return
	button.set_meta(SHAPE_TRACKED_META, true)
	button.minimum_size_changed.connect(_keep_wide.bind(button))
	button.resized.connect(_keep_wide.bind(button))
	_keep_wide(button)


#* Whether control uses `theme` or `landing_theme`:
func _uses_theme(control: Control) -> bool:
	#? The nearest ancestor with a theme of its own decides.
	var current: Node = control
	while current != null:
		if current is Control and current.theme != null:
			return current.theme == theme or current.theme == landing_theme
		if current is Window and current.theme != null:
			return current.theme == theme or current.theme == landing_theme
		current = current.get_parent()
	return false


#* Make button at least as wide as its height:
func _keep_wide(button: Button) -> void:
	#Ł Remember its code's own minimum width, so changes to it, or a smaller height, still count:
	var code_width: float = button.custom_minimum_size.x
	if button.has_meta(SHAPE_WIDTH_META) \
			and is_equal_approx(code_width, float(button.get_meta(SHAPE_WIDTH_META))):
		code_width = float(button.get_meta(CODE_WIDTH_META, 0.0))
	button.set_meta(CODE_WIDTH_META, code_width)
	var height := button.get_combined_minimum_size().y
	#% Not stretched to fill its container's height (a Buttons panel's Fill), which would make it as wide:
	if not (button.size_flags_vertical & Control.SIZE_EXPAND):
		height = maxf(height, button.size.y)
	var width := maxf(code_width, height)
	button.set_meta(SHAPE_WIDTH_META, width)
	if not is_equal_approx(button.custom_minimum_size.x, width):
		button.custom_minimum_size.x = width


#& Building

#* The theme id itself, or DEFAULT_THEME if missing:
func resolved_id(theme_id: String) -> String:
	if _themes.has(theme_id):
		return theme_id
	return DEFAULT_THEME


#* Rebuild `theme` in place:
func build(theme_id: String, overrides: Dictionary) -> void:
	theme_id = resolved_id(theme_id)
	_theme_id = theme_id
	_overrides = overrides.duplicate()
	_color_defaults.clear()
	for key in COLOR_DEFAULT_KEYS:
		_color_defaults[key] = _candy_entry(theme_id, key, 0)
	_build_into(theme, theme_id, overrides)
	theme_changed.emit()


#* Rebuild target in place:
func _build_into(target: Theme, theme_id: String, overrides: Dictionary) -> void:
	#? One "changed" at the end.
	target.set_block_signals(true)
	target.clear()
	#Ł Reset defaults too (clear() only empties the items):
	target.default_font = null
	target.default_font_size = -1
	target.default_base_scale = 0.0
	_owned_styles.clear()
	CandyThemeDefaults.add_structure(target)
	_apply_values(target, _candy_values(theme_id, 0))
	var godot_theme := _godot_theme(theme_id)
	if godot_theme != null:
		target.merge_with(godot_theme)
	_apply_values(target, _with_followers(theme_id, overrides))
	CandyThemeDefaults.add_inverted(target)
	CandyThemeDefaults.add_round(target)
	CandyThemeDefaults.add_area_buttons(target)
	CandyThemeDefaults.add_tab_button(target)
	CandyThemeDefaults.add_rich_text_fonts(target)
	_add_fallback_fonts(target)
	_square_opaque_popups(target)
	target.set_block_signals(false)
	target.emit_changed()


#* Give every font of target the fallback fonts: trimmed to its height, untrimmed for the types that show the user's text:
#! Call once every font is set (add_rich_text_fonts() reads default_font).
func _add_fallback_fonts(target: Theme) -> void:
	if _fallback_fonts.is_empty():
		return
	#Ł The text types' fonts, before the UI's fallbacks are added to them:
	var text_fonts := {}    #/ [type, item] -> Font
	for type_name: StringName in TEXT_FONT_TYPES:
		for item: StringName in TEXT_FONT_TYPES[type_name]:
			text_fonts[[type_name, item]] = _text_font(target, type_name, item)
	#? Without a default font, controls use Godot's, which has no Chinese.
	var default_font := target.default_font
	if default_font == null:
		default_font = ThemeDB.fallback_font
	target.default_font = with_fallbacks(default_font)
	for type_name in target.get_font_type_list():
		for item in target.get_font_list(type_name):
			target.set_font(item, type_name, with_fallbacks(target.get_font(item, type_name)))
	for key: Array in text_fonts:
		target.set_font(key[1], key[0], with_fallbacks(text_fonts[key], true))


#* The font a text type draws item with: its own, else its base type's (TextEdit's, RichTextLabel's):
func _text_font(target: Theme, type_name: StringName, item: StringName) -> Font:
	if target.has_font(item, type_name):
		return target.get_font(item, type_name)
	if RICH_FONT_ITEMS.has(item):
		return target.get_font(item, &"RichTextLabel")
	return target.get_font(item, CandyThemeDefaults.VARIATIONS[type_name])


#* A copy of font that falls back on the fallback fonts (font itself if there are none):
#? Without them, Godot looks for a system font, slowly, for every control, and may find none.
#? all: the fallbacks as they are, for text the user writes. Else the taller ones are trimmed (_ui_fallbacks()).
func with_fallbacks(font: Font, all := false) -> Font:
	if font == null or _fallback_fonts.is_empty() or _fallback_fonts.has(font):
		return font
	#Ł A copy made here is made again from its source:
	var source: Font = _copy_sources.get(font, font)
	var copies := _ui_copies
	if all:
		copies = _all_copies
	if copies.has(source):
		return copies[source]
	var fallbacks := _fallback_fonts
	if not all:
		fallbacks = _ui_fallbacks(source)
	var copy: FontVariation
	#¦ 1. A variation (bold, italics...): a copy, which keeps its settings:
	if source is FontVariation:
		copy = source.duplicate() as FontVariation
	#¦ 2. A font file or system font: wrapped, rather than copying its glyphs:
	else:
		copy = FontVariation.new()
		copy.base_font = source
	var list: Array[Font] = []
	list.assign(copy.fallbacks)
	for fallback in fallbacks:
		if not list.has(fallback):
			list.append(fallback)
	copy.fallbacks = list
	copies[source] = copy
	_copy_sources[copy] = source
	return copy


#* The fallback fonts, those taller than font trimmed to its height:
#? A taller one (Myanmar, Arabic...) would make every button using font taller, whatever its text.
func _ui_fallbacks(font: Font) -> Array[Font]:
	var metrics := _metrics_font(font)
	var height := metrics.get_height(FALLBACK_TEST_SIZE)
	var result: Array[Font] = []
	for fallback in _fallback_fonts:
		if fallback is FontFile and fallback.get_height(FALLBACK_TEST_SIZE) > height:
			result.append(_trimmed_fallback(fallback, metrics))
		else:
			result.append(fallback)
	return result


#* The font whose ascent and descent font has: a variation's (bold, italics...) are its base font's:
func _metrics_font(font: Font) -> Font:
	var current := font
	for depth in MAX_BASE_DEPTH:
		var variation := current as FontVariation
		if variation == null or variation.base_font == null:
			break
		current = variation.base_font
	return current


#* A copy of fallback with no more ascent or descent than metrics, at every size up to MAX_TRIMMED_SIZE:
#? It still draws every character; only the height Godot reserves for it changes. Larger sizes keep its own.
func _trimmed_fallback(fallback: FontFile, metrics: Font) -> FontFile:
	var key := [fallback, metrics]
	if _trimmed.has(key):
		return _trimmed[key]
	var trimmed := fallback.duplicate() as FontFile
	for size in range(1, MAX_TRIMMED_SIZE + 1):
		trimmed.set_cache_ascent(0, size, minf(fallback.get_ascent(size), metrics.get_ascent(size)))
		trimmed.set_cache_descent(0, size, minf(fallback.get_descent(size), metrics.get_descent(size)))
	_trimmed[key] = trimmed
	return trimmed


#* Square the popup panels' corners where windows can't be transparent:
func _square_opaque_popups(target: Theme) -> void:
	if not is_inside_tree():
		return
	if get_tree().root.gui_embed_subwindows or DisplayServer.is_window_transparency_available():
		return
	#? Popups are separate windows - otherwise their square background shows around the rounded panel.
	for type_name in POPUP_PANELS:
		if not target.has_stylebox(&"panel", type_name):
			continue
		var style := target.get_stylebox(&"panel", type_name)
		if not style is StyleBoxFlat:
			continue
		var square := style.duplicate() as StyleBoxFlat
		square.set_corner_radius_all(0)
		target.set_stylebox(&"panel", type_name, square)


#* Every option's value in a Candy theme, base first:
#? An option the theme doesn't set takes the value of the option its "default_from" names
#? (one listed before it), or else its "default".
func _candy_values(theme_id: String, depth: int) -> Dictionary:
	var values: Dictionary = {}
	var info: Dictionary = _themes.get(theme_id, {})
	if info.get("kind", "") == "candy" and depth < MAX_BASE_DEPTH:
		var data := CandyVariantFile.read(str(info["path"]))
		var base := str(data.get("base", ""))
		if base != "" and base != theme_id:
			values = _candy_values(base, depth + 1)
		var own = data.get("values", {})
		if own is Dictionary:
			values.merge(own, true)
	if depth == 0:
		for entry in _options:
			if values.has(entry["id"]):
				continue
			var source := str(entry.get("default_from", ""))
			if source != "" and values.has(source):
				values[entry["id"]] = values[source]
			else:
				values[entry["id"]] = entry.get("default")
	return values


#* The overrides, with the options that follow an overridden one through "default_from":
#? Only those neither the theme nor the overrides set themselves.
func _with_followers(theme_id: String, overrides: Dictionary) -> Dictionary:
	var result := overrides.duplicate()
	var own := _candy_values(theme_id, 1)			#/ Depth 1: the theme's own values, unfilled
	for entry in _options:
		var source := str(entry.get("default_from", ""))
		if source == "" or not result.has(source):
			continue
		if result.has(entry["id"]) or own.has(entry["id"]):
			continue
		result[entry["id"]] = result[source]
	return result


#* A Candy theme's COLOR_DEFAULT_KEYS entry, or its base's:
func _candy_entry(theme_id: String, key: String, depth: int) -> Dictionary:
	var info: Dictionary = _themes.get(theme_id, {})
	if info.get("kind", "") != "candy" or depth >= MAX_BASE_DEPTH:
		return {}
	var data := CandyVariantFile.read(str(info["path"]))
	var own = data.get(key, {})
	if own is Dictionary and not own.is_empty():
		return own
	var base := str(data.get("base", ""))
	if base == "" or base == theme_id:
		return {}
	return _candy_entry(base, key, depth + 1)


#* The theme's Godot theme (the file, or a Candy theme's "godot_theme"), or null:
func _godot_theme(theme_id: String) -> Theme:
	var info: Dictionary = _themes.get(theme_id, {})
	var path := str(info.get("path", ""))
	if info.get("kind", "") == "candy":
		var extra := str(CandyVariantFile.read(path).get("godot_theme", ""))
		if extra == "":
			return null
		if not extra.begins_with("res://") and not extra.begins_with("user://") and not extra.is_absolute_path():
			extra = path.get_base_dir().path_join(extra)
		path = extra
	if path == "":
		return null
	var loaded = ResourceLoader.load(path, "Theme")
	if loaded is Theme:
		return loaded
	push_warning("CandyTheme: %s is not a Theme" % path)
	return null


func _apply_values(target_theme: Theme, values: Dictionary) -> void:
	for entry in _options:
		var id: String = entry["id"]
		if not values.has(id):
			continue
		var value = coerce(entry, values[id])
		if value == null:
			continue
		for target in entry.get("targets", []):
			if target is Array and target.size() >= 3:
				_apply_target(target_theme, target, value)


func _apply_target(target_theme: Theme, target: Array, value: Variant) -> void:
	var kind := str(target[0])
	for type_name in _as_list(target[1]):
		for item in _as_list(target[2]):
			match kind:
				"color":
					target_theme.set_color(item, type_name, value)
				"constant":
					target_theme.set_constant(item, type_name, int(value))
				"font":
					var font := picked_font(str(value))
					#% No font picked, or its file is gone: the theme's own:
					if font == null:
						continue
					if type_name == "":
						target_theme.default_font = font
					else:
						target_theme.set_font(item, type_name, font)
				"font_size":
					if type_name == "":
						target_theme.default_font_size = int(value)
					else:
						target_theme.set_font_size(item, type_name, int(value))
				"style":
					if target.size() >= 4:
						_set_style_property(_style(target_theme, type_name, item), str(target[3]), value)
				"icon_box":
					target_theme.set_icon(item, type_name, _outline_icon(value, false))
				"icon_circle":
					target_theme.set_icon(item, type_name, _outline_icon(value, true))
				"icon_tint":
					var tinted := _tinted_icon(type_name, item, value)
					if tinted != null:
						target_theme.set_icon(item, type_name, tinted)
				_:
					push_warning("CandyTheme: unknown target kind '%s'" % kind)


#* target_theme's own stylebox, to change:
func _style(target_theme: Theme, type_name: String, style_name: String) -> StyleBox:
	var key := type_name + "/" + style_name
	if _owned_styles.has(key):
		return target_theme.get_stylebox(style_name, type_name)
	#Ł Copy it once per build, so a merged Godot theme's styleboxes are never changed:
	var box: StyleBox = null
	if target_theme.has_stylebox(style_name, type_name):
		box = target_theme.get_stylebox(style_name, type_name).duplicate()
	else:
		var fallback := ThemeDB.get_default_theme()
		var base: StringName = CandyThemeDefaults.base_type(StringName(type_name))
		if fallback.has_stylebox(style_name, base):
			box = fallback.get_stylebox(style_name, base).duplicate()
		else:
			box = StyleBoxFlat.new()
	target_theme.set_stylebox(style_name, type_name, box)
	_owned_styles[key] = true
	return box


func _set_style_property(box: StyleBox, property: String, value: Variant) -> void:
	var flat := box as StyleBoxFlat
	match property:
		"border_width":
			if flat != null:
				flat.set_border_width_all(int(value))
		"corner_radius":
			if flat != null:
				flat.set_corner_radius_all(int(value))
				_smooth_corners(flat)
		"corner_radius_top":
			if flat != null:
				flat.corner_radius_top_left = int(value)
				flat.corner_radius_top_right = int(value)
				_smooth_corners(flat)
		"content_margin":
			box.set_content_margin_all(float(value))
		"content_margin_h":
			box.content_margin_left = float(value)
			box.content_margin_right = float(value)
		"content_margin_v":
			box.content_margin_top = float(value)
			box.content_margin_bottom = float(value)
		_:
			if property in box:
				var current = box.get(property)
				if current is int:
					value = int(value)
				elif current is float:
					value = float(value)
				box.set(property, value)


#* Give rounded corners enough segments:
func _smooth_corners(flat: StyleBoxFlat) -> void:
	flat.corner_detail = maxi(flat.corner_detail, CORNER_DETAIL)	#/ Some Godot styleboxes (tabs) have 1, drawing a diagonal cut


#* A checkbox-sized outline icon, rounded square or circle:
func _outline_icon(color: Color, round_shape: bool) -> ImageTexture:
	var size := ICON_SIZE
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var half := size * 0.5 - 1.5
	var radius := 3.0
	if round_shape:
		radius = half
	var center := Vector2(size, size) * 0.5
	for y in size:
		for x in size:
			var offset := (Vector2(x + 0.5, y + 0.5) - center).abs() - Vector2(half - radius, half - radius)
			var distance := Vector2(maxf(offset.x, 0.0), maxf(offset.y, 0.0)).length() - radius
			#? Anti-aliased ring, ICON_LINE wide, inside the edge.
			var coverage := clampf(0.5 - (absf(distance + ICON_LINE * 0.5) - ICON_LINE * 0.5), 0.0, 1.0)
			image.set_pixel(x, y, Color(color, color.a * coverage))
	return ImageTexture.create_from_image(image)


#* Godot's own icon for a type, filled with color:
func _tinted_icon(type_name: String, icon_name: String, color: Color) -> ImageTexture:
	var texture := CandyThemeDefaults.default_icon(StringName(type_name), StringName(icon_name))
	if texture == null:
		return null
	var source := texture.get_image()
	if source == null:
		return null
	var image := Image.create_empty(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in source.get_width():
			image.set_pixel(x, y, Color(color, color.a * source.get_pixel(x, y).a))
	return ImageTexture.create_from_image(image)


#* An option's value as its type needs, or null:
func coerce(entry: Dictionary, value: Variant) -> Variant:
	match str(entry.get("type", "")):
		"color":
			if value is Color:
				return value
			if value is String:
				var parsed = str_to_var(value)
				if parsed is Color:
					return parsed
				if Color.html_is_valid(value):
					return Color.html(value)
			return null
		"number":
			if value is int or value is float:
				return value
			if value is String and value.is_valid_float():
				return value.to_float()
			return null
		"font":
			if value is String:
				return value
			return null
	return value


func _as_list(value: Variant) -> Array:
	if value is Array:
		return value
	return [str(value)]


#& Loading

func _load_options() -> void:
	_options.clear()
	_option_index.clear()
	var folders: Array = [BUILTIN_OPTIONS]
	folders.append_array(_mod_folders(MOD_OPTIONS))
	for folder in folders:
		for file_name in _files_in(folder, CANDY_EXTENSIONS):
			var entries = CandyVariantFile.read(folder.path_join(file_name)).get("options", [])
			if not entries is Array:
				push_warning("CandyTheme: %s has no \"options\" list" % file_name)
				continue
			for entry in entries:
				if entry is Dictionary and str(entry.get("id", "")) != "":
					_add_option(entry)


func _add_option(entry: Dictionary) -> void:
	var id := str(entry["id"])
	if _option_index.has(id):
		_options[_options.find(_option_index[id])] = entry
	else:
		_options.append(entry)
	_option_index[id] = entry


func _find_themes() -> void:
	_themes.clear()
	_add_themes(BUILTIN_THEMES, "Built-in")
	if DirAccess.dir_exists_absolute(MODS_DIR):
		for mod in DirAccess.get_directories_at(MODS_DIR):
			_add_themes(MODS_DIR.path_join(mod).path_join(MOD_THEMES), mod)
	_add_themes(USER_THEMES, "User")


#* Add a folder's themes, and its category folders':
func _add_themes(folder: String, source: String) -> void:
	_add_folder_themes(folder, source, "")
	for sub_folder in _folders_in(folder):
		_add_folder_themes(folder.path_join(sub_folder), source, sub_folder.replace("_", " "))


func _add_folder_themes(folder: String, source: String, category: String) -> void:
	for file_name in _files_in(folder, CANDY_EXTENSIONS + GODOT_EXTENSIONS):
		var path := folder.path_join(file_name)
		var id := file_name.get_basename()
		var theme_name := id.capitalize()
		var kind := "godot"
		if CANDY_EXTENSIONS.has(file_name.get_extension().to_lower()):
			kind = "candy"
			theme_name = str(CandyVariantFile.read(path).get("name", theme_name))
		_themes[id] = {"id": id, "name": theme_name, "path": path, "kind": kind, "source": source,
			"category": category}


#* Load the fallback fonts: the user's, then the mods', then the built-in ones:
#? The user's come first, so a font dropped in (Japanese, say) wins over a built-in one
#? for the characters both have. In each folder, the fonts made for the language shown come first.
func _load_fallback_fonts() -> void:
	_fallback_fonts.clear()
	_ui_copies.clear()
	_all_copies.clear()
	_copy_sources.clear()
	_trimmed.clear()
	var folders: Array = [USER_FONTS]
	folders.append_array(_mod_folders(MOD_FONTS))
	folders.append(BUILTIN_FONTS)
	var language := CandyLocale.current_language()
	if language == CandyLocale.SYSTEM_LANGUAGE:
		language = OS.get_locale()
	for folder: String in folders:
		var for_locale: Array[Font] = []		#/ Made for the exact locale ("zh_TW")
		var for_language: Array[Font] = []		#/ Made for its language ("zh")
		var for_default: Array[Font] = []		#/ Made for DEFAULT_FONT_LANGUAGE
		var others: Array[Font] = []
		for file_name in _files_in(folder, FONT_EXTENSIONS):
			var path := folder.path_join(file_name)
			var font: Font = null
			#¦ 1. Built-in: imported by Godot:
			if path.begins_with("res://"):
				font = load(path) as Font
			#¦ 2. Dropped in: read as it is:
			else:
				var file_font := FontFile.new()
				if file_font.load_dynamic_font(path) == OK:
					font = file_font
			if font == null:
				push_warning("CandyTheme: couldn't load the font %s" % path)
				continue
			#Ł Order: the language shown (its exact locale first), then DEFAULT_FONT_LANGUAGE, then the others:
			match _font_language_match(font, language):
				2:
					for_locale.append(font)
				1:
					for_language.append(font)
				_:
					if _font_language_match(font, DEFAULT_FONT_LANGUAGE) > 0:
						for_default.append(font)
					else:
						others.append(font)
		_fallback_fonts.append_array(for_locale)
		_fallback_fonts.append_array(for_language)
		_fallback_fonts.append_array(for_default)
		_fallback_fonts.append_array(others)


#* How well font is made for language, by the language support set in its import settings ("ja", "zh_TW"...):
#? 2: the exact locale, 1: its language, 0: neither.
#? Chinese, Japanese and Korean fonts draw the characters they share each in their own way.
func _font_language_match(font: Font, language: String) -> int:
	var file_font := font as FontFile
	if file_font == null:
		return 0
	var result := 0
	for supported in file_font.get_language_support_overrides():
		if not file_font.get_language_support_override(supported):
			continue
		if supported == language:
			return 2
		if supported == language.get_slice("_", 0):
			result = 1
	return result


func _mod_folders(subfolder: String) -> Array:
	var folders: Array = []
	if DirAccess.dir_exists_absolute(MODS_DIR):
		for mod in DirAccess.get_directories_at(MODS_DIR):
			folders.append(MODS_DIR.path_join(mod).path_join(subfolder))
	return folders


#* File names in a folder with one of the extensions:
func _files_in(folder: String, extensions: Array) -> PackedStringArray:
	var result := PackedStringArray()
	if not DirAccess.dir_exists_absolute(folder):
		return result
	var names := DirAccess.get_files_at(folder)
	names.append_array(ResourceLoader.list_directory(folder))	#/ For exported builds
	for file_name in names:
		file_name = file_name.trim_suffix(".remap")
		if extensions.has(file_name.get_extension().to_lower()) and not result.has(file_name):
			result.append(file_name)
	result.sort()
	return result


#* A folder's sub-folders, sorted:
func _folders_in(folder: String) -> PackedStringArray:
	var result := PackedStringArray()
	if not DirAccess.dir_exists_absolute(folder):
		return result
	var names := DirAccess.get_directories_at(folder)
	#Ł ResourceLoader's ("name/"), for exported builds:
	for entry in ResourceLoader.list_directory(folder):
		if entry.ends_with("/"):
			names.append(entry.trim_suffix("/"))
	for folder_name in names:
		if not folder_name.begins_with(".") and not result.has(folder_name):
			result.append(folder_name)
	result.sort()
	return result


#* Apply the last session's profile theme, before a profile opens:
func _apply_last_session() -> void:
	var session := CandyProfiles.get_last_session()
	var user := str(session.get("user", ""))
	var profile := str(session.get("profile", ""))
	if user == "" or profile == "":
		return
	var data := CandyProfiles.read_settings_file(CandyProfiles.settings_path(user, profile))
	var theme_id := str(data.get(THEME_SETTING, DEFAULT_THEME))
	build(theme_id, overrides_of(data.get(OVERRIDES_SETTING, {}), theme_id))
