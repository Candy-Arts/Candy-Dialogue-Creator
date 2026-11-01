#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyGeneralSettingsPage
extends CandySettingsPage


func build() -> void:
	add_heading(CandyLocale.t("Profile"))
	add_info(CandyLocale.t("User"), CandyProfiles.current_user)
	add_info(CandyLocale.t("Project profile"), CandyProfiles.current_profile)
	add_info(CandyLocale.t("Candy DC version"), CandyProfiles.VERSION)
	add_separator()

	add_heading(CandyLocale.t("Naming"))
	add_text("conversation_new_name", CandyLocale.t("New conversation name"),
		CandyLocale.t("Suggested when creating a conversation."), "Conversation_1")
	add_text("block_default_name", CandyLocale.t("Default block name"),
		CandyLocale.t("The block created with a new conversation."), "Block_1")
	add_text("block_new_name", CandyLocale.t("New block name"),
		CandyLocale.t("Suggested when creating a block."), "Block_")
