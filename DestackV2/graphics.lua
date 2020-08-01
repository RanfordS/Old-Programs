graphics = 
{	card	= {}
,	back	= false
,	bg		= false
,	hold	= {}
,	stack	= {}
,	destack	= false
,	free	= false
,	help	= false
,	new 	= false
,	quit	= false
,	flash	= false
,	glow	= false
,	dskglow	= false
}

graphics_path = "HorizontalGraphics/"--"VerticalGraphics/"

card_suit =
{ [1] = "Club"
, [2] = "Heart"
, [3] = "Spade"
}

function graphics.load ()
	--	general
	graphics.back	 = love.graphics.newImage (graphics_path .. "CardBack.png")
	graphics.bg		 = love.graphics.newImage (graphics_path .. "BG.png")
	graphics.destack = love.graphics.newImage (graphics_path .. "DestackHold.png")
	graphics.free	 = love.graphics.newImage (graphics_path .. "FreeCell.png")
	graphics.help	 = love.graphics.newImage (graphics_path .. "HelpButton.png")
	graphics.new	 = love.graphics.newImage (graphics_path .. "NewGameButton.png")
	graphics.quit	 = love.graphics.newImage (graphics_path .. "QuitGameButton.png")
	graphics.flash	 = love.graphics.newImage (graphics_path .. "CardFlash.png")
	graphics.glow	 = love.graphics.newImage (graphics_path .. "CardGlow.png")
	graphics.dskglow = love.graphics.newImage (graphics_path .. "DestackGlow.png")
	--	suited
	for suit = 1,3 do
		local suit_path = graphics_path .. card_suit[suit]
		graphics.card[suit] = {}
		for num = 1,9 do
			graphics.card[suit][num] =
				love.graphics.newImage (suit_path .. num .. ".png")
		end
		graphics.card[suit][11] =
			love.graphics.newImage (suit_path .. "Special.png")
		graphics.hold[suit] = 
			love.graphics.newImage (suit_path .. "Hold.png")
		graphics.stack[suit] = 
			love.graphics.newImage (suit_path .. "Stack.png")
	end
end



flashes = {}

function flash_new (pos,err)
	local new =
	{	position = pos
	,	is_error = err
	,	timer = 0
	}
	table.insert(flashes, new)
	if not err then love.audio.newSource(audio.flash):play() end
end

function tick_flashes (dt)
	for i,f in ipairs(flashes) do
		f.timer = f.timer + 2*dt
	end
	while #flashes > 0 and flashes[1].timer > 1 do
		table.remove(flashes, 1)
	end
end

function draw_glows ()
	--	placement glows
	if #hand.store > 0 then
		--	destack glows
		for i,d in ipairs(board.destack) do
			if d:can_add_base(hand.store[1]) then
				love.graphics.draw(graphics.dskglow
				,	d.position.x
				,	d.position.y
				,	0
				,	1
				,	1
				,	110
				,	210
				,	0
				,	0
				)
			end
			if d:can_add_top(hand.store[1]) then
				local pos = #d.store
				pos = pos > 0 and d.storepos[pos] or d.position
				love.graphics.draw(graphics.glow
				,	pos.x
				,	pos.y
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
	end
	--	hold glows
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
		local v = smoother(1,0,f.timer)
		local e = f.is_error and 0 or v
		rglSetColor(v,e,e,1)
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
end