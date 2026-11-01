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

const BUILTIN_DIR := "res://Dropdowns"
const MODS_DIR := "user://Mods"
const DROPDOWN_SUBDIR := "Dropdowns"
#^ A new SpriteFrames' animation:
const DEFAULT_ANIMATION := "default"
#^ Folder of an actor's or layer's SpriteFrames:
const SPRITE_FRAMES_FOLDER := "Sprite_Frames"
#^ The "not set" value:
const NOT_SET_VALUE := "null"
#^ Label of the "null" item, shown "No override (null)":
const NO_OVERRIDE_LABEL := "No override"	#/ translatable
#^ How "" shows - "Let the scene decide (empty)":
const EMPTY_VALUE_TEXT := "empty"	#/ translatable
const NO_OVERRIDE_TOOLTIP :="Overrides nothing: the actor, the UI element or the engine decides, or the setting stays as it is."	#/ translatable

var _providers: Dictionary = {}    #/ provider id -> Callable(config, context) -> Array
var _instances: Array = []    #/ Keeps the provider instances alive


func _ready() -> void:
	_load_dir(BUILTIN_DIR)
	if DirAccess.dir_exists_absolute(MODS_DIR):
		for mod in DirAccess.get_directories_at(MODS_DIR):
			_load_dir(MODS_DIR.path_join(mod).path_join(DROPDOWN_SUBDIR))


#* Register every .gd in a folder under its file name:
func _load_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	for file_name in ResourceLoader.list_directory(path):	#/ Lists .gd even in an exported build
		if not file_name.ends_with(".gd"):
			continue
		var script := load(path.path_join(file_name)) as GDScript
		if script == null or not script.can_instantiate():
			push_warning("CandyDropdowns: %s could not be loaded" % file_name)
			continue
		var instance = script.new()
		if not instance is Object or not instance.has_method("get_items"):
			push_warning("CandyDropdowns: %s has no get_items(config, context)" % file_name)
			continue
		_instances.append(instance)
		register_provider(file_name.get_basename(), Callable(instance, "get_items"))


func register_provider(id: String, provider: Callable) -> void:
	_providers[id] = provider


func has_provider(id: String) -> bool:
	return _providers.has(id)


#* Items for one dropdown config:
#? [] means no dropdown button.
func get_items(config: Dictionary, context: Dictionary) -> Array:
	if config.is_empty():
		return []
	var id := str(config.get("provider", "static"))
	if not _providers.has(id):
		push_warning("CandyDropdowns: unknown provider '%s'" % id)
		return []
	var items = _providers[id].call(config, context)
	if not items is Array:
		return []
	#? Each provider translates its own texts (the static one, the schema's).
	return items


#* Whether a field has a dropdown ("dropdown" key or "null" default):
func has_field_dropdown(spec: Dictionary) -> bool:
	if spec.get("dropdown") is Dictionary and not spec["dropdown"].is_empty():
		return true
	return _defaults_to_not_set(spec)


#* A field's dropdown items:
func field_items(spec: Dictionary, context: Dictionary) -> Array:
	var items: Array = []
	var config = spec.get("dropdown", {})
	if config is Dictionary:
		items = get_items(config, context)
	#% "null" default - a "No override (null)" item first, unless the list has its own "null" item:
	if not _defaults_to_not_set(spec):
		return items
	for item in items:
		if item is Dictionary and str(item.get("value", "")) == NOT_SET_VALUE and not item.has("items"):
			return items
	var result: Array = [{"label": CandyLocale.t(NO_OVERRIDE_LABEL), "value": NOT_SET_VALUE,
		"tooltip": CandyLocale.t(NO_OVERRIDE_TOOLTIP)}]
	if not items.is_empty():
		result.append({"separator": true})
	result.append_array(items)
	return result


func _defaults_to_not_set(spec: Dictionary) -> bool:
	return str(spec.get("default", "")) == NOT_SET_VALUE


#* Normalize one item, so every key exists:
func normalize_item(item: Variant) -> Dictionary:
	if not item is Dictionary:
		return {"label": str(item), "value": str(item), "text": str(item), "tooltip": "",
			"separator": false, "items": [], "config": item}
	var children = item.get("items", [])
	if not children is Array:
		children = []
	var label := str(item.get("label", item.get("value", "")))
	var value := str(item.get("value", ""))
	var separator := bool(item.get("separator", false))
	#Ł "text" - the label + its value when they differ ("On (1)"); label only for submenus and separators:
	var text := label
	if not separator and children.is_empty() and not item.has("provider") and value != label:
		text = "%s (%s)" % [label, _shown_value(value)]
	return {
		"label": label,
		"value": value,
		"text": text,
		"tooltip": str(item.get("tooltip", "")),
		"separator": separator,
		"items": children,
		"config": item,
	}


#* A value as shown after a label ("empty" for ""):
func _shown_value(value: String) -> String:
	if value == "":
		return CandyLocale.t(EMPTY_VALUE_TEXT)
	return value


#& Helpers for providers

#* The conversation of sibling config["conversation_field"], else the line's:
func target_conversation(config: Dictionary, context: Dictionary) -> String:
	var conversation := sibling_value(config, context, "conversation_field")
	if conversation != "":
		return conversation		#/ Even a missing one, so its lists come out empty
	var line_path = context.get("line_path", [])
	if line_path is Array and not line_path.is_empty():
		return str(line_path[0])
	return ""


#* The value of sibling field config[key]:
func sibling_value(config: Dictionary, context: Dictionary, key: String) -> String:
	var sibling := str(config.get(key, ""))
	var line_path = context.get("line_path", [])
	var field_path = context.get("field_path", [])
	if sibling == "" or not line_path is Array or not field_path is Array or field_path.is_empty():
		return ""
	var path: Array = field_path.slice(0, field_path.size() - 1) + [sibling]
	var value := str(CandyDialogue.get_field(line_path, path, "")).strip_edges()
	if value == "null":
		return ""
	return value


#* The entry whose folder a media dropdown lists:
func entry_name(config: Dictionary, context: Dictionary) -> String:
	if config.has("entry_field"):
		return sibling_value(config, context, "entry_field")
	var field_path = context.get("field_path", [])
	if not field_path is Array or field_path.size() < 2:
		return ""
	var entry := str(field_path[field_path.size() - 2])
	if str(config.get("entry_part", "")) == "last":	#/ "Actors/Hero" -> "Hero"
		return entry.get_file()
	return entry


#* The file path of a SpriteFrames, as Candy DE finds it:
func sprite_frames_path(file_name: String, entry: String, folder_key: String) -> String:
	if file_name == "":
		return ""
	var expression := symbol("expression")
	if expression != "" and file_name.begins_with(expression):
		return ""
	if CandyResources.is_project_path(file_name):
		return CandyResources.to_file_path(file_name)
	var folder := CandyResources.resource_folder(folder_key)
	if folder == "" or entry == "":
		return ""
	return folder.path_join(entry).path_join(SPRITE_FRAMES_FOLDER).path_join(file_name)	#/ No extension guessed: the game sets it


#* Give item a hover preview of path (file or frame folder):
#? preview_size: a CandyMediaPreview.SIZES size.
func with_preview(item: Dictionary, preview_size: String, path: String, animation: String = "") -> Dictionary:
	if preview_size == "" or path == "":
		return item
	var preview := {"path": path, "size": preview_size}
	if animation != "":
		preview["animation"] = animation
	item["preview"] = preview
	return item


#* One kind of project data ("Actors", "Roles"...), its "In use" list:
func project_data(kind: String) -> PackedStringArray:
	var kinds = CandyProfiles.get_setting(CandyProjectDataPage.SCRIPTS_KEY, {})
	if not kinds is Dictionary or not kinds.get(kind) is Dictionary:
		return PackedStringArray()
	return CandyProjectScripts.split_list(str(kinds[kind].get("Data", "")))


#* Items for an actor key - a "Roles" submenu, then every actor:
#? prefix goes before each value ("Actors/" for a CS target).
func actor_items(prefix: String = "") -> Array:
	var items: Array = []
	var actors := project_data("Actors")
	var roles := project_data("Roles")

	if not roles.is_empty():
		var role_symbol := symbol("role")
		var role_items: Array = []
		for role in roles:
			var value := role
			if role_symbol != "" and not role.begins_with(role_symbol):
				value = role_symbol + role
			role_items.append({"label": value, "value": prefix + value})
		items.append({"label": CandyLocale.t("Roles"), "items": role_items})
		if not actors.is_empty():
			items.append({"separator": true})

	for actor in actors:
		items.append({"label": actor, "value": prefix + actor})
	return items


#* The animation names of a .tres SpriteFrames, read as text:
func sprite_frames_animations(path: String) -> Array:
	if path.get_extension().to_lower() != "tres" or not FileAccess.file_exists(path):
		return []
	var text := FileAccess.get_file_as_string(path)
	if not RegEx.create_from_string("(?m)^animations\\s*=").search(text):
		return [DEFAULT_ANIMATION]	#/ No animations stored
	#Ł Each animation's "name" (animations = [{ "frames": [...], "loop": true, "name": &"walk", "speed": 5.0 }]):
	var names: Array = []
	var key := RegEx.create_from_string("\"name\"\\s*:\\s*&?\"((?:[^\"\\\\]|\\\\.)*)\"")
	for found in key.search_all(text):
		var animation := found.get_string(1).c_unescape()
		if not names.has(animation):
			names.append(animation)
	return names


#* One of the project's Candy DE symbols ("" if not set):
func symbol(key: String) -> String:
	var symbols = CandyProfiles.get_setting(CandySymbolsPage.SYMBOLS_KEY, {})
	if not symbols is Dictionary:
		return ""
	return str(symbols.get(key, ""))
