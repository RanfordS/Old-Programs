--[[ General ]]

--	card:: w:16, h:24
--	hold:: w:18, h:26

function draw_cell (cell)
	local dstk = getmetatable(cell) == destack_t_m
	love.graphics.draw (cell.graphic
	,	cell.position.x
	,	cell.position.y
	,	0	--angle
	,	1	--xscale
	,	1	--yscale
	,	110	--xorigin
	,	dstk and 210 or 150	--yorigin
	)
	
	if cell:in_bounds(hand.position) then
		rglSetColor (1,1,0,1)
	elseif dstk and cell:in_stacker_bounds(hand.position) then
		rglSetColor (1,0,1,1)
	else
		rglSetColor (0,1,0,1)
	end
	love.graphics.circle ("line", cell.position.x, cell.position.y, 60)
--	if type(cell.store) == type{} then
--		love.graphics.setColor (255,0,0,255)
--		love.graphics.print(#cell.store, cell.position.x, cell.position.y - 160)
--	end
	rglSetColor (1,1,1,1)
end

--[[ Free Cell]]

free_cell_t = {}
free_cell_t_m = {__index = free_cell_t}

function free_cell_t.new ()
	local new =
	{	store = false					--	reference to the card held within, false if empty
	,	position = vector_t.new(0,0)	--	the position of the centre of the free cell
	,	graphic = graphics.free			--	the graphic of the free cell
	}
	return setmetatable(new, free_cell_t_m)
end

function free_cell_t:can_add_card (card)
	return not self.store
end

--	attempts to add card to this free cell, returns false if the cell is full, returns true if the card was added
function free_cell_t:add_card (card)
	self.store = card
	card:move_to(self.position)
end

--	empty safe
function free_cell_t:take_card ()
	local card = self.store
	self.store = false
	return card
end

--	queries if the position interacts with the holder
function free_cell_t:in_bounds (pos)
	local dif = pos - self.position
	return math.abs(dif.x) < 90 and math.abs(dif.y) < 130
end
--[[
function free_cell_t:interact (pos)
	if self:in_bounds(pos) then
		if #hand.store == 0
		  and self.store
		  then--take card from free cell
			self.store:move_to(hand.storepos[1])	--	trigger anim
			table.insert(hand.store, self.store)	--	move to hand store
			self.store = false						--	clear own reference
			hand.old_placement.cell = self			--	mark original reference
			return true
		elseif #hand.store == 1
		  and not self.store
		  then--add card to free cell
			hand.store[1]:move_to(self.position)
			self.store = hand.store[1]

		end
	end
	return false
end
--]]
--	queries if the card can be added to the free cell
function free_cell_t:can_add (card)
	return not self.store
end

--	add the card to the cell, no verification
function free_cell_t:add (card)
	card:move_to(self.position)
	self.store = card
	card:set_depth_after(1, .5)
end

function free_cell_t:clear ()
	self.store = false
end

--[[ Suit Stack ]]

suit_stack_t = {}
suit_stack_t_m = {__index = suit_stack_t}

function suit_stack_t.new (suit)
	local new =
	{	store = {}
	,	suit = suit
	,	position = vector_t.new(0,0)
	,	graphic = graphics.stack[suit]
	}
	return setmetatable(new, suit_stack_t_m)
end

function suit_stack_t:in_bounds (pos)
	local dif = pos - self.position
	return math.abs(dif.x) < 90 and math.abs(dif.y) < 130
end

--	queries if the card can be added to the suit stack
function suit_stack_t:can_add (card)
	local top = #self.store
	return self.suit == card.suit and top + 1 == card.number
end

--	add the card to the stack, no verification
function suit_stack_t:add (card)
	--	move card
	card:move_to(self.position)
	table.insert(self.store, card)
	--	manage depth
	card:set_depth(50 + #self.store)
	card:set_depth_after(#self.store, .5) --event_t.new(1, function(c) c.zdepth = c.zdepth - 50 end, card)
	--	VFX
	if card.number == 9 then
		event_t.new(.5, flash_new, self.position)
	end
end

--	clears all cards from the stack reference
function suit_stack_t:clear ()
	self.store = {}
end

--	queries if the stack is complete
function suit_stack_t:complete ()
	return #self.store == 9
end

--[[ Suit Hold ]]

suit_hold_t = {}
suit_hold_t_m = {__index = suit_hold_t}

function suit_hold_t.new (suit)
	local new =
	{	store = {}
	,	suit = suit
	,	position = vector_t.new(0,0)
	,	graphic = graphics.hold[suit]
	}
	return setmetatable(new, suit_hold_t_m)
end

function suit_hold_t:in_bounds (pos)
	local dif = pos - self.position
	return math.abs(dif.x) < 90 and math.abs(dif.y) < 130
end

--	checks if the suit_hold can be added to
--	returns list of relevant stacks if it can
--	returns false otherwise
function suit_hold_t:can_fill ()
	--	cell cannot be filled if it is already full
	if #self.store > 0 then return false end
	
	local count = {}
	--	search destacks
	for i,d in ipairs(board.destack) do
		--	don't search empty stacks
		if #d.store > 0 then
			local c = d.store[1]
			
			if c.number == 11
			  and c.suit == self.suit
			  then
				table.insert(count, {d=d, top=false})
			end
			
			--	check stack top
			if #d.store > 1 then
				c = rLast(d.store)
				if c.number == 11
				  and c.suit == self.suit
				  then
					table.insert(count, {d=d, top=true})
				end
			end
		end
	end
	--	search free cells
	for i,f in ipairs(board.free_cell) do
		local c = f.store
		if c and c.number == 11 and c.suit == self.suit then
			table.insert(count, {f=f})
		end
	end
	--	did the search yield enough cards to fill the hold
	if #count < 3 then return false end
	return count
end

--	takes the cards from the reference list and adds them to the hold
function suit_hold_t:fill (ref)
	for i,r in ipairs(ref) do
		event_t.new((i-1)*0.1
		,	function(r,s)
				local c = false
				--	is the reference to a destack or a free cell
				if r.d then
					c = destack_t[r.top and "take_top" or "take_base"](r.d)
				else
					c = r.f:take_card()
				end
				c:move_to(s.position)
				table.insert(s.store, c)
				c:set_depth(50)
				c:set_depth_after(1, 1)
			end
		,	r
		,	self
		)
	end
	event_t.new(.8, flash_new, self.position)
end

--	clears all cards from the stack reference
function suit_hold_t:clear ()
	self.store = {}
end

--	queries if the stack is complete
function suit_stack_t:complete ()
	return #self.store == 3
end


--[[ Destack ]]

destack_t = {}
destack_t_m = {__index = destack_t}

function destack_t.new ()
	local new =
	{	store = {}
	,	storepos = {}
	,	position = vector_t.new(0,0)
	,	graphic = graphics.destack
	}
	return setmetatable(new, destack_t_m)
end

function destack_t:in_bounds (pos)
	local dif = pos - self.position
	return math.abs(dif.x) < 90 and math.abs(dif.y) < 130
end

function destack_t:in_stacker_bounds (pos)
	local dif = vector_t.new(0,190) + pos - self.position
	return math.abs(dif.x) < 90 and math.abs(dif.y) < 110
end


function destack_t:can_add_top (card)
	local top = rLast(self.store)
	
	return (not top)	--	if empty, can add
	or (card.suit ~= top.suit and card.number+1 == top.number)	--	if suit differs and value decreases, can add
end

function destack_t:add_top (card, deal)
	local new_pos = self.position:clone()
	new_pos.y = new_pos.y + 60 * #self.store
	table.insert(self.store, card)
	table.insert(self.storepos, new_pos)
	if deal then
		card:move_to_then_flip(new_pos)
	else
		card:move_to(new_pos)
	end
	card:set_depth_after(#self.store, 0.5)
end

function destack_t:take_top ()
	local i = #self.store
	table.remove(self.storepos, i)
	return table.remove(self.store, i)
end


function destack_t:can_add_base (card)
	local bot = self.store[1]
	
	return (not bot)	--	if empty, can add
	or (card.suit == bot.suit and card.number-1 == bot.number)	--	if suit matches and value decreases, can add
end

function destack_t:add_base (card)
	local new_pos = self.position:clone()
	new_pos.y = new_pos.y + 60 * #self.store
	table.insert(self.storepos, new_pos)
	
	table.insert(self.store, 1, card)
	for i,c in ipairs(self.store) do
		c:move_to(self.storepos[i], i ~= 1)
		c:set_depth(i)
	end
end

function destack_t:take_base()
	table.remove(self.storepos, #self.store)
	local take = table.remove(self.store, 1)
	for i,c in ipairs(self.store) do
		c:move_to(self.storepos[i], true)
		c:set_depth(i)
	end
	return take
end


function destack_t:clear ()
	self.store = {}
	self.storepos = {}
end