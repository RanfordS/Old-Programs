
function NIL_FUNC ()
	return nil
end

function rSwitch (switch, cases, ...)
	return cases[switch](...)
end

function linear_interp (a, b, t)
	return a + (b-a)*t
end

function rTo_string (...)
	local arg = {...}
	local res = ""
	for i,v in ipairs(arg) do
		res = res .. tostring(v)
	end
	return res
end

--	if e is an element of t, return the key of e
--	return nil otherwise
function rIn (t,e)
	for k,v in pairs(t) do
		if v == e then return k end
	end
end

function rLast (t)
	return t[#t]
end

version_major, version_minor, version_revision, version_codename = love.getVersion( )

function rglSetColor (r,g,b,a)
	if version_major < 11 then
		r = r*255
		g = g*255
		b = b*255
		a = a*255
	end
	love.graphics.setColor(r,g,b,a)
end

vector_t = {}
vector_t_m = {__index = vector_t}

function vector_t.new (x,y)
	return setmetatable({x = x or 0, y = y or 0}, vector_t_m)
end

function vector_t_m.__unm (a)
	return vector_t.new (-a.x,-a.y)
end

function vector_t_m.__add (a,b)
	return vector_t.new (a.x+b.x,a.y+b.y)
end

function vector_t_m.__sub (a,b)
	return vector_t.new (a.x-b.x,a.y-b.y)
end

function vector_t_m.__mul (a,b)
	return vector_t.new (a.x*b.x,a.y*b.y)
end

function vector_t_m.__div (a,b)
	return vector_t.new (a.x/b.x,a.y/b.y)
end

function vector_t:sum ()
	return self.x + self.y
end

function vector_t:magnitude ()
	return math.sqrt((self*self):sum())
end

function vector_t:unpack ()
	return self.x, self.y
end

function vector_t:clone ()
	return vector_t.new(self:unpack())
end

function vector_t.interp (a, b, t, fun)
	fun = fun or linear_interp
	return vector_t.new (fun(a.x, b.x, t), fun(a.y, b.y, t))
end