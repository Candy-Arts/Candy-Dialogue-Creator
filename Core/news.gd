#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyNews
extends Node

signal refreshed(result: Result)

enum Result { UPDATED, UNCHANGED, FAILED, NO_SOURCE }

#^ Where the news files are read from, shown in this order:
#? "id" prefixes its items' identifiers, so two files can use the same one.
#? "repository" is only for messages; "repository_id" 0 turns that source off.
#? An ID is the "octolytics-dimension-repository_id" meta tag of its page.
const SOURCES := [
	{"id": "candy_dc",
		"title": "Candy DC news",	#/ translatable
		"repository": "Candy-Arts/Candy-Arts", "repository_id": 1177938775, "branch": "main", "path": "NEWS/Candy Dialogue Creator/News.txt"},
	{"id": "candy_arts",
		"title": "Candy Arts news",	#/ translatable
		"repository": "Candy-Arts/Candy-Arts", "repository_id": 1177938775, "branch": "main", "path": "NEWS/Candy Arts/News.txt"},
]
#^ Starts a news item, at the start of a line (after spaces):
const ITEM_MARKER := "====="
const STATE_FILE := "user://News.txt"
const DEFAULT_REFRESH_AT_STARTUP := true
#^ Largest News.txt taken:
const MAX_BYTES := 256 * 1024

#^ SOURCES and the API base ("" = GitHub's). Only tests change them:
var sources: Array = SOURCES
var api_base := ""

#^ The last refresh's failures, one line per source ("" = none):
var problem := ""

var _github: CandyGitHubSource
var _state: Dictionary = {}
var _busy := false


func _ready() -> void:
	_github = CandyGitHubSource.new()
	add_child(_github)
	_state = CandyVariantFile.read(STATE_FILE)


#& Settings

func refresh_at_startup() -> bool:
	return CandyVariantFile.to_bool(_state.get("refresh_at_startup", DEFAULT_REFRESH_AT_STARTUP),
		DEFAULT_REFRESH_AT_STARTUP)


func set_refresh_at_startup(value: bool) -> void:
	_state["refresh_at_startup"] = value
	_save()


#* The sources with a repository, in the order they're shown:
func active_sources() -> Array:
	return sources.filter(func(source: Dictionary) -> bool: return int(source.get("repository_id", 0)) != 0)


func has_source() -> bool:
	return not active_sources().is_empty()


#& News

#* A source's last copy - {text, etag}, or {}:
func copy(source_id: String) -> Dictionary:
	var copies: Variant = _state.get("copies", {})
	if copies is Dictionary and copies.get(source_id) is Dictionary:
		return copies[source_id]
	return {}


func _keep_copy(source_id: String, text: String, etag: String) -> void:
	var copies: Variant = _state.get("copies", {})
	if not copies is Dictionary:
		copies = {}
	copies[source_id] = {"text": text, "etag": etag}
	_state["copies"] = copies


#* Every source's news items, source after source: [{id, text}]
func items() -> Array:
	var result: Array = []
	for source in active_sources():
		result.append_array(source_items(str(source["id"])))
	return result


#* A source's items. Their ids start with the source's: "candy_arts/welcome":
func source_items(source_id: String) -> Array:
	var result: Array = []
	var item_id := ""
	var item_lines: PackedStringArray = []
	var in_item := false
	var text := str(copy(source_id).get("text", "")).replace("\r\n", "\n")
	for line in text.split("\n"):
		var stripped := line.strip_edges()
		if stripped.begins_with(ITEM_MARKER):
			if in_item:
				_add_item(result, source_id, item_id, item_lines)
			item_id = stripped.trim_prefix(ITEM_MARKER).strip_edges()
			item_lines.clear()
			in_item = true
		elif in_item:
			item_lines.append(line)
	if in_item:
		_add_item(result, source_id, item_id, item_lines)
	return result


func _add_item(result: Array, source_id: String, item_id: String, lines: PackedStringArray) -> void:
	var item := "\n".join(lines).strip_edges()
	if item == "":
		return
	#% No identifier on its marker line - its text stands in, so editing it makes it unread again:
	if item_id == "":
		item_id = "text:" + item.sha256_text()
	result.append({"id": source_id + "/" + item_id, "text": item})


#& Read items

#* Identifiers of the items already shown:
func read_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	var kept: Variant = _state.get("read", [])
	if kept is Array or kept is PackedStringArray:
		for item_id in kept:
			ids.append(str(item_id))
	return ids


func is_read(item_id: String) -> bool:
	return read_ids().has(item_id)


#* Remember an item as read. Returns whether it was unread:
func mark_read(item_id: String) -> bool:
	var ids := read_ids()
	if ids.has(item_id):
		return false
	ids.append(item_id)
	_state["read"] = Array(ids)
	_save()
	return true


#* Whether the last copy has an item not shown yet:
func has_unread() -> bool:
	var ids := read_ids()
	for item in items():
		if not ids.has(item["id"]):
			return true
	return false


#* Forget the read items a source's last copy no longer has:
#? Only that source's: one that couldn't be downloaded keeps its own.
func _forget_deleted(source_id: String) -> void:
	var present: Array = source_items(source_id).map(func(item: Dictionary) -> String: return item["id"])
	var ids := read_ids()
	var kept: Array = []
	for item_id in ids:
		if not item_id.begins_with(source_id + "/") or present.has(item_id):
			kept.append(item_id)
	if kept.size() != ids.size():
		_state["read"] = kept


func is_busy() -> bool:
	return _busy


#* Fetch every source's file and keep the changed ones (ends with refreshed()):
#? UPDATED if any source changed, FAILED if none did and one failed.
func refresh() -> void:
	if is_busy():
		return
	if not has_source():
		refreshed.emit(Result.NO_SOURCE)
		return
	if api_base != "":
		_github.api_base = api_base
	_busy = true
	problem = ""
	var updated := false
	var failures: PackedStringArray = []
	for source in active_sources():
		var source_id := str(source["id"])
		var kept := copy(source_id)
		var etag := ""
		if str(kept.get("text", "")) != "":
			etag = str(kept.get("etag", ""))
		var answer: Dictionary = await _github.fetch_file(str(source.get("repository", "")), int(source["repository_id"]),
			str(source.get("branch", "")), str(source.get("path", "")), etag, MAX_BYTES)
		if answer.has("error"):
			failures.append(CandyLocale.t("{source} couldn't be downloaded. {problem}").format(
				{"source": CandyLocale.t(str(source.get("title", source_id))), "problem": str(answer["error"])}))
			continue
		if answer.has("unchanged"):
			continue
		var text := (answer["bytes"] as PackedByteArray).get_string_from_utf8()
		var changed := text != str(kept.get("text", ""))
		_keep_copy(source_id, text, str(answer.get("etag", "")))
		if changed:
			updated = true
			_forget_deleted(source_id)
	_busy = false
	problem = "\n".join(failures)
	_save()
	if updated:
		refreshed.emit(Result.UPDATED)
	elif not failures.is_empty():
		refreshed.emit(Result.FAILED)
	else:
		refreshed.emit(Result.UNCHANGED)


func _save() -> void:
	CandyVariantFile.write(STATE_FILE, _state)
