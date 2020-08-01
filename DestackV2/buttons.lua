--[[ Buttons ]]

button_t = {}
button_t_m = {__index = button_t}

function button_t.new (graphic, hook, timer_rate)
	
	local new =
	{	position = vector_t.new()
	,	graphic = graphic
	,	hook = hook					--	the function that replaces love.update
	,	timer = 0
	,	timer_rate = timer_rate
	}
	return setmetatable(new, button_t_m)
end

function button_t.proxy_new (i)
	if i == 1 then
		return button_t.new (graphics.help, button_help_hook, 1)
elseif i == 2 then
		return button_t.new (graphics.new , button_new_hook, 1)
elseif i == 3 then
		return button_t.new (graphics.quit, button_quit_hook, 0.5)
	end
end

function button_t:draw ()
	local mx, my = love.mouse.getPosition()
	if self:in_bounds(vector_t.new(mx,my)) then
		rglSetColor (0,0,1,1)
	end
	
	love.graphics.draw(self.graphic
	,	self.position.x
	,	self.position.y
	,	0
	,	1
	,	1
	,	45
	,	45
	)
	
	rglSetColor (1,1,1,1)
	love.graphics.setLineWidth(10)
	love.graphics.arc("line", "open", self.position.x, self.position.y, smoother(160,80,self.timer), -0.5*math.pi, smoother(-0.5,-2.5,self.timer)*math.pi, 64)
	love.graphics.setLineWidth(1)
end

function button_t:in_bounds (pos)
	return (pos - self.position):magnitude() < 60
end

function button_t:interact ()
	step_hook_func = function(dt) button_t.ticker(self, dt) end
end

function button_t.ticker (self, dt)
	if self:in_bounds(hand.position) and love.mouse.isDown(1) then
		self.timer = self.timer + dt * self.timer_rate
		if self.timer < 1 then return end
		self.hook()
	end
	self.timer = 0
	step_hook_func = NIL_FUNC
end

function button_help_hook ()
	--	help code
	flash_new(board.free_cell[1].position)
end

function button_new_hook ()
	--	new game code
	if not dealt then
		board.deal()
	elseif not playing_animation then
		for i,c in ipairs(cards) do
			event_t.new ((36-i)*0.1, card_t.move_to_with_flip, c, board.free_cell[2].position, true)
		end
		for i,c in ipairs(board.cell_list) do
			c:clear()
		end
		
		dealt = false
	end
end

function button_quit_hook ()
	--	quit game code
	love.event.quit()
end

