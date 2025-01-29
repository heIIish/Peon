local Vector3 = {}
Vector3.__index = Vector3

local function createVector3(x, y, z)
	assert(type(x) == "number", string.format("Vector3(x, _, _) - number expected, got %s", type(x)))
	assert(type(y) == "number", string.format("Vector3(_, y, _) - number expected, got %s", type(y)))
	assert(type(z) == "number", string.format("Vector3(_, _, z) - number expected, got %s", type(z)))

	local vector = {
		__type = "Vector3",
		X = x,
		Y = y,
		Z = z
	}

	setmetatable(vector, Vector3)

	return vector
end

function Vector3:Unpack()
	return self.X, self.Y, self.Z
end

function Vector3:Magnitude()
	local X, Y, Z = self.X, self.Y, self.Z
	return math.sqrt(X * X + Y * Y + Z * Z)
end

function Vector3:Unit()
	return 
end

function Vector3:__add(vector)
	local t = typeof(vector)
	assert(t == "Vector3", string.format("Vector3:__add - Vector3 expected, got %s", t))
	return createVector3(self.X + vector.X, self.Y + vector.Y, self.Z + vector.Z)
end

function Vector3:__sub(vector)
	local t = typeof(vector)
	assert(t == "Vector3", string.format("Vector3:__sub - Vector3 expected, got %s", t))
	return createVector3(self.X - vector.X, self.Y - vector.Y, self.Z - vector.Z)
end

function Vector3:__mul(vector)
	local t = typeof(vector)
	if t == "Vector3" then
		return createVector3(self.X * vector.X, self.Y * vector.Y, self.Z * vector.Z)
	elseif t == "number" then
		return createVector3(self.X * vector, self.Y * vector, self.Z * vector)
	else
		error(string.format("Vector3:__mul - Vector3 or number expected, got %s", t))
	end
end

function Vector3:__div(vector)
	local t = typeof(vector)
	if t == "Vector3" then
		return createVector3(self.X / vector.X, self.Y / vector.Y, self.Z / vector.Z)
	elseif t == "number" then
		return createVector3(self.X / vector, self.Y / vector, self.Z / vector)
	else
		error(string.format("Vector3:__div - Vector3 or number expected, got %s", t))
	end
end

function Vector3:__eq(vector)
	local t = typeof(vector)
	assert(t == "Vector3", string.format("Vector3:__eq - Vector3 expected, got %s", t))
	return self.X == vector.X and self.Y == vector.Y and self.Z == vector.Z
end

function Vector3:__unm()
	return createVector3(-self.X, -self.Y, -self.Z)
end

function Vector3:__tostring()
	return string.format("(%.5f, %.5f, %.5f)", self.X, self.Y, self.Z)
end

function Vector3:__call(...)
	return createVector3(...)
end

return setmetatable(Vector3, Vector3)