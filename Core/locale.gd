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

#^ Candy DC's own translation domain, so a game that embeds the Creator keeps its own language:
const DOMAIN := &"candy_dc"

const BUILTIN_TRANSLATIONS := "res://Translations"
const USER_TRANSLATIONS := "user://Translations"
const MODS_DIR := "user://Mods"
const MOD_TRANSLATIONS := "Translations"
const TRANSLATION_EXTENSIONS := ["po", "mo"]
#^ What the built-in translations' copies in USER_TRANSLATIONS were made from: { file name: MD5 of the copy }:
const COPIES_FILE := "user://Translation_Copies.txt"

#^ App settings, shared by every user and profile (the landing screen shows before a profile opens):
const APP_SETTINGS_FILE := "user://App_Settings.txt"
const LANGUAGE_SETTING := "language"
#^ Whether command names (schema titles) are translated, or stay as Candy DE's documentation writes them:
const COMMAND_NAMES_SETTING := "translate_command_names"
#^ Language setting values - the system's language, the source language, the test language:
const SYSTEM_LANGUAGE := ""
const SOURCE_LANGUAGE := "en"
const PSEUDO_LANGUAGE := "pseudo"
#^ The template's entry where a translation gives its language's own name ("Français"):
const LANGUAGE_NAME_TEXT := "English"
const LANGUAGE_NAME_CONTEXT := "language name"
#^ The titles Godot gives its dialogs (AcceptDialog, ConfirmationDialog):
const GODOT_DIALOG_TITLES := ["Alert!", "Please Confirm..."]
#^ Set on a scene's root once translate_scene() translated it:
const SCENE_TRANSLATED_META := &"candy_scene_translated"

var _domain: TranslationDomain
#^ The language chosen when Candy DC started (a change shows once it starts again):
var _language := SYSTEM_LANGUAGE
#^ Whether command names are translated, as when Candy DC started:
var _translate_command_names := false
var _locales: PackedStringArray = []      #/ The loaded translations' locales
var _language_names: Dictionary = {}      #/ locale -> the language's own name, from its translation


func _init() -> void:
	#? Set up here, before any other autoload builds text.
	_domain = TranslationServer.get_or_add_domain(DOMAIN)
	_copy_builtin_translations()
	_load_translations()
	_language = language_setting()
	_translate_command_names = command_names_setting()
	_apply_language(_language)


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


#& Translating

#* Translate text (text itself if there's no translation):
#? Pass the English text as a literal, so the template tool finds it:
#? CandyLocale.t("Save"), CandyLocale.t("Open", "verb"), CandyLocale.t("Not found in %s.") % folder
func t(text: String, context: String = "") -> String:
	if text == "":
		return text
	return String(_domain.translate(text, context))


#* Translate text into another language than the one shown (a language setting value, see language_setting()):
#? The text isn't found by the template tool: pass a literal marked elsewhere (a "#/ translatable" const).
func t_in(language: String, text: String, context: String = "") -> String:
	if text == "" or language == SOURCE_LANGUAGE:
		return text
	if language == PSEUDO_LANGUAGE:
		return _domain.pseudolocalize(text)
	if language == SYSTEM_LANGUAGE:
		language = OS.get_locale()
	for translation: Translation in _domain.find_translations(language, false):
		var message := String(translation.get_message(text, context))
		if message != "":
			return message
	return text


#* A command's name (its schema title), translated or in English as the setting says:
func command_title(title: String) -> String:
	if _translate_command_names:
		return t(title)
	return title


#* Translate text that depends on a number (singular / plural):
#? CandyLocale.tn("%d line", "%d lines", count) % count
func tn(singular: String, plural: String, count: int, context: String = "") -> String:
	return String(_domain.translate_plural(singular, plural, count, context))


#* Make node and everything in it use Candy DC's translations, and translate only what the code asks:
#? Godot's automatic translation would also translate the user's data (a choice named "Yes").
#? Call on every top node of Candy DC: the main scene, and each window outside it.
func claim(node: Node) -> void:
	node.set_translation_domain(DOMAIN)
	node.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED


#* Translate a scene's own texts (labels, buttons, tooltips), as written in the .tscn:
#? Call before the scene's scripts set texts of their own (its root's _enter_tree()). Only translates once.
func translate_scene(root: Node) -> void:
	if root.has_meta(SCENE_TRANSLATED_META):
		return
	root.set_meta(SCENE_TRANSLATED_META, true)
	for node in [root] + root.find_children("*", "", true, false):
		if node is Label or node is Button:
			node.text = t(node.text)
		if node is Control:
			node.tooltip_text = t(node.tooltip_text)
		if node is LineEdit:
			node.placeholder_text = t(node.placeholder_text)


#& Language

#* The language setting (SYSTEM_LANGUAGE, a locale or PSEUDO_LANGUAGE):
func language_setting() -> String:
	return str(CandyVariantFile.read(APP_SETTINGS_FILE).get(LANGUAGE_SETTING, SYSTEM_LANGUAGE))


#* Save the language setting, for the next start:
func set_language_setting(language: String) -> void:
	var data := CandyVariantFile.read(APP_SETTINGS_FILE)
	data[LANGUAGE_SETTING] = language
	CandyVariantFile.write(APP_SETTINGS_FILE, data)


#* Whether command names are translated (saved; shows from the next start):
func command_names_setting() -> bool:
	return bool(CandyVariantFile.read(APP_SETTINGS_FILE).get(COMMAND_NAMES_SETTING, false))


func set_command_names_setting(translated: bool) -> void:
	var data := CandyVariantFile.read(APP_SETTINGS_FILE)
	data[COMMAND_NAMES_SETTING] = translated
	CandyVariantFile.write(APP_SETTINGS_FILE, data)


#* Whether command names are translated now:
func translates_command_names() -> bool:
	return _translate_command_names


#* The language Candy DC shows now:
func current_language() -> String:
	return _language


#* The languages to choose from, each named in its own language: [ { "label", "value" } ]
func language_choices() -> Array:
	var choices: Array = [
		{"label": CandyLocale.t("System language (%s)") % language_name(OS.get_locale()), "value": SYSTEM_LANGUAGE},
		{"label": language_name(SOURCE_LANGUAGE), "value": SOURCE_LANGUAGE},
	]
	var named: Array = []
	for locale in _locales:
		if TranslationServer.standardize_locale(locale) != SOURCE_LANGUAGE:
			named.append({"label": language_name(locale), "value": locale})
	named.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["label"] < b["label"])
	choices.append_array(named)
	choices.append({"label": CandyLocale.t("Test language (for translators)"), "value": PSEUDO_LANGUAGE})
	return choices


#* A language's name in that language ("Français"), as its translation gives it, or else Godot's English name:
func language_name(locale: String) -> String:
	if locale == SOURCE_LANGUAGE:
		return LANGUAGE_NAME_TEXT
	var own := str(_language_names.get(locale, ""))
	if own == "":
		own = str(_language_names.get(locale.get_slice("_", 0), ""))
	if own == "":
		own = TranslationServer.get_locale_name(locale)
	return own


func _apply_language(language: String) -> void:
	var pseudo := language == PSEUDO_LANGUAGE
	_domain.pseudolocalization_enabled = pseudo
	if pseudo:
		#? Accents and longer words show the text that isn't translated, and where it overflows.
		_domain.pseudolocalization_accents_enabled = true
		_domain.pseudolocalization_double_vowels_enabled = false
		_domain.pseudolocalization_skip_placeholders_enabled = true
		_domain.pseudolocalization_expansion_ratio = 0.3
		_domain.pseudolocalization_prefix = "["
		_domain.pseudolocalization_suffix = "]"
		_domain.set_locale_override(SOURCE_LANGUAGE)
		return
	if language == SYSTEM_LANGUAGE:
		language = OS.get_locale()
	_domain.set_locale_override(language)


#& Loading

#* Copy the built-in translations to USER_TRANSLATIONS, where users can open and edit them:
#? A copy the user edited is kept; one left as copied follows the built-in file when it changes.
#? The built-in files still load after the user's, so texts a newer version adds show translated.
func _copy_builtin_translations() -> void:
	var copies := CandyVariantFile.read(COPIES_FILE)
	var changed := false
	for file_name in _files_in(BUILTIN_TRANSLATIONS):
		var source := BUILTIN_TRANSLATIONS.path_join(file_name)
		var target := USER_TRANSLATIONS.path_join(file_name)
		var source_md5 := FileAccess.get_md5(source)
		#% Already a copy of this version, or edited by the user:
		if FileAccess.file_exists(target):
			var target_md5 := FileAccess.get_md5(target)
			if target_md5 == source_md5 or target_md5 != str(copies.get(file_name, "")):
				continue
		var bytes := FileAccess.get_file_as_bytes(source)
		if bytes.is_empty():
			continue
		DirAccess.make_dir_recursive_absolute(USER_TRANSLATIONS)
		var file := FileAccess.open(target, FileAccess.WRITE)
		if file == null:
			push_warning("CandyLocale: couldn't copy %s to %s" % [source, target])
			continue
		file.store_buffer(bytes)
		file.close()
		copies[file_name] = source_md5
		changed = true
	if changed:
		CandyVariantFile.write(COPIES_FILE, copies)


#* Load every translation: the user's, then the mods', then the built-in ones:
func _load_translations() -> void:
	_domain.clear()
	_locales.clear()
	_language_names.clear()
	var folders: Array = [USER_TRANSLATIONS]
	if DirAccess.dir_exists_absolute(MODS_DIR):
		for mod in DirAccess.get_directories_at(MODS_DIR):
			folders.append(MODS_DIR.path_join(mod).path_join(MOD_TRANSLATIONS))
	folders.append(BUILTIN_TRANSLATIONS)
	for folder: String in folders:
		for file_name in _files_in(folder):
			var path := folder.path_join(file_name)
			var translation := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Translation
			if translation == null:
				push_warning("CandyLocale: couldn't load the translation %s" % path)
				continue
			_domain.add_translation(translation)
			if not _locales.has(translation.locale):
				_locales.append(translation.locale)
			#Ł Its language's own name (the first file that gives it wins, as for every text):
			var own_name := String(translation.get_message(LANGUAGE_NAME_TEXT, LANGUAGE_NAME_CONTEXT))
			if own_name != "" and not _language_names.has(translation.locale):
				_language_names[translation.locale] = own_name


func _files_in(folder: String) -> PackedStringArray:
	var result := PackedStringArray()
	if not DirAccess.dir_exists_absolute(folder):
		return result
	var names := DirAccess.get_files_at(folder)
	names.append_array(ResourceLoader.list_directory(folder))	#/ For exported builds
	for file_name in names:
		file_name = file_name.trim_suffix(".remap")
		if TRANSLATION_EXTENSIONS.has(file_name.get_extension().to_lower()) and not result.has(file_name):
			result.append(file_name)
	result.sort()
	return result


#& Godot's own texts

#* Translate the texts Godot writes itself (a text field's menu, a dialog's OK and Cancel...):
#? claim() turns automatic translation off; these never show the user's data, so they keep it.
func _on_node_added(node: Node) -> void:
	if node.get_translation_domain() != DOMAIN:
		return
	if node is PopupMenu and (node.get_parent() is LineEdit or node.get_parent() is TextEdit):
		node.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_ALWAYS
	elif node is FileDialog or node is ColorPicker:
		node.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_ALWAYS
	elif node is AcceptDialog:
		node.get_ok_button().auto_translate_mode = Node.AUTO_TRANSLATE_MODE_ALWAYS
		#% Godot's own title ("Alert!"), when the code hasn't set one:
		if GODOT_DIALOG_TITLES.has(node.title):
			node.title = t(node.title)
		if node is ConfirmationDialog:
			node.get_cancel_button().auto_translate_mode = Node.AUTO_TRANSLATE_MODE_ALWAYS
