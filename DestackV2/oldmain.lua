require "graphics"




--[[ DEPRECIATED ]]

CardGraphics = {}
CardSuit = {"Club","Heart","Spade"}
Background = 0
FlipSound = 0
MoveSound = 0
GraphicsPath = "HorizontalGraphics/"--"VerticalGraphics/"

--[[
card values
number card	:	[1,9]
special card:	11

card suits
club	g	:	1
heart	r	:	2
spade	k	:	3

anim types
none		:	0
movedeal	:	1
move		:	2
flip		:	3

--]]

card_t = {}
card_t_m = {__index = card_t}
tmpcard = 0
cards = {}

function card_t.new (n, s)
	local new =
	{	flipsound = love.audio.newSource(FlipSound)	--	card flip sound effect
	,	movesound = love.audio.newSource(MoveSound)	--	card flip sound effect
	,	back = true									--	display the back of the card
	,	graphic = CardGraphics[s][n]				--	the front graphic of the card
	,	number = n									--	the number value of the card
	,	suit = s									--	the suit of the card
	,	position = {x=1580, y=540}						--	the position of the centre of the card
	,	animtype = 0								--	the type of animation currently playing
	,	animtime = 0								--	the timer for the current animation
	,	animorig = {x=0, y=0}						--	the target position of the animation
	,	animtarg = {x=0, y=0}						--	the target position of the animation
	}
	table.insert(cards, new)
	return setmetatable(new, card_t_m)
end

function smoother (a0, a1, t)
	return a1 + (a0-a1)*(t-1)^2
end

function card_t:draw()
	local xscale = 1
	if self.animtype == 3 then
		xscale = self.animtime
		xscale = 3*xscale^2 - 2*xscale^3
		xscale = math.abs(math.cos(xscale*math.pi))
	end
	
	love.graphics.draw(self.back and CardGraphics[4] or self.graphic
	,	self.position.x, self.position.y
	,	0
	,	xscale
	,	1
	,	100
	,	140
	,	0
	,	0
	)
end

function card_t:flip()
	self.animtype = 3
	self.flipsound:play()
end

function card_t:move_to (pos, withFlip)
	self.animtype = withFlip and 1 or 2
	self.animorig = self.position
	self.animtarg = pos
	self.movesound:play()
end

function card_t:update(dt)
	local oldtime = self.animtime
	self.animtime = oldtime + dt
	
	;({	[0] = function()
			self.animtime = 0
		end
	,	[1] = function()
			if self.animtime > 1 then
				self.animtime = 0
				self:flip()
			else
				self.position.x = smoother(self.animorig.x, self.animtarg.x, self.animtime/1)
				self.position.y = smoother(self.animorig.y, self.animtarg.y, self.animtime/1)
			end
		end
	,	[2] = function()
			if self.animtime > 1 then
				self.animtime = 0
				self.animtype = 0
			else
				self.x = smoother(self.animorig.x, self.animtarg.x, self.animtime/1)
				self.y = smoother(self.animorig.y, self.animtarg.y, self.animtime/1)
			end
		end
	,	[3] = function()
			if self.animtime > 1 then
				self.animtime = 0
				self.animtype = 0
			elseif (oldtime < 0.5) and (0.5 <= self.animtime) then
				self.back = not self.back
			end
		end
	})[self.animtype]()
end

function love.load ()
	love.window.setTitle("Destack")
	love.window.setMode(1798,1080,{})
	Background = love.graphics.newImage(GraphicsPath .. "BG.png")
	FlipSound = love.sound.newSoundData("FlipSound.ogg")
	MoveSound = love.sound.newSoundData("MoveSound.ogg")
	for i=1,6 do
--		CardSoundSource[i] = love.audio.newSource(CardSound)
	end
	local cardstoadd = {}
	for i=1,3 do
		CardGraphics[i] = {}
		for j=1,9 do
			CardGraphics[i][j] = love.graphics.newImage(GraphicsPath .. CardSuit[i] .. j .. ".png")
		end
		CardGraphics[i][11] = love.graphics.newImage(GraphicsPath .. CardSuit[i] .. "Special.png")
	end
	CardGraphics[4] = love.graphics.newImage(GraphicsPath .. "CardBack.png")
	
	
	
	tmpcard = card_t.new(11,2)
	
	tmplst = {}
	for j=1,3 do
		for i=1,9 do
			table.insert(tmplst, card_t.new(i,j))
		end
		for i=1,3 do
			table.insert(tmplst, card_t.new(11,j))
		end
	end
end


tmpElst = {}
function love.keypressed(key, scancode, isrepeat)
	if(key=="space")then
		--tmpcard.animtarg.x, tmpcard.animtarg.y = love.mouse.getPosition()
		--tmpcard.animorig.x, tmpcard.animorig.y = tmpcard.x, tmpcard.y
		--tmpcard.animtype = 1
		local x,y = love.mouse.getPosition()
		--tmpcard:move_to(x,y,true)
		for i=1,#tmplst do
			table.insert(tmpElst, {t = (i+math.floor((i-1)/6))*0.1, x=x + 200*((i-1)%6), y=y + 60*math.floor((i-1)/6), i=i})
			--rLog = "added card "..i.." to tmpElst, #"..#tmpElst.."\n" .. rLog
		end
	end
end

function love.mousepressed (x, y, button, istouch)
	if x > 1500 then
		love.event.quit()
	else
		for i=1,#tmplst do
			table.insert(tmpElst, {t = (i+math.floor((i-1)/6))*0.1, x=x + 200*((i-1)%6), y=y + 60*math.floor((i-1)/6), i=i})
		end
	end
end

--[[

	t = time
	i = index
	x
	y

]]

function love.update (dt)
	for i,v in ipairs(cards) do
		v:update(dt)
	end
	
	for i=#tmpElst,1,-1 do
		local v = tmpElst[i]
		
		v.t = v.t - dt
		if v.t < 0 then
			tmplst[v.i]:move_to({x=v.x,y=v.y},true)
			table.remove(tmpElst, i)
		end
	end
end

function love.draw ()
	love.graphics.draw(Background,0,0,0,1920/512,1080/512)
--	local x,y = love.mouse.getPosition()
	
	--tmpcard:draw()
	for _,card in ipairs(cards) do
		card:draw()
	end
	local _, _, flags = love.window.getMode()
	local width, height = love.window.getDesktopDimensions(flags.display)
	love.graphics.print(width .. ", " .. height, 20,20)
	
	for i=1,#tmpElst do
		love.graphics.print(tmpElst[i].t, 120,20*i)
	end
	--love.graphics.print(rLog, 220,20)
end