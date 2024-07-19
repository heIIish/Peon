local Math = {}

--- Converts (-180, 180) south-facing CCW angle range to (0, 2pi) north-facing CW angle range.
function Math.ToSimpleAngle(angle)
	return math.pi - math.rad(angle)
end

return Math