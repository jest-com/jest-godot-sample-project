class_name JestLoginReservation
extends JestResult

## The reservation data to pass to send_reserved_login_message().
var reservation: Dictionary = {}


static func from_dict(d: Dictionary) -> JestLoginReservation:
	var r := JestLoginReservation.new()
	if d.has("error") and not str(d["error"]).is_empty():
		r.ok = false
		r.error = str(d["error"])
	else:
		r.ok = true
		r.reservation = d.get("reservation", {})
	return r


static func make_error(err: String) -> JestLoginReservation:
	var r := JestLoginReservation.new()
	r.ok = false
	r.error = err
	return r
