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

const BUILTIN_DIR := "res://Field_Checks"
const MODS_DIR := "user://Mods"
const CHECKS_SUBDIR := "Field_Checks"

const ERROR := "error"
const WARNING := "warning"
const NOTICE := "notice"
#^ Most severe first (display order):
const SEVERITY_ORDER := [ERROR, WARNING, NOTICE]
#^ Theme type by severity:
const THEME_TYPES := {
	ERROR: CandyThemeDefaults.ERROR,
	WARNING: CandyThemeDefaults.WARNING,
	NOTICE: CandyThemeDefaults.NOTE,
}
#^ Severity names in the tooltip:
const SEVERITY_NAMES := {ERROR: "Error", WARNING: "Warning", NOTICE: "Notice"}	#/ translatable
#^ "No override" value:
const NOT_SET_VALUE := "null"

var _checks: Dictionary = {}    #/ check id -> Callable(config, context) -> Array
var _expression_checks: Dictionary = {}    #/ ids of checks that take expressions
var _instances: Array = []      #/ Keeps the check instances alive
var _unknown_reported: Dictionary = {}


func _ready() -> void:
	_load_dir(BUILTIN_DIR)
	if DirAccess.dir_exists_absolute(MODS_DIR):
		for mod in DirAccess.get_directories_at(MODS_DIR):
			_load_dir(MODS_DIR.path_join(mod).path_join(CHECKS_SUBDIR))


#* Register every .gd in a folder under its file name:
func _load_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for file_name in ResourceLoader.list_directory(path):	#/ Lists .gd even in an exported build
		if not file_name.ends_with(".gd"):
			continue
		var script := load(path.path_join(file_name)) as GDScript
		if script == null or not script.can_instantiate():
			push_warning("CandyChecks: %s could not be loaded" % file_name)
			continue
		var instance = script.new()
		if not instance is Object or not instance.has_method("check"):
			push_warning("CandyChecks: %s has no check(config, context)" % file_name)
			continue
		_instances.append(instance)
		var looks_at_expressions := bool(script.get_script_constant_map().get("EXPRESSIONS", false))
		register_check(file_name.get_basename(), Callable(instance, "check"), looks_at_expressions)


#* Register a check:
#? expressions: also runs on {expression} values.
func register_check(id: String, check_callable: Callable, expressions: bool = false) -> void:
	_checks[id] = check_callable
	if expressions:
		_expression_checks[id] = true
	else:
		_expression_checks.erase(id)


func has_check(id: String) -> bool:
	return _checks.has(id)


#& Running checks

#* The messages of a spec's checks under key ("checks" / "entry_checks"):
func messages(spec: Dictionary, context: CandyCheckContext, key: String = "checks") -> Array:
	var result: Array = []
	var checks = spec.get(key, [])
	if not checks is Array or checks.is_empty():
		return result
	var value := context.value.strip_edges()
	var value_is_expression := is_expression(value)
	var skip_value := value == NOT_SET_VALUE and str(spec.get("default", "")) == NOT_SET_VALUE
	for config in checks:
		if config is String:
			config = {"check": config}
		if not config is Dictionary:
			continue
		var id := str(config.get("check", ""))
		if not _checks.has(id):
			if not _unknown_reported.has(id):
				_unknown_reported[id] = true
				push_warning("CandyChecks: unknown check '%s'" % id)
			continue
		#% Skip expressions and "null" as the file's header says:
		if context.checks_value and skip_value:
			continue
		if (context.checks_value or key == "entry_checks") and value_is_expression \
				and not _expression_checks.has(id) and not bool(config.get("expressions", false)):
			continue
		var found = _checks[id].call(config, context)
		if not found is Array:
			continue
		for item in found:
			if item is Dictionary and str(item.get("text", "")) != "":
				result.append(message(str(item.get("severity", NOTICE)),
					CandyFieldHelpButton.with_symbols(str(item["text"]))))
	#Ł Most severe first:
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _rank(a["severity"]) < _rank(b["severity"]))
	return result


func message(severity: String, text: String) -> Dictionary:
	if not SEVERITY_ORDER.has(severity):
		severity = NOTICE
	return {"severity": severity, "text": text}


func _rank(severity: String) -> int:
	return SEVERITY_ORDER.find(severity)


#* Show messages in label:
func show_messages(label: Label, found: Array) -> void:
	if label == null:
		return
	if found.is_empty():
		label.text = ""
		label.tooltip_text = ""
		return
	#Ł The most severe + how many more; all in the tooltip:
	var first: Dictionary = found[0]
	label.text = str(first["text"])
	if found.size() > 1:
		label.text += " (+%d)" % (found.size() - 1)
	var lines: PackedStringArray = []
	for item in found:
		lines.append("%s: %s" % [CandyLocale.t(SEVERITY_NAMES[item["severity"]]), item["text"]])
	label.tooltip_text = "\n".join(lines)
	label.theme_type_variation = THEME_TYPES[first["severity"]]


#* Make a message label:
#? Always present, so a message never changes the height.
func new_message_label() -> Label:
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_PASS  #/ For the tooltip
	label.theme_type_variation = CandyThemeDefaults.NOTE
	return label


#& Helpers for checks

#* One of the project's Candy DE symbols:
func symbol(key: String) -> String:
	return CandyDropdowns.symbol(key)


#* Whether text is an expression:
func is_expression(text: String) -> bool:
	var expression := symbol("expression")
	return expression != "" and text.strip_edges().begins_with(expression)


#* Whether text is a whole number ("5", "-1", "+2"):
func is_whole(text: String) -> bool:
	return text.strip_edges().is_valid_int()


#* Whether text is a number:
func is_number(text: String) -> bool:
	var trimmed := text.strip_edges()
	return trimmed.is_valid_int() or trimmed.is_valid_float()


#* text as a number (0.0 if not one):
func to_number(text: String) -> float:
	if not is_number(text):
		return 0.0
	return text.strip_edges().to_float()


#* A time in seconds, -1.0 if not one:
#? Seconds or SS.xx / MM:SS.xx / HH:MM:SS.xx; no sign, no "f=".
func time_seconds(text: String) -> float:
	var trimmed := text.strip_edges()
	if trimmed == "":
		return -1.0
	var parts := trimmed.split(":")
	if parts.size() > 3:
		return -1.0
	var seconds := 0.0
	for i in parts.size():
		var part := parts[i].strip_edges()
		var last := i == parts.size() - 1
		if last:
			if not (part.is_valid_float() or part.is_valid_int()) or part.begins_with("-") or part.begins_with("+"):
				return -1.0
			seconds = seconds * 60.0 + part.to_float()
		else:
			if not part.is_valid_int() or part.begins_with("-") or part.begins_with("+"):
				return -1.0
			seconds = seconds * 60.0 + float(part.to_int())
	return seconds


#* Whether text is a timestamp rather than seconds:
func is_timestamp(text: String) -> bool:
	return text.contains(":")


#* Seconds for messages ("90", "2.5"):
func seconds_text(seconds: float) -> String:
	if is_equal_approx(seconds, roundf(seconds)):
		return str(int(roundf(seconds)))
	return str(snappedf(seconds, 0.01))


#* Read a frame target "f=N":
func frame_target(text: String) -> Dictionary:
	var trimmed := text.strip_edges()
	if not trimmed.to_lower().begins_with("f="):
		return {"frames": false, "valid": false}
	var number := trimmed.substr(2).strip_edges()
	return {"frames": true, "valid": is_number(number) and number.to_float() >= 0.0}


#* Whether a _Play's Duration plays past its loops (CandyPlayDuration.read()):
#? 1 yes, 0 no, -1 unknown ({expression}).
func duration_state(text: String) -> int:
	var trimmed := text.strip_edges()
	if is_expression(trimmed):
		return -1
	var frames := frame_target(trimmed)
	if frames["frames"]:
		if frames["valid"] and trimmed.substr(2).strip_edges().to_float() > 0.0:
			return 1
		return 0
	if time_seconds(trimmed.trim_prefix("+")) > 0.0:	#/ A time above 0
		return 1
	return 0


#* Read a relative frame move "f+N" / "f-N" (CandyPlayback.resolve_relative_time()):
func relative_frames(text: String) -> Dictionary:
	var trimmed := text.strip_edges()
	var lowered := trimmed.to_lower()
	if not lowered.begins_with("f+") and not lowered.begins_with("f-"):
		return {"frames": false, "valid": false, "count": "", "forward": false}
	var number := trimmed.substr(2).strip_edges()
	return {"frames": true, "valid": is_number(number) and number.to_float() >= 0.0, "count": number,
		"forward": lowered.begins_with("f+")}


#* Split a comma-separated list (trimmed, no empty items):
func split_list(text: String) -> PackedStringArray:
	return CandyProjectScripts.split_list(text)


#* Whether a comma-separated list has an empty item ("a,,b", "a,"):
func has_empty_item(text: String) -> bool:
	var trimmed := text.strip_edges()
	if trimmed == "":
		return false
	for item in trimmed.split(","):
		if item.strip_edges() == "":
			return true
	return false


#* One kind of project data ("Actors", "Roles"...), empty if unknown:
func project_data(kind: String) -> PackedStringArray:
	return CandyDropdowns.project_data(kind)


#* Whether list holds text (exactly, or ignoring case):
func has_text(list: Variant, text: String, ignore_case: bool = false) -> bool:
	if not (list is Array or list is PackedStringArray):
		return false
	for item in list:
		if str(item) == text or (ignore_case and str(item).to_lower() == text.to_lower()):
			return true
	return false


#* A role reference's name ("°guard" -> "guard"), "" if not one:
func role_name(text: String) -> String:
	var role_symbol := symbol("role")
	if role_symbol == "" or not text.begins_with(role_symbol):
		return ""
	return text.substr(role_symbol.length())


#* The variation database's languages:
func languages() -> Array:
	var result: Array = []
	var data = CandyProfiles.get_setting(CandyVariationData.DATA_KEY, {})
	if data is Dictionary and data.get("languages") is Array:
		for entry in data["languages"]:
			if entry is Dictionary:
				result.append(str(entry.get("name", "")))
	if result.is_empty():
		result.append(CandyVariationData.DEFAULT_LANGUAGE)
	return result


#* Every value a dropdown's items write, submenus included:
func item_values(items: Array, dropdown_context: Dictionary = {}) -> Array:
	var result: Array = []
	for raw in items:
		var item := CandyDropdowns.normalize_item(raw)
		if item["separator"]:
			continue
		if not item["items"].is_empty():
			result.append_array(item_values(item["items"], dropdown_context))
		elif item["config"] is Dictionary and item["config"].has("provider"):
			result.append_array(item_values(CandyDropdowns.get_items(item["config"], dropdown_context), dropdown_context))
		else:
			result.append(str(item["value"]))
	return result


#* Fill text's placeholders (‹value›, ‹entry›, ‹Id›):
#? extra adds placeholders ({ "name": "Rain" } fills ‹name›).
#? defaults: value for an empty sibling ({ "Actor_Key": "DisplayName" }).
func fill(text: String, context: CandyCheckContext, extra: Dictionary = {}, defaults: Dictionary = {}) -> String:
	if not "‹" in text:
		return text
	var result := text
	for key in extra:
		result = result.replace("‹%s›" % str(key), str(extra[key]))
	result = result.replace("‹value›", context.value.strip_edges())
	if "‹entry›" in result:
		result = result.replace("‹entry›", context.entry_key())
	var placeholder := RegEx.create_from_string("‹([^‹›]+)›")
	for found in placeholder.search_all(result):
		var id := found.get_string(1)
		var sibling := context.sibling(id)
		if sibling == "" and defaults.has(id):
			sibling = str(defaults[id])
		result = result.replace(found.get_string(), sibling)
	return result


#* Whether file_name is in values, as Candy DE finds files:
func has_file(values: Array, file_name: String) -> bool:
	var wanted := file_name.strip_edges()
	if wanted == "":
		return false
	var without_extension := wanted.get_extension() == ""
	for value in values:
		var text := str(value)
		if text == wanted:
			return true
		#% "Rain" finds "Rain.ogg":
		if without_extension and text.get_basename() == wanted:
			return true
		#% A frame folder, listed with its "/":
		if text.trim_suffix("/") == wanted:
			return true
	return false


#* Whether a game project res:// or user:// path exists:
func project_path_exists(path: String) -> bool:
	var file_path := CandyResources.to_file_path(path)
	if file_path == "":
		return true		#/ Unknown (no project folder)
	if FileAccess.file_exists(file_path) or DirAccess.dir_exists_absolute(file_path):
		return true
	#% No extension - Candy DE adds the default one:
	if path.get_extension() == "":
		var folder := file_path.get_base_dir()
		if DirAccess.dir_exists_absolute(folder):
			for file_name in DirAccess.get_files_at(folder):
				if file_name.get_basename() == file_path.get_file():
					return true
	return false


#* A Paths folder key for messages ("*Portraits" -> "Portraits"):
func folder_label(key: String) -> String:
	return key.trim_prefix("*").replace("_", " ")


#* The messages of a file field, looked up in its dropdown list:
#? texts (‹name› the value, ‹folder› folder, "" for none):
#?   "missing"      (warning) not in the list, when the list is known
#?   "missing_path" (warning) a res:// or user:// path that doesn't exist
#?   "empty"        (notice) empty value
#?   "no_default"   (warning) empty value, and the list has no Default file
func file_messages(context: CandyCheckContext, texts: Dictionary, folder: String) -> Array:
	var value := context.value.strip_edges()
	var extra := {"name": value, "folder": folder}
	var result: Array = []
	if value == "":
		if str(texts.get("empty", "")) != "":
			result.append(message(NOTICE, fill(str(texts["empty"]), context, extra)))
		if str(texts.get("no_default", "")) != "":
			var defaults := context.dropdown_values()
			if not defaults.is_empty() and not has_file(defaults, "Default"):
				result.append(message(WARNING, fill(str(texts["no_default"]), context, extra)))
		return result
	if CandyResources.is_project_path(value):
		if str(texts.get("missing_path", "")) != "" and not project_path_exists(value):
			result.append(message(WARNING, fill(str(texts["missing_path"]), context, extra)))
		return result
	if str(texts.get("missing", "")) == "":
		return result
	var values := context.dropdown_values()
	if not values.is_empty() and not has_file(values, value):
		result.append(message(WARNING, fill(str(texts["missing"]), context, extra)))
	return result


#* The folder a file check names, from config's "folder":
#? A "folder_label" with no "folder" names it in words ("the speaker's voice folder").
func file_folder(config: Dictionary, context: CandyCheckContext) -> String:
	if config.has("folder_label") and not config.has("folder"):
		return CandyLocale.t(str(config["folder_label"]))
	var kind := str(config.get("folder", "entry"))
	var result := kind		#/ As written
	if kind == "entry":		#/ The entry whose folder is listed
		result = context.entry_name()
	elif kind == "dropdown":	#/ The dropdown's Paths folder
		var dropdown = context.spec.get("dropdown", {})
		if dropdown is Dictionary:
			result = folder_label(str(dropdown.get("folder", "")))
	if result == "" or is_expression(result):
		return CandyLocale.t("its folder")	#/ Unknown
	return result
