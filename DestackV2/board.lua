--[[ Board ]]

board =
{	free_cell = {}
,	suit_stack = {}
,	suit_hold = {}
,	destack = {}
,	button = {}
,	cell_list = {}
}

--	currently using hard-coded solution
function board.arrange ()
	
	for i,d in ipairs(board.destack) do
		d.position.x = 256*i - 128 --100 + (i-1)*199
		d.position.y = 330
	end
	for suit=1,3 do
		local x = (3+suit)*256 + 128 -- 1295 + (suit-1)*200
		
		board.suit_stack[suit].position.x = x
		board.suit_stack[suit].position.y = 190
		
		board.free_cell[suit].position.x = x
		board.free_cell[suit].position.y = 470
		
		board.suit_hold[suit].position.x = x
		board.suit_hold[suit].position.y = 750
		
		board.button[suit].position.x = x
		board.button[suit].position.y = 975
	end
end

function board.init ()
	for suit = 1,3 do
		board.free_cell[suit]  = free_cell_t.new()
		table.insert(board.cell_list, board.free_cell[suit])
		
		board.suit_stack[suit] = suit_stack_t.new(suit)
		table.insert(board.cell_list, board.suit_stack[suit])
		
		board.suit_hold[suit]  = suit_hold_t.new(suit)
		table.insert(board.cell_list, board.suit_hold[suit])
		
		board.button[suit]    = button_t.proxy_new(suit)
	end
	for i = 1,4 do
		board.destack[i] = destack_t.new()
		table.insert(board.cell_list, board.destack[i])
	end
	board.arrange()
end

dealt = false
function board.deal ()
	--	use depth to get comparator for table.sort
	for i,c in ipairs(cards) do
		c.zdepth = math.random()
	end
	table.sort(cards, function(a,b) return a.zdepth < b.zdepth end)
	--	deal
	for i,c in ipairs(cards) do
		c.zdepth = i
		event_t.new( 0.1 * ( (i-1) + math.floor( (i-1)/4 ) )	--	produces dealing pattern: deal 6, pause 1
		,	function(i,c)
				board.destack[(i-1)%4 + 1]:add_top(c, true)
			end
		,	i
		,	c
		)
	end
	dealt = true
end

--	searches for a card to raise, if one is found, it is raised
function board.check_raise ()
	local n = 10
	--	check for the highest value that can be added
	for i=1,3 do
		n = math.min(n, #board.suit_stack[i].store + 1)
	end
	--	search destacks
	for i,d in ipairs(board.destack) do
		if #d.store > 0 then
			local card = false
			--	check top and bottom
			if d.store[1].number == n then
				card = d:take_base()
			elseif d.store[#d.store].number == n then
				card = d:take_top()
			end
			--	add any card that was found
			if card then
				local stack = board.suit_stack[card.suit]
				stack:add(card)
				return true
			end
		end
	end
	--	search free cells
	for i,f in ipairs(board.free_cell) do
		if f.store and f.store.number == n then
			local card = f:take_card()
			board.suit_stack[card.suit]:add(card)
			return true
		end
	end
end










