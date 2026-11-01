#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDocsLibrary

const INFO_FILE := "database.json"
const PAGE_EXTENSIONS: Array[String] = ["txt"]
const HEADER_FILE := "_header.txt"
const FOOTER_FILE := "_footer.txt"
const ABOUT_FOLDER := "_About"
const DEFAULT_LANGUAGE := "English"
const NO_ORDER := 100000
const MAX_DEPTH := 8
#^ Godot's BBCode tags, names a database tag can't use:
const BUILT_IN_TAGS: Array[String] = ["b", "i", "u", "s", "code", "char", "p", "br", "hr", "center", "left", "right", "fill", "indent", "url", "hint", "img", "font", "font_size", "opentype_features", "lang", "table", "cell", "ul", "ol", "lb", "rb", "lrm", "rlm", "lre", "rle", "lro", "rlo", "pdf", "alm", "lri", "rli", "fsi", "pdi", "zwj", "zwnj", "wj", "shy", "color", "bgcolor", "fgcolor", "outline_size", "outline_color", "dropcap", "wave", "tornado", "shake", "fade", "rainbow", "pulse"]
#^ ...except these, which a database can restyle:
const RESTYLED_TAGS: Array[String] = ["url", "code"]

static var _tag_regex: RegEx = null


#& Databases

#* Find every database in the folders, sorted by title:
#? Each: { id, title, description, home, default_language, path, versions
#?   (newest first), style, theme, theme_name, header, header_scrolls,
#?   footer, footer_scrolls, version_hint, tags }.
static func scan(roots: Array) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var seen: Dictionary = {}
	for root in roots:
		_scan_folder(str(root), found, seen, 0)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a["title"]).naturalnocasecmp_to(str(b["title"])) < 0)
	return found


static func _scan_folder(path: String, found: Array[Dictionary], seen: Dictionary, depth: int) -> void:
	if depth > MAX_DEPTH or not DirAccess.dir_exists_absolute(path):
		return
	if FileAccess.file_exists(path.path_join(INFO_FILE)):
		_add_database(path, found, seen)
		return
	for folder in DirAccess.get_directories_at(path):
		if folder.begins_with("."):
			continue
		_scan_folder(path.path_join(folder), found, seen, depth + 1)


static func _add_database(path: String, found: Array[Dictionary], seen: Dictionary) -> void:
	var info := read_json(path.path_join(INFO_FILE))
	var id := str(info.get("id", path.get_file()))
	if seen.has(id):
		push_warning("CandyDocsLibrary: two databases share the id \"%s\" (%s); only the first is used." % [id, path])
		return
	seen[id] = true
	var versions: Array[String] = []
	for folder in DirAccess.get_directories_at(path):
		if not folder.begins_with(".") and not folder.begins_with("_"):
			versions.append(folder)
	versions.sort_custom(version_is_newer)
	var tags: Dictionary = {}
	if info.get("tags") is Dictionary:
		for tag_name in info["tags"]:
			if not info["tags"][tag_name] is Dictionary:
				continue
			var tag := str(tag_name)
			if not tag.is_valid_ascii_identifier() or (BUILT_IN_TAGS.has(tag) and not RESTYLED_TAGS.has(tag)):
				push_warning("CandyDocsLibrary: \"%s\" can't be a tag of the database \"%s\" (a tag is a name made of letters, digits and _, and not one of Godot's own BBCode tags)." % [tag, id])
				continue
			tags[tag] = info["tags"][tag_name]
	found.append({
		"id": id,
		"title": str(info.get("title", prettify(path.get_file()))),
		"description": str(info.get("description", "")),
		"home": str(info.get("home", "")),
		"default_language": str(info.get("default_language", DEFAULT_LANGUAGE)),
		"path": path,
		"versions": versions,
		"style": _block(info, "style"),
		"theme": _block(info, "theme"),
		"theme_name": str(info.get("theme_name", "")),
		"header": str(info.get("header", "")),
		"header_scrolls": str(info.get("header_scrolls", "1")) != "0",
		"footer": str(info.get("footer", "")),
		"footer_scrolls": str(info.get("footer_scrolls", "1")) != "0",
		"version_hint": _block(info, "version_hint"),
		"tags": tags,
	})


static func _block(info: Dictionary, key: String) -> Dictionary:
	if info.get(key) is Dictionary:
		return info[key]
	return {}


static func read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		return data
	return {}


#* Whether path is folder or inside it (both simplified):
static func is_inside(path: String, folder: String) -> bool:
	return path == folder or path.begins_with(folder.trim_suffix("/") + "/")


#& Versions and languages

#* Whether version a is newer than b ("1.10.0" > "1.9.0", "v" ignored):
static func version_is_newer(a: String, b: String) -> bool:
	var parts_a := a.trim_prefix("v").split(".")
	var parts_b := b.trim_prefix("v").split(".")
	for index in maxi(parts_a.size(), parts_b.size()):
		var part_a := "0"
		var part_b := "0"
		if index < parts_a.size():
			part_a = parts_a[index]
		if index < parts_b.size():
			part_b = parts_b[index]
		if part_a == part_b:
			continue
		if part_a.is_valid_int() and part_b.is_valid_int():
			return int(part_a) > int(part_b)
		return part_a.naturalnocasecmp_to(part_b) > 0
	return false


#* The database version the Godot project has installed (version_hint):
static func hinted_version(database: Dictionary, project_path: String) -> String:
	var hint: Dictionary = database["version_hint"]
	var file_path := str(hint.get("file", ""))
	#% The "res://" file is only looked for in project_path:
	if project_path.is_empty() or not file_path.begins_with("res://"):
		return ""
	var relative := file_path.trim_prefix("res://")
	if not CandyGitHubSource.is_safe_relative_path(relative):
		return ""
	var value: Variant = read_json(project_path.path_join(relative))
	for key in str(hint.get("key", "version")).split("."):
		if value is Dictionary and value.has(key):
			value = value[key]
		else:
			return ""
	var wanted := str(value).trim_prefix("v")
	for version: String in database["versions"]:
		if version.trim_prefix("v") == wanted:
			return version
	return ""


#* A version's languages (its sub-folders), sorted:
static func languages(database: Dictionary, version: String) -> Array[String]:
	var found: Array[String] = []
	for folder in DirAccess.get_directories_at(str(database["path"]).path_join(version)):
		if not folder.begins_with(".") and not folder.begins_with("_"):
			found.append(folder)
	found.sort_custom(func(a: String, b: String) -> bool:
		return a.naturalnocasecmp_to(b) < 0)
	return found


#* Index in available of the language to open, -1 if none fits:
static func pick_language(database: Dictionary, available: Array[String], remembered: String) -> int:
	for candidate: String in [remembered, str(database["default_language"])]:
		var key := _language_key(candidate)	#/ Case-insensitive, "_" = space
		if key.is_empty():
			continue
		for index in available.size():
			if _language_key(available[index]) == key:
				return index
	return -1


static func _language_key(language: String) -> String:
	return language.replace("_", " ").strip_edges().to_lower()


#* The header file - language's, else version's, else database's ("" if none):
static func header_file(database: Dictionary, version: String, language: String) -> String:
	return _band_file(database, version, language, str(database["header"]), HEADER_FILE)


#* The footer file, found like the header's:
static func footer_file(database: Dictionary, version: String, language: String) -> String:
	return _band_file(database, version, language, str(database["footer"]), FOOTER_FILE)


#* A header's or footer's file - language's, else version's, else database's ("" if none):
#? file_name - the name database.json gives it ("" for default_name).
static func _band_file(database: Dictionary, version: String, language: String, file_name: String, default_name: String) -> String:
	var database_path := str(database["path"])
	if file_name.is_empty():
		file_name = default_name
	for folder: String in [database_path.path_join(version).path_join(language), database_path.path_join(version), database_path]:
		var candidate := folder.path_join(file_name).simplify_path()
		if is_inside(candidate, database_path) and FileAccess.file_exists(candidate):
			return candidate
	return ""


#& Pages

#* Read one language of a version:
#? Node: { "kind": "category", "id", "title", "order", "children" } or
#?   { "kind": "page", "id", "title", "order", "file" } (+ "children" when it
#?   stands in for a folder of its name).
#? Page: { "title", "file", "search" (plain lower-case text) }, + "about": true.
static func load_version(database: Dictionary, version: String, language: String) -> Dictionary:
	var pages: Dictionary = {}
	var tree := _read_folder(str(database["path"]).path_join(version).path_join(language), "", pages)
	var about := _read_about(database, version, language, pages)
	return {"tree": tree, "pages": pages, "first": first_page(tree), "about": about}	#/ pages: id -> page. about: About page ids in order


#* Add the About pages to pages, return their ids in order:
static func _read_about(database: Dictionary, version: String, language: String, pages: Dictionary) -> Array[String]:
	var database_path := str(database["path"])
	var by_name: Dictionary = {}
	#? Broadest folder first, so specific ones replace.
	for folder: String in [database_path, database_path.path_join(version), database_path.path_join(version).path_join(language)]:
		var about_folder := folder.path_join(ABOUT_FOLDER)
		if not DirAccess.dir_exists_absolute(about_folder):
			continue
		for file_name in DirAccess.get_files_at(about_folder):
			if file_name.begins_with("_") or not PAGE_EXTENSIONS.has(file_name.get_extension().to_lower()):
				continue
			var file_path := about_folder.path_join(file_name)
			var file := FileAccess.open(file_path, FileAccess.READ)
			if file == null:
				continue
			var meta: Dictionary = parse_page(file.get_as_text())["meta"]
			var split := split_prefix(file_name.get_basename())
			var order: int = split["order"]
			if str(meta.get("order", "")).is_valid_int():
				order = int(meta["order"])
			by_name[split["name"]] = {
				"id": ABOUT_FOLDER + "/" + str(split["name"]),	#/ Regular ids never start with "_", so no clash
				"title": str(meta.get("title", prettify(str(split["name"])))),
				"order": order,
				"file": file_path,
			}
	var entries: Array = by_name.values()
	entries.sort_custom(_in_order)
	var ids: Array[String] = []
	for entry: Dictionary in entries:
		pages[entry["id"]] = {"title": entry["title"], "file": entry["file"], "search": "", "about": true}
		ids.append(str(entry["id"]))
	return ids


static func _read_folder(folder: String, id_prefix: String, pages: Dictionary) -> Array[Dictionary]:
	var nodes: Array[Dictionary] = []
	#? By basename, so a same-named folder becomes their children.
	var pages_by_name: Dictionary = {}
	for file_name in DirAccess.get_files_at(folder):
		if file_name.begins_with("_") or not PAGE_EXTENSIONS.has(file_name.get_extension().to_lower()):
			continue
		var file_path := folder.path_join(file_name)
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			continue
		var parsed := parse_page(file.get_as_text())
		var meta: Dictionary = parsed["meta"]
		var split := split_prefix(file_name.get_basename())
		var page_id := id_prefix + str(split["name"])
		var order: int = split["order"]
		if str(meta.get("order", "")).is_valid_int():
			order = int(meta["order"])
		var node := {
			"kind": "page",
			"id": page_id,
			"title": str(meta.get("title", prettify(str(split["name"])))),
			"order": order,
			"file": file_path,
		}
		if pages.has(page_id):
			push_warning("CandyDocsLibrary: two pages share the id \"%s\"; only the first is used." % page_id)
			continue
		pages[page_id] = {"title": node["title"], "file": file_path, "search": plain_text(str(parsed["body"])).to_lower()}
		nodes.append(node)
		pages_by_name[file_name.get_basename()] = node
	for folder_name in DirAccess.get_directories_at(folder):
		if folder_name.begins_with(".") or folder_name.begins_with("_"):
			continue
		var split := split_prefix(folder_name)
		var children := _read_folder(folder.path_join(folder_name), id_prefix + str(split["name"]) + "/", pages)
		if children.is_empty():
			continue
		if pages_by_name.has(folder_name):
			pages_by_name[folder_name]["children"] = children
			continue
		nodes.append({"kind": "category", "id": id_prefix + str(split["name"]) + "/", "title": prettify(str(split["name"])), "order": split["order"], "children": children})
	nodes.sort_custom(_in_order)
	return nodes


#* Sort by order, then title:
static func _in_order(a: Dictionary, b: Dictionary) -> bool:
	if a["order"] != b["order"]:
		return a["order"] < b["order"]
	return str(a["title"]).naturalnocasecmp_to(str(b["title"])) < 0


static func first_page(nodes: Array) -> String:
	for node: Dictionary in nodes:
		if node["kind"] == "page":
			return node["id"]
		var inner := first_page(node["children"])
		if not inner.is_empty():
			return inner
	return ""


#* Split a page into { "meta" = { key = value }, "body" = text }:
static func parse_page(text: String) -> Dictionary:
	var meta: Dictionary = {}
	var lines := text.replace("\r\n", "\n").split("\n")
	var index := 0
	#Ł Meta - the `@key: value` lines at the top:
	while index < lines.size() and lines[index].begins_with("@"):
		var line := lines[index].substr(1)
		var colon := line.find(":")
		if colon > 0:
			meta[line.substr(0, colon).strip_edges().to_lower()] = line.substr(colon + 1).strip_edges()
		index += 1
	var body := "\n".join(lines.slice(index)).lstrip("\n")
	return {"meta": meta, "body": body}


#* "02_Installing_It" -> { "order" = 2, "name" = "Installing_It" }:
static func split_prefix(file_name: String) -> Dictionary:
	var digits := 0
	while digits < file_name.length() and file_name[digits].is_valid_int():
		digits += 1
	var rest := file_name.substr(digits).lstrip("_-. ")
	if digits == 0 or rest.is_empty():
		return {"order": NO_ORDER, "name": file_name}	#/ No prefix
	return {"order": int(file_name.substr(0, digits)), "name": rest}


static func prettify(file_name: String) -> String:
	return file_name.replace("_", " ")


#* A BBCode page without its tags, for searching:
static func plain_text(body: String) -> String:
	if _tag_regex == null:
		_tag_regex = RegEx.create_from_string("\\[[^\\]]*\\]")
	return _tag_regex.sub(body, "", true)


#* Load a texture - the imported resource if any (Candy DC's own), else the file:
static func load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var resource: Resource = load(path)
		if resource is Texture2D:
			return resource
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)
	return null
