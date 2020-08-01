card_t = {}
card_t_m = {__index = card_t}
cards = {}



function card_t.new (n, s)
	local new =
	{	flipsound = love.audio.newSource(audio.flip)--	card flip sound effect
	,	movesound = love.audio.newSource(audio.move)--	card flip sound effect
	,	back = true									--	display the back of the card
	,	frontgraphic = graphics.card[s][n]			--	the front graphic of the card
	,	graphic = graphics.back						--	the currently active graphic
	,	number = n									--	the number value of the card
	,	suit = s									--	the suit of the card
	,	position = board.free_cell[2].position		--	the position of the centre of the card
	,	animtype = 0								--	the type of animation currently playing
	,	animtime = 0								--	the timer for the current animation
	,	animorig = {x=0, y=0}						--	the target position of the animation
	,	animtarg = {x=0, y=0}						--	the target position of the animation
	,	zdepth = 1									--	determines the draw order, larger values are drawn on top
	}
	table.insert(cards, new)
	return setmetatable(new, card_t_m)
end

function card_t:flip ()
	self:anim_interupt()
	
	self.animtype = 3
	self.animtime = 0
	self.flipsound:play()
end

function card_t:move_to (pos, mute)
	self:anim_interupt()
	
	self.animtype = 2
	self.orig = self.position
	self.targ = pos
	self.animtime = 0
	if not mute then self.movesound:play() end
end

function card_t:move_to_then_flip (pos)
	self:anim_interupt()
	
	self.animtype = 1
	self.orig = self.position
	self.targ = pos
	self.animtime = 0
	self.movesound:play()
end

function card_t:move_to_with_flip (pos)
	self:anim_interupt()
	
	self.animtype = 4
	self.orig = self.position
	self.targ = pos
	self.animtime = 0
	self.movesound:play()
	self.flipsound:play()
end

function card_t:anim_clear ()
	self.animtype = 0
	self.animtime = 0
end

function card_t:anim_interupt ()
	--	if animation is a movement type
	if rIn({1,2,4}, self.animtype) then
		self.position = self.targ
		if self.animtype == 1 then
			self.animtype = 3
			return self:flip()
		end
	end
	--	if flip
	if self.animtype > 2 then
		if self.animtime < 0.5 then
			self.back = not self.back
			self.graphic = self.back and graphics.back or self.frontgraphic
		end
	end
	self:anim_clear()
end

function card_t:in_bounds (pos)
	return math.abs(pos.x - self.position.x) < 80 and math.abs(pos.y - self.position.y) < 120
end

function smoother (a0, a1, t)
	return a1 + (a0-a1)*(t-1)^2
end

animcases =
{	[0] = function (self, dt)	--	static
	end
,	[1] = function (self, dt)	--	move followed by a flip
		self.animtime = self.animtime + 2*dt
		if self.animtime > 1 then
			self.position = self.targ
			self:flip()
		else
			self.position = vector_t.interp (self.orig, self.targ, self.animtime, smoother)
		end
	end
,	[2] = function (self, dt)	--	move
		self.animtime = self.animtime + 2*dt
		if self.animtime > 1 then
			self.position = self.targ
			self:anim_clear()
		else
			self.position = vector_t.interp (self.orig, self.targ, self.animtime, smoother)
		end
	end
,	[3] = function (self, dt)	--	flip
		local new = self.animtime + dt
		if new > 1 then
			self:anim_clear()
		elseif self.animtime < 0.5
		  and 0.5 <= new
		  then
			self.back = not self.back
			self.graphic = self.back and graphics.back or self.frontgraphic
		end
		self.animtime = new
	end
,	[4] = function (self, dt)	--	move and flip
		local new = self.animtime + dt
		if new > 1 then
			self.position = self.targ
			self:anim_clear()
		else
			self.position = vector_t.interp (self.orig, self.targ, self.animtime, smoother)
			if self.animtime < 0.5
			  and 0.5 <= new
			  then
				self.back = not self.back
				self.graphic = self.back and graphics.back or self.frontgraphic
			end
		end
		self.animtime = new
	end
}

playing_animation = false
playing_critical_animation = false

function card_t:update (dt)
	
	rSwitch (self.animtype, animcases, self, dt)
	
	if self.animtype ~= 0 then
		playing_animation = true
		if self.animtype ~= 2 then
			playing_critical_animation = true
		end
	end
end

function card_t:draw ()
	local xscale = 1
	if self.animtype > 2 then
		xscale = self.animtime
		xscale = 3*xscale^2 - 2*xscale^3
		xscale = math.abs(math.cos(xscale*math.pi))
	end
	--[[
	local mx, my = love.mouse.getPosition()
	if self:in_bounds(mx,my) then
		love.graphics.setColor (127,255,127,255)
	end
	--]]
	love.graphics.draw(self.graphic
	,	self.position.x
	,	self.position.y
	,	0
	,	xscale
	,	1
	,	100
	,	140
	,	0
	,	0
	)
	
	--rglSetColor (1,1,1,1)
end

function card_t.gen_cards ()
	for suit = 1,3 do
		for num=1,9 do
			card_t.new (num, suit)
		end
		for i=1,3 do
			card_t.new (11, suit)
		end
	end
end

function card_t:set_depth (z)
	self.zdepth = z
end

function card_t:set_depth_after (z, t)
	event_t.new(t, card_t.set_depth, self, z)
end