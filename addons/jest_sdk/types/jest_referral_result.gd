class_name JestReferralResult
extends JestResult

## Array of referral entries: [{reference: String, registrations: int}]
var referrals: Array[Dictionary] = []
## Signed token for server-side verification.
var referrals_signed: String = ""


static func from_dict(d: Dictionary) -> JestReferralResult:
	var r := JestReferralResult.new()
	r.ok = true
	r.referrals = []
	var arr = d.get("referrals", [])
	if arr is Array:
		for item in arr:
			if item is Dictionary:
				r.referrals.append(item)
	r.referrals_signed = str(d.get("referralsSigned", ""))
	return r


static func make_error(err: String) -> JestReferralResult:
	var r := JestReferralResult.new()
	r.ok = false
	r.error = err
	return r
