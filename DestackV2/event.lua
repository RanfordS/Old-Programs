event_t = {}
event_t_m = {__index = event_t}
event_list = {}

function event_t.new (timer, hook, ...)
	local new = 
	{	timer = timer
	,	hook = hook
	,	args = {...}
	}
	setmetatable(new, event_t_m)
	table.insert(event_list, new)
	return new
end

function event_t:do_event ()
	self.hook(unpack(self.args))
end

function tick_events (dt)
	for i = #event_list, 1, -1 do
		local e = event_list[i]
		local t = e.timer - dt
		if t > 0 then
			e.timer = t
		else
			e:do_event()
			table.remove(event_list, i)
		end
	end
end