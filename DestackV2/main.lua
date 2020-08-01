--require "dbg"
require "rLib"
require "event"
require "graphics"
require "audio"
require "hand"
require "cards"
require "holders"
require "buttons"
require "board"

function love.load ()
	local _, _, flags = love.window.getMode()
	local width, height = love.window.getDesktopDimensions(flags.display)
	
	love.window.setTitle("Destack")
	love.window.setMode(1798,1080,{})
	
	graphics.load()
	audio.load()
	board.init()
	card_t.gen_cards()
	math.randomseed(12)	--	12 - hold start, 14 - stack start
end

step_hook_func = NIL_FUNC

function love.update (dt)
	hand.position.x, hand.position.y = love.mouse.getPosition()
	update_hand_store_position()
	
	if dealt --[[ and not playing_animation ]] and #hand.store == 0 and #event_list == 0 then
		local raised = board.check_raise()
		if not raised then
			for i,h in pairs(board.suit_hold) do
				local valid = h:can_fill()
				if valid then h:fill(valid) end
			end
		end
	end
	
	tick_events(dt)
	tick_flashes(dt)
	
	playing_animation = false
	for i,c in ipairs(cards) do
		c:update(dt)
	end
	step_hook_func(dt)
end

function love.draw ()
	love.graphics.draw(graphics.bg
	,	0
	,	0
	,	0
	,	1798/512
	,	1080/512
	)
	
	for i,v in ipairs(board.cell_list) do
		draw_cell(v)
	end
	
	--	depth sort
	for i=1,36 do	--	prevent flickering
		cards[i].zdepth = math.floor(cards[i].zdepth) + 0.005*i
	end
	table.sort(cards, function(a,b) return a.zdepth < b.zdepth end)
	for i=1,36 do
		cards[i]:draw()
	end
	
	for i,b in ipairs(board.button) do
		b:draw()
	end
	
	love.graphics.setBlendMode("screen")
	--[[
	for i,h in ipairs(board.suit_hold) do
		if h:can_fill() then
			love.graphics.draw(graphics.glow
			,	h.position.x
			,	h.position.y
			,	0
			,	1
			,	1
			,	100
			,	140
			,	0
			,	0
			)
		end
	end
	for i,f in ipairs(flashes) do
		local v = smoother(255,0,f.timer)
		love.graphics.setColor(v,v,v,255)--255,255,255,v)
		love.graphics.draw(graphics.flash
		,	f.position.x
		,	f.position.y
		,	0
		,	1
		,	1
		,	100
		,	140
		,	0
		,	0
		)
	end
	--]]
	draw_glows()
	
	love.graphics.setBlendMode("alpha")
	rglSetColor (1,1,1,1)
	
	for i,v in ipairs(event_list) do
		love.graphics.print(v.timer, 20, 20*i)
	end
	for i,v in ipairs(flashes) do
		love.graphics.print(v.timer, 620, 20*i)
	end
	love.graphics.print(tostring(step_hook_func), 320, 20)
	love.graphics.print(tostring(playing_animation), 320, 40)
	for i,v in ipairs(board.destack[1].store) do
		love.graphics.print(tostring(v), 920, 20*i)
	end
	--love.graphics.print(tostring(board.destack[1].store[6]), 920, 20*8)
end



--[[
function deal ()
	for i,c in ipairs(cards) do
		c.zdepth = math.random()
	end
	table.sort(cards, function(a,b) return a.zdepth < b.zdepth end)
	for i,c in ipairs(cards) do
		c.zdepth = i
		--event_t.new ((i+math.floor((i-1)/6))*0.1, card_t.move_to_then_flip, c, vector_t.new(100 + 199*((i-1)%6),360 + 60*math.floor((i-1)/6)))
		event_t.new (0.1*(i+math.floor((i-1)/6))
		,	function(i,c)
				board.destack[(i-1)%6 + 1]:add_top(c)
			end
		,	i
		,	c
		)
	end
	dealt = true
end
--]]
--[[
function check_for_raisers ()
	local n = 10
	for i=1,3 do
		n = math.min(n, #board.suit_stack[i].store + 1)
	end
	
	for i,d in ipairs(board.destack) do
		if #d.store > 0 then
			local card = false
			if d.store[1].number == n then
				card = d:take_base()
			elseif d.store[#d.store].number == n then
				card = d:take_top()
			end
			
			if card then
				local stack = board.suit_stack[card.suit]
				stack:add(card)
				return true
			end
		end
	end
	return false
end
--]]
--[
function love.keypressed (key, scancode, isrepeat)
	local num = tonumber(key)
	if num and num < 10 then
		local c = board.destack[num]:take_top()
		table.insert(hand.store, c)
		c:move_to(hand.position)
	end
end
--]]
