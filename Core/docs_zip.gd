#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDocsZip
extends RefCounted

#! The zip's format is Candy Wizard's (Docs_Zip.gd, Release_Signature.gd) and Candy Web Database's (Web_Docs_Zip.gd): change them together.
#^ The manifest at the zip's root, and its signature (the manifest's name, then SIGNATURE_SUFFIX):
const MANIFEST_NAME := "candy_docs_manifest.json"
const SIGNATURE_SUFFIX := ".sig"
const PACKAGE := "candy_docs"
#^ The newest manifest format this Candy DC reads:
const FORMAT := 1
#^ Candy Arts' public release keys, a copy of Candy Wizard's Data/Release_Keys.json - {"keys": [{"name", "fingerprint", "public"}]}:
const KEYS_PATH := "res://Defaults/release_keys.json"
#^ Where a downloaded zip is put to be read (ZIPReader only opens files):
const TEMP_ZIP := "user://Documentation/docs_download.zip"

#^ A signature as its file writes it - bytes in hexadecimal:
static var _hex_regex := RegEx.create_from_string(r"^([0-9a-f]{2})+\z")


#* A documentation zip's files - {"files": {path: bytes}, "left_out": [paths]}, or {"error"}:
#? folder_name: the database's folder, which every path starts with. title: for messages.
#? Nothing in the zip is believed before its manifest's signature is checked.
static func read(zip_bytes: PackedByteArray, folder_name: String, title: String, extensions: Array) -> Dictionary:
	var error := CandyDocsFiles.write_file(TEMP_ZIP, zip_bytes)
	if error != "":
		return {"error": error}
	var reader := ZIPReader.new()
	var result := {}
	if reader.open(TEMP_ZIP) != OK:
		result = {"error": CandyLocale.t("%s didn't download as a zip file that can be read.") % title}
	else:
		result = _read_open(reader, folder_name, title, extensions)
		reader.close()
	DirAccess.remove_absolute(TEMP_ZIP)
	return result


static func _read_open(reader: ZIPReader, folder_name: String, title: String, extensions: Array) -> Dictionary:
	#@ Step 1 - The signature:
	if not reader.file_exists(MANIFEST_NAME):
		return {"error": CandyLocale.t("%s isn't a documentation zip.") % title}
	var manifest_bytes := reader.read_file(MANIFEST_NAME)
	var signature := ""
	if reader.file_exists(MANIFEST_NAME + SIGNATURE_SUFFIX):
		signature = reader.read_file(MANIFEST_NAME + SIGNATURE_SUFFIX).get_string_from_utf8()
	var signature_problem := _signature_problem(manifest_bytes, signature, title)
	if signature_problem != "":
		return {"error": signature_problem}

	#@ Step 2 - The manifest:
	var manifest: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not manifest is Dictionary or not manifest.get("files") is Dictionary:
		return {"error": CandyLocale.t("%s's manifest can't be read.") % title}
	if int(manifest.get("format", 0)) > FORMAT:
		return {"error": CandyLocale.t("%s was made for a newer version of Candy Dialogue Creator. Update Candy Dialogue Creator first.") % title}
	if manifest.get("package") != PACKAGE or manifest.get("database") != folder_name:
		return {"error": CandyLocale.t("%s's zip holds another database. It was refused.") % title}

	#@ Step 3 - Every file, checked against the manifest:
	var files := {}
	var left_out: PackedStringArray = []
	var prefix := folder_name + "/"
	for path: Variant in manifest["files"]:
		var relative := str(path)
		if not relative.begins_with(prefix) or not CandyGitHubSource.is_safe_relative_path(relative):
			return {"error": CandyLocale.t("{set}'s zip names a file outside its folder ({file}). It was refused.").format({"set": title, "file": relative})}
		if not extensions.has(relative.get_extension().to_lower()):
			left_out.append(relative)
			continue
		if not reader.file_exists(relative):
			return {"error": CandyLocale.t("{set}'s zip is incomplete: {file} is missing.").format({"set": title, "file": relative})}
		var entry: Variant = manifest["files"][path]
		var bytes := reader.read_file(relative)
		if not entry is Dictionary or _sha256(bytes).hex_encode() != str(entry.get("sha256", "")):
			return {"error": CandyLocale.t("{set}'s zip is damaged: {file} doesn't match its manifest. Download it again.").format({"set": title, "file": relative})}
		files[relative] = bytes
	if files.is_empty():
		return {"error": CandyLocale.t("%s's zip has no files to download.") % title}
	left_out.sort()
	return {"files": files, "left_out": left_out}


#* Why a manifest can't be taken for Candy Arts', or "" (Candy Wizard's Release_Signature.problem()):
static func _signature_problem(manifest_bytes: PackedByteArray, signature: String, title: String) -> String:
	var keys := public_keys()
	if keys.is_empty():
		return CandyLocale.t("This copy of Candy Dialogue Creator has no release keys, so it can't tell whether the documentation is Candy Arts'. Get Candy Dialogue Creator again from Candy Arts.")
	var text := signature.strip_edges().to_lower()
	if text == "":
		return CandyLocale.t("%s isn't signed by Candy Arts. It was refused.") % title
	if _hex_regex.search(text) != null:
		var signature_bytes := text.hex_decode()
		var digest := _sha256(manifest_bytes)
		var crypto := Crypto.new()
		for key in keys:
			if crypto.verify(HashingContext.HASH_SHA256, digest, signature_bytes, key):
				return ""
	return CandyLocale.t("%s's signature isn't Candy Arts': it isn't official, or it was changed. It was refused.") % title


#* Candy Arts' public keys from KEYS_PATH, empty when the file is missing or holds none:
static func public_keys() -> Array[CryptoKey]:
	var keys: Array[CryptoKey] = []
	if not FileAccess.file_exists(KEYS_PATH):
		return keys
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(KEYS_PATH))
	if not parsed is Dictionary or not parsed.get("keys") is Array:
		return keys
	for entry: Variant in parsed["keys"]:
		if not entry is Dictionary or not entry.get("public") is String:
			continue
		var key := CryptoKey.new()
		if key.load_from_string(entry["public"], true) == OK:
			keys.append(key)
	return keys


static func _sha256(bytes: PackedByteArray) -> PackedByteArray:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	if bytes.size() > 0:
		context.update(bytes)
	return context.finish()
