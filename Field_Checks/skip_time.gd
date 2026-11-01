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


func check(_config: Dictionary, context: CandyCheckContext) -> Array:
	var value := context.value.strip_edges()
	if value == "":
		return []

	var moves := CandyChecks.relative_frames(value)
	if moves["frames"]:
		if not moves["valid"]:
			return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("f+ / f- needs a number of frames."))]
		var frames_text := CandyLocale.t("Moves %s frames back.")
		if moves["forward"]:
			frames_text = CandyLocale.t("Moves %s frames forward.")
		return [CandyChecks.message(CandyChecks.NOTICE, frames_text % moves["count"])]

	var direction := ""
	var target := value
	if value.begins_with("+"):
		direction = "forward"
		target = value.substr(1).strip_edges()
	elif value.begins_with("-"):
		direction = "back"
		target = value.substr(1).strip_edges()

	var frames := CandyChecks.frame_target(target)
	if frames["frames"]:
		if direction != "":
			return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("To move by frames, write f+N / f-N."))]
		if not frames["valid"]:
			return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("f= needs a frame number."))]
		return []
	var seconds := CandyChecks.time_seconds(target)
	if seconds < 0.0:
		return [CandyChecks.message(CandyChecks.ERROR, CandyLocale.t("Value is not a time."))]
	if direction == "forward":
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Moves %s s forward.") % CandyChecks.seconds_text(seconds))]
	if direction == "back":
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Moves %s s back.") % CandyChecks.seconds_text(seconds))]
	if is_zero_approx(seconds):
		return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Rewind to the start."))]
	return [CandyChecks.message(CandyChecks.NOTICE, CandyLocale.t("Skips to %s.") % value)]
