#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyConfirmPrompt


#* Ask for confirmation:
static func ask(host: Node, title: String, text: String, ok_text: String, on_confirmed: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = title
	dialog.dialog_text = text
	dialog.ok_button_text = ok_text
	dialog.confirmed.connect(on_confirmed)
	#? The dialog hides before reporting the answer; queue_free() waits for it.
	dialog.visibility_changed.connect(func():
		if not dialog.visible:
			dialog.queue_free())
	host.add_child(dialog)
	dialog.popup_centered()


#* Ask before removing an entry:
#? entry_label: what an entry is called ("choice").
static func ask_remove(host: Node, entry_label: String, entry_name: String, on_confirmed: Callable) -> void:
	var text := CandyLocale.t("Remove this %s and everything in it?") % entry_label
	#% Named entry:
	if entry_name != "":
		text = CandyLocale.t("Remove the {entry} \"{name}\" and everything in it?").format({"entry": entry_label, "name": entry_name})
	ask(host, CandyLocale.t("Remove %s") % entry_label.capitalize(), text, CandyLocale.t("Remove"), on_confirmed)
