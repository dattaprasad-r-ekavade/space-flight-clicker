class_name AdRules
extends RefCounted
## Pure interstitial rules. No clock, no nodes. Pass times in as arguments.

const INSTALL_GRACE_S: float = 600.0
const MIN_GAP_S: float = 900.0


static func can_show_interstitial(now_unix: float, install_unix: float, last_shown_unix: float, remove_ads: bool) -> bool:
	if remove_ads:
		return false
	if now_unix - install_unix < INSTALL_GRACE_S:
		return false
	if last_shown_unix > 0.0 and now_unix - last_shown_unix < MIN_GAP_S:
		return false
	return true
