--[[ Path Find Tools ]]

function H_Gen()
	
	for r=1,MapSize do
		for c=1,MapSize do
			
			Map[r][c].h = math.sqrt((r-t[1])^2 + (c-t[2])^2)
--			Map[r][c].h = 0.5*( math.abs(r-t[1]) + math.abs(c-t[2]) )
			
		end
	end
	
end

function H_Add(r,c,h)
	
	local element = {r,c,h}
	local length  = #List
	local i=1
	
	while i <= length do
		if List[i][3] >= h then
			break
		else
			i=i+1
		end
	end
	
	table.insert(List,i,element)
	
--	io.write("Added: (",r,", ",c,") ~ ",h," at position: ",i,"\n")
	
end
