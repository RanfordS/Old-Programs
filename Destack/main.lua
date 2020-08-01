
--[[~@> Destack <@~]]

function drawPlace(x, y, destack)
	local verts = {
		-2 + x, -2 + y,
		52 + x, -2 + y,
		52 + x, 77 + y,
		-2 + x, 77 + y}
	
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.polygon('line', verts)
	
	if(destack)then
		if(hand[1]==nil)then
			verts = {
				15 + x, -10 + y,
				35 + x, -10 + y,
				25 + x, -20 + y}
		else
			verts = {
				15 + x, -20 + y,
				35 + x, -20 + y,
				25 + x, -10 + y}
		end
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.polygon('line', verts)
	end
end

function drawCard(card, x, y, over)
	if(over==nil)then over = false end
	if(over or card.draw)then
		local suit = 2*card.suit
		local num = card.num
		local verts = {
			 0 + x,  0 + y,
			50 + x,  0 + y,
			50 + x, 75 + y,
			 0 + x, 75 + y}
		local suitcols = {
			{   0,   0,   0, 255}, { 255, 255, 255, 255},
			{ 255,   0,   0, 255}, { 255, 240, 240, 255},
			{   0, 191,   0, 255}, { 240, 255, 240, 255}}
		local suitspecials = {'K','R','G'}
		
		if(num == -2)then
			love.graphics.setColor(127, 127, 127, 255)
			love.graphics.polygon('fill', verts)
			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.polygon('line', verts)
		else
			if(num == -1)then num = suitspecials[card.suit] end
			
			love.graphics.setColor(suitcols[suit])
			love.graphics.polygon('fill', verts)
			
			love.graphics.setColor(suitcols[suit-1])
			love.graphics.print(num, 5 + x, 5 + y)
			love.graphics.polygon('line', verts)
		end
	end
end

function drawGroup(suit, x, y)
	local verts = {
		 0 + x,  0 + y,
		50 + x,  0 + y,
		50 + x, 21 + y,
		 0 + x, 21 + y}
	local suitcols = {
		{ 255, 255, 255, 255},
		{ 255, 240, 240, 255},
		{ 240, 255, 240, 255}}
	local suitspecials = {'K','R','G'}
	
	love.graphics.setColor(suitcols[suit])
	love.graphics.polygon('line', verts)
	love.graphics.printf(suitspecials[suit], x, 5 + y, 50, "center")
end

function newgame()
	local tobedealt = {}
	hand = {}
	hold = {}
	stack = {}
	board = {}
	
	win = false
	
	for i=1,6 do
		board[i]={}
	end
	for s=1,3 do
		for i=1,9 do
			table.insert(tobedealt, {suit = s, num = i, draw = true})
		end
		for i=1,3 do
			table.insert(tobedealt, {suit = s, num = -1, draw = true})
		end
	end
	local c=1
	while(#tobedealt > 0)do
		table.insert(board[c], table.remove(tobedealt, math.random(1,#tobedealt)))
		c = c + 1
		if(c>6)then c = 1 end
	end
	
	checkhold()
end

function checkhold()
	count = {0,0,0}
	for i=1,3 do
		if(hold[i]~=nil)then
			if(hold[i].num == -1)then
				count[hold[i].suit] = count[hold[i].suit] + 1
			end
		end
	end
	for c=1,6 do
		local n = #board[c]
		if(n>0)then
			if(board[c][1].num == -1)then
				count[board[c][1].suit] = count[board[c][1].suit] + 1
			end
			if(n>1)then
				if(board[c][n].num == -1)then
					count[board[c][n].suit] = count[board[c][n].suit] + 1
				end
			end
		end
	end
	group = {0,0,0}
	for i=1,3 do
		if(hold[i]==nil)then
			for j=1,3 do
				group[j] = i
			end
		elseif(hold[i].num == -1)then
			group[hold[i].suit] = i
		end
	end
	for i=1,3 do
		if(count[i]~=3)then
			group[i] = 0
		end
	end
end

function checkwin()
	win = true
	for i=1,3 do
		if(hold[i]==nil)then
			win = false
		elseif(hold[i].num~=-2)then
			win = false
		end
		if(stack[i]==nil)then
			win = false
		elseif(stack[i].num~=9)then
			win = false
		end
	end
end

gScale = 2

function love.load()
	love.window.setTitle("Destack")
	love.window.setMode(430*gScale,458*gScale,{msaa=8})
	
	math.randomseed(os.time())
	newgame()
end

function love.draw()
	love.graphics.origin()
	love.graphics.scale(gScale,gScale)
	for i=1,3 do
		drawPlace(60*i -  50, 10, false)
		drawPlace(60*i + 190, 10, false)
		local card = hold[i]
		if(card~=nil)then
			drawCard(card, 60*i - 50, 10)
		end
		card = stack[i]
		if(card~=nil)then
			drawCard(card, 60*i + 190, 10)
		end
		if(group[i]~=0)then
			drawGroup(i, 190, 29*i - 21)
		end
	end
	
	for c=1,6 do
		drawPlace(60*c - 20, 115, true)
		local col = board[c]
		for i=1,#col do
			local card = col[i]
			drawCard(card, 60*c - 20, 20*i + 95)
		end
	end
	
	mx, my = love.mouse.getPosition()
	mx = mx/gScale
	my = my/gScale
	for i=1,#hand do
		local card = hand[i]
		drawCard(card, mx - 25, my + 20*i-20, true)
	end
	love.graphics.setColor(255,255,255,255)
	if(win)then love.graphics.print("You won", 10, 360) end
	love.graphics.print(string.format("count {%i,%i,%i}", count[1], count[2], count[3]), 10, 380)
	love.graphics.print(string.format("group {%i,%i,%i}", group[1], group[2], group[3]), 10, 400)
	love.graphics.print(string.format("mx = %03i, my = %03i", mx, my), 10, 440)
	if(hand[1]~=nil)then
		love.graphics.print(string.format("s = %i, n = %i, c = %i, i = %i", hand[1].suit, hand[1].num, hand.source.col, hand.source.id), 10, 420)
	end
end

function love.mousepressed(mx, my, button, istouch)
	mx = mx/gScale
	my = my/gScale
	hand[1] = nil
	if(9<my and my<86)then	--	hold
		local x = mx - 10
		local rem = x % 60
		if(rem < 51)then
			local i = math.ceil(x / 60)
			if(i==4)then	--	group
				local y = my - 10
				rem = y % 29
				if(rem < 22)then
					local s = math.ceil(y / 22)
					if(0<s and s<4)then
						if(group[s]>0)then	
							for i=1,3 do
								if(hold[i]~=nil)then
									if(hold[i].num == -1 and hold[i].suit==s)then
										hold[i] = nil
									end
								end
							end
							for c=1,6 do
								if(#board[c]>0)then
									if(board[c][1].num == -1 and board[c][1].suit == s)then
										table.remove(board[c], 1)
									end
								end
								local n = #board[c]
								if(n > 0)then
									if(board[c][n].num == -1 and board[c][n].suit == s)then
										table.remove(board[c], n)
									end
								end
							end
						end
						hold[group[s]] = {suit = s, num = -2, draw = true}
						checkhold()
						checkwin()
					end
				end
			elseif(0<i and i<4)then
				if(hold[i]~=nil)then
					if(hold[i].num~=-2)then
						hand[1] = hold[i]
						hold[i].draw = false
						hand.source = {col = 7, id = i}
					end
				end
			end
		end
	else
		local x = mx - 40
		local rem = x % 60
		if(rem < 50)then
			local c = math.ceil(x / 60)
			if(c>0 and c<7)then
				local l = nil
				local y = my - 115
				
				if(y<0)then
					hand[1] = board[c][1]
					hand[1].draw = false
					hand.source = {col = c, id = 1}
				end
				
				for i=1,#board[c] do
					local ly = y - 20*i + 20
					if(-1<ly and ly<76)then
						l = i
					end
				end
				if(l~=nil)then
					local valid = true
					local suit = -1
					local num = board[c][l].num + 1
					for i=l,#board[c] do
						if(suit==board[c][i].suit)then
							valid = false
							break
						end
						suit = board[c][i].suit
						if(num-1~=board[c][i].num)then
							valid = false
							break
						end
						num = board[c][i].num
					end
					if(valid)then
						for i=l,#board[c] do
							table.insert(hand, board[c][i])
							board[c][i].draw = false
						end
						hand.source = {col = c, id = l}
					end
				end
			end
		end
	end
end

function love.mousereleased(mx, my, button, istouch)
	mx = mx/gScale
	my = my/gScale
	if(hand[1]~=nil)then
		for i=1,#hand do
			hand[i].draw = true
		end
		
		if(my>80)then		--	board
			local x = mx - 40
			local rem = x % 60
			if(rem < 50)then
				local c = math.ceil(x / 60)
				if(0<c and c<7)then
					if(my>114)then	--	main board
						local h = hand[1]
						local b = board[c]
						b = b[#b]
						if(b==nil)then b = {suit = -1, num = h.num+1} end
						if(h.suit~=b.suit and h.num+1==b.num)then
							if(hand.source.col == 7)then
								hold[hand.source.id] = nil
								table.insert(board[c], hand[1])
							else
								while(#hand>0)do
									table.remove(board[hand.source.col], hand.source.id)
									table.insert(board[c], table.remove(hand, 1))
								end
							end
						end
					else			--	destack
						local h = hand[#hand]
						local b = board[c][1]
						if(h.suit~=b.suit and h.num-1==b.num)then
							if(hand.source.col == 7)then
								hold[hand.source.id] = nil
								table.insert(board[c], 1, hand[1])
							else
								while(#hand>0)do
									table.remove(board[hand.source.col], hand.source.id)
									table.insert(board[c], 1, table.remove(hand, #hand))
								end
							end
						end
					end
				end
			end
		elseif(my>9)then	--	hold or stack
			if(#hand==1)then
				local x = mx - 10
				local rem = x % 60
				if(rem < 50)then
					local c = math.ceil(x / 60)
					if(0 < c and c~=4 and c < 8)then
						if(c < 4)then	--	hold
							if(hold[c]==nil)then
								local s = hand.source
								if(s.col==7)then
									hold[s.id] = nil
								else
									table.remove(board[s.col], s.id)
								end
								hold[c] = hand[1]
							end
						else		--	stack
							c = c-4
							local ref = 1
							local suit = hand[1].suit
							if(stack[c]~=nil)then
								ref = stack[c].num + 1
								suit = stack[c].suit
							end
							if(hand[1].num == ref and hand[1].suit == suit)then
								local s = hand.source
								if(s.col==7)then
									hold[s.id] = nil
								else
									table.remove(board[s.col], s.id)
								end
								stack[c]=hand[1]
							end
						end
					end
				end
			end
		end
		hand = {}
	end
	checkhold()
	checkwin()
end

function love.keypressed(key, scancode, isrepeat)
	if(key=="space")then
		newgame()
	end
end
