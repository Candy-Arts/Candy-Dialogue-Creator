#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyGitHubSource
extends Node

signal files_progress(done: int, total: int)

const API_HEADERS := [
	"Accept: application/vnd.github+json",
	"X-GitHub-Api-Version: 2022-11-28",
	"User-Agent: Candy-Dialogue-Creator",
]
#^ Answered with the file itself instead of its description:
const FILE_HEADERS := [
	"Accept: application/vnd.github.raw+json",
	"X-GitHub-Api-Version: 2022-11-28",
	"User-Agent: Candy-Dialogue-Creator",
]
const DOWNLOAD_HEADERS := [
	"User-Agent: Candy-Dialogue-Creator",
]
#^ Timeouts in seconds (API answer, one file download):
const API_TIMEOUT := 20.0
const FILE_TIMEOUT := 60.0
#^ Files downloaded at once:
const PARALLEL_DOWNLOADS := 4
#^ Largest file taken (a documentation zip holds a whole database):
const MAX_FILE_BYTES := 128 * 1024 * 1024
#^ Hashed with normalized line endings (see git_blob_hash()):
const TEXT_EXTENSIONS := ["json", "md", "txt", "csv", "gitkeep"]

#^ Where GitHub is (only tests change them):
var api_base := "https://api.github.com"
var raw_base := "https://raw.githubusercontent.com"

var _http: HTTPRequest
var _busy := false
var _workers: Array[HTTPRequest] = []


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = API_TIMEOUT
	add_child(_http)


#* Whether an API request is under way (another is refused):
func is_busy() -> bool:
	return _busy


#& A branch's files

#* Fetch a branch's file list, or { "error" }:
#? repo (the name) is only for messages.
func fetch_tree(repo: String, repo_id: int, branch: String) -> Dictionary:
	if repo_id == 0:
		return {"error": CandyLocale.t("No repository is set up for this in this version of Candy Dialogue Creator.")}
	var ref: Variant = await _get_json("%s/git/ref/heads/%s" % [repository_url(repo_id), branch.uri_encode()],
		missing_text(CandyLocale.t("The repository (or its %s branch)") % branch))
	if ref is Dictionary and ref.has("error"):
		return ref
	if not ref is Dictionary or not ref.get("object") is Dictionary:
		return {"error": CandyLocale.t("GitHub's answer couldn't be read.")}
	var commit := str(ref["object"].get("sha", ""))
	var listing: Variant = await _get_json("%s/git/trees/%s?recursive=1" % [repository_url(repo_id), commit],
		CandyLocale.t("%s's files weren't found on GitHub.") % repo)
	if listing is Dictionary and listing.has("error"):
		return listing
	if not listing is Dictionary or not listing.get("tree") is Array:
		return {"error": CandyLocale.t("GitHub's answer couldn't be read.")}
	if CandyVariantFile.to_bool(listing.get("truncated", false), false):
		return {"error": CandyLocale.t("%s has too many files for GitHub to list them all at once.") % repo}
	var files := {}
	var folders := {}
	for entry in listing["tree"]:
		if not entry is Dictionary:
			continue
		match str(entry.get("type", "")):
			"blob":
				files[str(entry.get("path", ""))] = str(entry.get("sha", ""))
			"tree":
				folders[str(entry.get("path", ""))] = str(entry.get("sha", ""))
	return {"commit": commit, "files": files, "folders": folders}			#/ { path from the root: git hash }


#* An API request's JSON answer, or { "error" }:
func _get_json(url: String, not_found: String) -> Variant:
	var response := await _request(url, API_HEADERS, MAX_FILE_BYTES)
	if response.is_empty():
		return {"error": CandyLocale.t("Couldn't contact GitHub.")}
	var problem := _response_error(response, CandyLocale.t("Checking GitHub"), not_found)
	if problem != "":
		return {"error": problem}
	var parsed: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	if parsed == null:
		return {"error": CandyLocale.t("GitHub's answer couldn't be read.")}
	return parsed


#& One file

#* Fetch one file of a branch, or { "error" }:
#? _repo (the name) is unused, kept so every fetch takes the same arguments.
func fetch_file(_repo: String, repo_id: int, branch: String, path: String, etag: String = "",
		max_bytes: int = MAX_FILE_BYTES) -> Dictionary:
	if repo_id == 0:
		return {"error": CandyLocale.t("No repository is set up for this in this version of Candy Dialogue Creator.")}
	var headers: Array = FILE_HEADERS.duplicate()
	if etag != "":
		headers.append("If-None-Match: " + etag)
	var url := "%s/contents/%s?ref=%s" % [repository_url(repo_id), _encoded_path(path), branch.uri_encode()]
	var response := await _request(url, headers, max_bytes)
	if response.is_empty():
		return {"error": CandyLocale.t("Couldn't contact GitHub.")}
	if int(response[1]) == 304:
		return {"unchanged": true}			#/ etag still matches
	var problem := _response_error(response, CandyLocale.t("Checking GitHub"), CandyLocale.t("It isn't on GitHub, or isn't public."))
	if problem != "":
		return {"error": problem}
	return {"bytes": response[3], "etag": _header_value(response[2], "etag")}


#* Make an API request:
func _request(url: String, headers: Array, max_bytes: int) -> Array:
	if _busy:
		return []			#/ Busy
	_http.timeout = API_TIMEOUT
	_http.body_size_limit = max_bytes
	if _http.request(url, PackedStringArray(headers)) != OK:
		return []			#/ Couldn't start
	_busy = true
	var response: Array = await _http.request_completed
	_busy = false
	return response			#/ request_completed's arguments


#& Files at a commit

#* Download files at a commit, into memory, or { "error" } at the first failure:
#? wanted: { path: git hash }.
func download_files(repo: String, commit: String, wanted: Dictionary) -> Dictionary:
	var queue: Array = wanted.keys()
	var state := {"error": "", "next": 0, "done": 0, "running": 0, "files": {}}
	if queue.is_empty():
		return {"files": {}}
	files_progress.emit(0, queue.size())
	for index in mini(PARALLEL_DOWNLOADS, queue.size()):
		var request := HTTPRequest.new()
		#! Not threaded: cancelling a threaded request freezes the app until the server answers.
		request.timeout = FILE_TIMEOUT
		request.body_size_limit = MAX_FILE_BYTES
		add_child(request)
		_workers.append(request)
		state["running"] += 1
		_download_next(request, repo, commit, queue, wanted, state)
	while state["running"] > 0 and state["error"] == "":
		await get_tree().process_frame
	#Ł Stop the others (a cancelled request never completes):
	for request in _workers:
		request.cancel_request()
		request.queue_free()
	_workers.clear()
	if state["error"] != "":
		return {"error": state["error"]}
	return {"files": state["files"]}			#/ { path: bytes }


#* One parallel download - take queued files until none are left, or one failed:
func _download_next(request: HTTPRequest, repo: String, commit: String, queue: Array,
		wanted: Dictionary, state: Dictionary) -> void:
	while state["error"] == "" and state["next"] < queue.size():
		var path := str(queue[state["next"]])
		state["next"] += 1
		var url := "%s/%s/%s/%s" % [raw_base, repo, commit, _encoded_path(path)]
		var error := request.request(url, PackedStringArray(DOWNLOAD_HEADERS))
		if error != OK:
			state["error"] = CandyLocale.t("Couldn't start downloading {file} ({error}).").format({"file": path.get_file(), "error": error_string(error)})
			break
		var response: Array = await request.request_completed
		if state["error"] != "":
			break
		var problem := _response_error(response, CandyLocale.t("Downloading %s") % path.get_file(),
			CandyLocale.t("%s isn't on GitHub anymore: try again.") % path)
		if problem != "":
			state["error"] = problem
			break
		var bytes: PackedByteArray = response[3]
		#Ł Check against its hash:
		if git_blob_hash(path, bytes, false) != str(wanted[path]):
			state["error"] = CandyLocale.t("%s didn't download right (it doesn't match GitHub's list). Try again.") % path
			break
		state["files"][path] = bytes
		state["done"] += 1
		files_progress.emit(state["done"], queue.size())
	state["running"] -= 1


#* Stop the downloads (download_files() then ends with an error):
func cancel() -> void:
	for request in _workers:
		request.cancel_request()


#& Helpers

#* A repository's API URL, by ID:
func repository_url(repo_id: int) -> String:
	return "%s/repositories/%d" % [api_base, repo_id]


#* The message for something missing under a repository's ID:
static func missing_text(what: String) -> String:
	return CandyLocale.t("%s isn't on GitHub, or isn't public.") % what


#* A file's git blob hash (SHA-1), as GitHub lists it:
#? normalize false: checks a download is exact.
static func git_blob_hash(path: String, bytes: PackedByteArray, normalize: bool = true) -> String:
	var data := bytes
	#% Text files hashed with "\r\n" -> "\n", so a local copy still matches:
	if normalize and TEXT_EXTENSIONS.has(path.get_extension().to_lower()):
		data = bytes.get_string_from_utf8().replace("\r\n", "\n").to_utf8_buffer()
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA1)
	var header := ("blob %d" % data.size()).to_utf8_buffer()
	header.append(0)
	context.update(header)
	if data.size() > 0:
		context.update(data)
	return context.finish().hex_encode()


#* Whether an outside path stays inside its folder (relative, no "..", no backslash, no drive, no empty part):
static func is_safe_relative_path(path: String) -> bool:
	if path == "" or path.begins_with("/") or "\\" in path or ":" in path:
		return false
	for part in path.split("/"):
		if part == "" or part == "." or part == "..":
			return false
	return true


#* URL-encode a path, keeping the "/":
func _encoded_path(path: String) -> String:
	var encoded: PackedStringArray = []
	for part in path.split("/"):
		encoded.append(part.uri_encode())
	return "/".join(encoded)


#* What went wrong with a response ("" if fine):
func _response_error(response: Array, what: String, not_found: String) -> String:
	var result: int = response[0]
	var code: int = response[1]
	if result == HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
		return CandyLocale.t("%s failed: the file is larger than Candy Dialogue Creator takes.") % what
	if result != HTTPRequest.RESULT_SUCCESS:
		return CandyLocale.t("{what} failed: couldn't reach the server. Check your internet connection. ({error})").format(
			{"what": what, "error": _result_text(result)})
	if code == 404:
		return not_found
	if code == 403 or code == 429:
		return CandyLocale.t("GitHub refused the request: it limits how often it can be asked (60 times an hour). %s") % _retry_text(response[2])
	if code < 200 or code >= 300:
		return CandyLocale.t("{what} failed: the server answered with error {code}.").format({"what": what, "code": code})
	return ""


#* When GitHub's rate limit lifts, from the headers:
func _retry_text(headers: PackedStringArray) -> String:
	var reset := _header_value(headers, "x-ratelimit-reset").to_int()
	var minutes := ceili((reset - Time.get_unix_time_from_system()) / 60.0)
	if reset > 0 and minutes > 1:
		return CandyLocale.tn("Try again in %d minute.", "Try again in %d minutes.", minutes) % minutes
	if reset > 0 and minutes == 1:
		return CandyLocale.t("Try again in a minute.")
	return CandyLocale.t("Try again in a while.")


func _header_value(headers: PackedStringArray, header_name: String) -> String:
	var prefix := header_name.to_lower() + ":"
	for header in headers:
		if header.to_lower().begins_with(prefix):
			return header.substr(prefix.length()).strip_edges()
	return ""


func _result_text(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CANT_RESOLVE:
			return CandyLocale.t("host not found")
		HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_CONNECTION_ERROR:
			return CandyLocale.t("connection failed")
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			return CandyLocale.t("secure connection failed")
		HTTPRequest.RESULT_TIMEOUT:
			return CandyLocale.t("timed out")
		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
			return CandyLocale.t("too many redirects")
	return CandyLocale.t("error %d") % result
