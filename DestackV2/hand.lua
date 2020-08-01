

hand =
{	store    = {}				--	a list of all the cards currently stored within the hand
,	storepos = {}				--	a list of positions to be used by reference by the cards within the store
,	position = vector_t.new()	--	current position of the hand
,	old_placement =
	{--	cell = false			--	reference to the cell that originally contained the current hand
	--,	top  = false			--	where to return to, nil if free cell, true or false destack
	}
}

function add_to_hand (card, ref, delay)
	local pos = hand.position:clone()
	pos.y = pos.y + 30*#hand.store
	card.zdepth = 50 + #hand.store

	card:move_to(pos)

	table.insert(hand.storepos, pos)
	table.insert(hand.store, card)
	table.insert(hand.old_placement, ref)
end

function take_from_hand ()
	local card = table.remove(hand.store, 1)
--	for i,c in ipairs(hand.store) do
--		c:move_to(hand.storepos[i], true)
--	end
end

function update_hand_store_position ()
	for i,p in ipairs(hand.storepos) do
		p.x = hand.position.x
		p.y = hand.position.y + 50*(i-1)
	end
end

function clear_hand ()
	hand.store = {}
	hand.storepos = {}
	hand.old_placement = {}
end

function love.mousepressed (x, y, button, istouch)
	if #hand.store > 0 or #event_list > 0 then return end
	--	update hand
	hand.position.x = x
	hand.position.y = y
	--	click to deal
	if not dealt and board.free_cell[2]:in_bounds(hand.position) then
		board.deal()
		return
	end
	--	check buttons
	for i,b in ipairs(board.button) do
		if b:in_bounds(hand.position) then
			b:interact(hand.position)
			return
		end
	end
	--	check suit holds
	for i,h in ipairs(board.suit_hold) do
		if h:in_bounds(hand.position) then
			local valid = h:can_fill()
			if valid then
				h:fill(valid)
				return
			end
		end
	end
	--	check free cells
	for i,f in ipairs(board.free_cell) do
		if f:in_bounds(hand.position) and f.store then
			add_to_hand(f:take_card(), {cell=f})
			return
		end
	end
	--	check destacks
	for I,d in ipairs(board.destack) do
		if #d.store > 0 then
			--	check base
			if d:in_stacker_bounds(hand.position) then
				--error "got here"
				add_to_hand(d:take_base(), {cell=d, top=false})
				return
			end
			--	find grab point
			local i = #d.store
			while i > 0 do
				if d.store[i]:in_bounds(hand.position) then
					--error "got here"
					--	check if valid grab
					local c = d.store[i]
					--[[
					if c.number == 11 and i == #d.store then
						--error "got here"
						flash_new(c.position, true)
						return
					end
					--]]
					local j = i + 1
					
					while j <= #d.store do
						local nc = d.store[j]
						if not (nc.suit ~= c.suit and nc.number == c.number - 1) then
							if i == 1 then
								add_to_hand(d:take_base(), {cell=d, top=false})
							end
							return
						end
						j = j+1
						c = nc
					end
					local list = {}
					for k = i,j-1 do
						--error "got here, drain stack"
						table.insert(list, d:take_top())
					end
					if #list == 1 then
						add_to_hand(c, {cell=d, top=true})
						return
					end
					for k,c in pairs(list) do
						event_t.new(0.2*((j-i-k+1)/(j-i))
						,	add_to_hand
						,	c
						,	{cell=d, top=true}
						)
					end
					return
				else
					i = i-1
				end
			end
		end
	end
end

function love.mousereleased ()
	if #hand.store == 0 or #event_list > 0 then return end

	local head = hand.store[1]

	--	single unit placements
	if #hand.store == 1 then
		--	free cell
		for i,f in ipairs(board.free_cell) do
			if f:in_bounds(hand.position) and f:can_add(head) then
				f:add(head)
				clear_hand()
				return
			end
		end
		--	suit stack
		for i,s in ipairs(board.suit_stack) do
			if s:in_bounds(hand.position) and s:can_add(head) then
				s:add(head)
				clear_hand()
				return
			end
		end
		--	destack base
		for i,d in ipairs(board.destack) do
			if d:in_stacker_bounds(hand.position) and d:can_add_base(head) then
				d:add_base(head)
				clear_hand()
				return
			end
		end
	end

	for i,d in ipairs(board.destack) do
		if (#d.store == 0 and d or rLast(d.store)):in_bounds(hand.position)
		  and d:can_add_top(head)
		  then
			for i,c in pairs(hand.store) do
				event_t.new(0.1*(i-1)
				,	destack_t.add_top
				,	d
				,	c
				)
			end
			clear_hand()
			return
		end
	end

	--	return to original position
	flash_new(head.position, true)
	for i,c in ipairs(hand.store) do
		local p = hand.old_placement[i]
		--	return to free_cell
		if p.top == nil then
			p.cell:add(c)
		elseif p.top then
			event_t.new(0.1*(i-1)
			,	destack_t.add_top
			,	p.cell
			,	c
			)
		else
			p.cell:add_base(c)
		end
	end
	clear_hand()
end