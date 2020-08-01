--[[ Path Find Print and Map ]]

function GenMap(size,t,p)
	local veronoi = {}
	
	for i=1,size do
		local r = math.random()*size
		local c = math.random()*size
		local v = math.random()<t
		table.insert(veronoi,{r,c,v})
	end
	
	Map = {}
	
	for r=1,size do
		Map[r] = {}
		for c=1,size do
			Map[r][c]={}
			local v = true
			local dist = 1/0
			for i=1,size do
				local test = math.abs(r - veronoi[i][1])^p + math.abs(c - veronoi[i][2])^p
				if test<dist then
					v = veronoi[i][3]
					dist = test
--					Map[r][c].w = dist		--	Just looks cool
				end
			end
			Map[r][c].e = false
			if v then
				Map[r][c].name = "Terrain"
			else
				Map[r][c].name = "Empty"
			end
		end
	end
	
	MapSize=size
end

function PrintMap()
	local str="\27[1;1H┌"
	for i=1,MapSize do
		str=str.."─"
	end
	str=str.."┐\n"
	
	for r=1,MapSize do
		str=str.."│"
		for c=1,MapSize do
			local ref = Map[r][c]
			if ref.name == "Terrain" then
				str=str.."\27[31m█\27[0m"
			elseif ref.name == "Route" then
				str=str.."\27[1;32m█\27[0m"
			else
                if ref.active then
                    str=str.."\27[1;32m█\27[0m"
                elseif ref.w~=nil then
					local rw = ref.w / Weight_Max
					if rw>0.75 		then	str=str.."█"
					elseif rw>0.5 	then	str=str.."▓"
					elseif rw>0.25	then	str=str.."▒"
					else					str=str.."░" end
				else
					str=str.." "
				end
			end
		end
		str=str.."│\n"
	end
	
	str=str.."└"
	for i=1,MapSize do
		if i%4 == 0 then
			str=str.."┴"
		else
			str=str.."─"
		end
	end
	str=str.."┘\n"
	
	io.write(str)
end
