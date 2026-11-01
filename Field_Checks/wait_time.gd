#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends RefCounted


func check(config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	if value == "":
		return []
	if bool(config.get("frames", true)) and CandyChecks.relative_frames(value)["frames"]:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("f+ / f- only moves a playback: write f=N."))]
	var frames := CandyChecks.frame_target(value)
	if frames["frames"]:
		if bool(config.get("frames", true)) and not frames["valid"]:
			return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("f= needs a frame number."))]
		return []
	if value.begins_with("-"):
		if CandyChecks.time_seconds(value.substr(1)) >= 0.0:
			return [CandyChecks.message(CandyChecks.WARNING, CandyLocale.t("Negative: no extra wait."))]
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a time."))]
	var seconds := CandyChecks.time_seconds(value.trim_prefix("+"))
	if seconds < 0.0:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Not a time."))]
	if CandyChecks.is_timestamp(value):
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("%s seconds.") % CandyChecks.seconds_text(seconds))]
	return []
