#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySymbolPrompt

#& Runs an action only once what it reads or writes uses the profile's symbols.
#? A file or dialogue written with other symbols is updated first (CandySymbolUpdater), or
#? the action is cancelled: mixing symbols would leave a file Candy DE misreads.
#? Files that don't store their symbols are taken to use the profile's.
#? Before asking, it offers to update the profile's symbols from the project's scripts, when
#? they differ (offer_project_symbols()): optional, since the files only need to match the profile.

const TITLE := "Symbols Don't Match"      #/ translatable
const PROJECT_TITLE := "Project Symbols Changed"      #/ translatable

#^ The [profile's, project's] symbols last kept, so the same offer isn't made twice in a row:
static var _declined: Array = []


#* Run action once the open dialogue (and presets) use the profile's symbols:
#? doing: what the action does, for the question ("saving").
static func ensure_dialogue(host: Node, doing: String, action: Callable) -> void:
	if not CandyProfiles.is_profile_open() or CandyDialogue.symbols_match():
		action.call()
		return
	offer_project_symbols(host, _ask_dialogue.bind(host, doing, action))


static func _ask_dialogue(host: Node, doing: String, action: Callable) -> void:
	#% The profile may now have the dialogue's symbols:
	if CandyDialogue.symbols_match():
		action.call()
		return
	var profile := CandySymbolUpdater.profile_symbols()
	var problem := CandySymbolUpdater.profile_problems()
	if problem != "":
		show_error(host, CandyLocale.t("The profile's symbols can't be used: %s Fix them on Settings > Project > Symbols.") % problem)
		return
	var text := CandyLocale.t("The profile's symbols changed since it was opened:\n\n{changes}\n\nUpdate the open dialogue, the presets and the clipboard to the new symbols before {doing}?\nThis clears the undo history.").format({
		"changes": CandySymbolUpdater.describe_changes(CandyDialogue.symbols, profile), "doing": doing})
	_ask(host, text, func():
		var updater := CandyDialogue.update_symbols()
		CandyPresets.save()
		_report_checks([{"path": CandyLocale.t("The open dialogue, presets and clipboard"), "kind": "Dialogue", "version": "",
			"outcome": CandyFileConverter.OUTCOME_CONVERTED, "message": "", "backup": "",
			"notes": updater.notes, "changed": updater.changed_values}])
		action.call())


#* Run action once the files at paths use the profile's symbols:
#? doing as in ensure_dialogue(). cancel_note: what Cancel leaves, added to the question.
#? Missing or unreadable files are left to the action, which reports them.
static func ensure_files(host: Node, paths: Array, doing: String, action: Callable, cancel_note: String = "") -> void:
	if not CandyProfiles.is_profile_open() or _mismatched(paths).is_empty():
		action.call()
		return
	#? A profile updated from the project changes what's open too: that's asked first.
	offer_project_symbols(host, func():
		ensure_dialogue(host, doing, _ask_files.bind(host, paths, doing, action, cancel_note)))


#* The files at paths written with other symbols than the profile's:
static func _mismatched(paths: Array) -> Array:
	var profile := CandySymbolUpdater.profile_symbols()
	var result: Array = []
	for path in paths:
		if not FileAccess.file_exists(str(path)):
			continue
		var info := CandySymbolUpdater.inspect(str(path), profile, profile)
		if str(info["status"]) == CandySymbolUpdater.STATUS_UPDATE:
			result.append(str(path))
	return result


static func _ask_files(host: Node, paths: Array, doing: String, action: Callable, cancel_note: String) -> void:
	var mismatched := _mismatched(paths)
	if mismatched.is_empty():
		action.call()
		return
	var profile := CandySymbolUpdater.profile_symbols()
	var changes := CandySymbolUpdater.describe_changes(CandySymbolUpdater.inspect(str(mismatched[0]), profile, profile)["symbols"], profile)
	var problem := CandySymbolUpdater.profile_problems()
	if problem != "":
		show_error(host, CandyLocale.t("The profile's symbols can't be used: %s Fix them on Settings > Project > Symbols.") % problem)
		return

	var names := PackedStringArray()
	for path in mismatched:
		names.append(ProjectSettings.globalize_path(path))
	var text := CandyLocale.tn("This file was written with other symbols than the profile's:\n{files}\n\n{changes}\n\nUpdate the file to the profile's symbols before {doing}? Each is backed up first, in Conversion Backups/{folder} beside it.",
		"These files were written with other symbols than the profile's:\n{files}\n\n{changes}\n\nUpdate them to the profile's symbols before {doing}? Each is backed up first, in Conversion Backups/{folder} beside it.",
		mismatched.size()).format({"files": "\n".join(names), "changes": changes, "doing": doing,
		"folder": CandySymbolUpdater.BACKUP_KIND_FOLDER})
	if cancel_note != "":
		text += "\n\n" + cancel_note
	_ask(host, text, func():
		var results := CandySymbolUpdater.update_files(mismatched, profile, profile)
		var failed := PackedStringArray()
		for result in results:
			if str(result["outcome"]) == CandyFileConverter.OUTCOME_FAILED:
				failed.append("%s\n%s" % [ProjectSettings.globalize_path(str(result["path"])), CandySymbolUpdater.outcome_text(result)])
		if not failed.is_empty():
			show_error(host, CandyLocale.t("Nothing was done, as some files couldn't be updated:\n\n%s") % "\n\n".join(failed))
			return
		_report_checks(results)
		action.call())


#* Offer to update the profile's symbols from the project's scripts, then run then_call, whatever the answer:
#? Not offered when no script can be read, when they match, when the project's symbols can't be
#? used, or when the same offer was just turned down.
static func offer_project_symbols(host: Node, then_call: Callable) -> void:
	var project := CandySymbolUpdater.project_symbols()
	var project_symbols: Dictionary = project["symbols"]
	var profile := CandySymbolUpdater.profile_symbols()
	if not project["read"] or CandySymbolUpdater.same_symbols(project_symbols, profile) \
			or CandySymbolUpdater.symbol_problems(project_symbols) != "" or _was_declined(profile, project_symbols):
		then_call.call()
		return

	var dialog := ConfirmationDialog.new()
	dialog.theme = CandyTheme.theme
	dialog.title = CandyLocale.t(PROJECT_TITLE)
	dialog.dialog_text = CandyLocale.t("Your project's symbols don't match the profile's:\n\n%s\n\nUpdate the profile's symbols (Settings > Project > Symbols) from Candy_Properties.gd and CandyRef_Shortcuts.gd?") % \
		CandySymbolUpdater.describe_changes(profile, project_symbols)
	dialog.ok_button_text = CandyLocale.t("Update Profile")
	dialog.cancel_button_text = CandyLocale.t("Keep Profile's")
	dialog.confirmed.connect(func():
		CandySymbolUpdater.set_profile_symbols(project_symbols)
		_declined = []
		then_call.call())
	#? Closing the window keeps the profile's too.
	dialog.canceled.connect(func():
		_declined = [profile, project_symbols]
		then_call.call())
	dialog.visibility_changed.connect(func():
		if not dialog.visible:
			dialog.queue_free())
	host.add_child(dialog)
	dialog.popup_centered()


static func _was_declined(profile: Dictionary, project_symbols: Dictionary) -> bool:
	if _declined.size() != 2:
		return false
	return CandySymbolUpdater.same_symbols(_declined[0], profile) and CandySymbolUpdater.same_symbols(_declined[1], project_symbols)


#* Ask to update or cancel - nothing else, so the action never runs on mixed symbols:
static func _ask(host: Node, text: String, on_update: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	#? Own theme - autoloads host it too, outside Candy DC's windows.
	dialog.theme = CandyTheme.theme
	dialog.title = CandyLocale.t(TITLE)
	dialog.dialog_text = text
	dialog.ok_button_text = CandyLocale.t("Update Symbols")
	dialog.cancel_button_text = CandyLocale.t("Cancel")
	dialog.confirmed.connect(on_update)
	#? The dialog hides before reporting the answer; queue_free() waits for it.
	dialog.visibility_changed.connect(func():
		if not dialog.visible:
			dialog.queue_free())
	host.add_child(dialog)
	dialog.popup_centered()


#* Open the report if an update left something to check:
static func _report_checks(results: Array) -> void:
	for result in results:
		for note in result.get("notes", []):
			if str(note["level"]) == CandySymbolUpdater.LEVEL_CHECK:
				CandyConverterReportDialog.open_report(results, CandySymbolUpdater)
				return


static func show_error(host: Node, message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.theme = CandyTheme.theme
	dialog.title = CandyLocale.t(TITLE)
	dialog.dialog_text = message
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	host.add_child(dialog)
	dialog.popup_centered()
