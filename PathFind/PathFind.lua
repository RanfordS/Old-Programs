--[[ Path Find ]]

require("PathFind_Print")
require("PathFind_Tools")

--4,7,9,10,11,26,29,45
math.randomseed(arg[1])

Weight_Max=0

GenMap(32,0.5,.25) --0.25

--[[ tmp
for r=1,MapSize do
    for c=1,MapSize do
        Weight_Max = math.max(Weight_Max,Map[r][c].w)
    end
end
--]]

io.write ("\27[?1049h")
PrintMap()

while true do
    local r=math.random(32)
    local c=math.random(32)
    if Map[r][c].name ~= "Terrain" then
        f={r,c}
        break
    end
end
while true do
    local r=math.random(32)
    local c=math.random(32)
    if Map[r][c].name ~= "Terrain" then
        t={r,c}
        break
    end
end


--[[    Map[r][c]={name, w, h, e, p}

    name    = tile name
    w       = path weight
    h       = hueristic
    e       = evaulated
    p       = previous
--]]

H_Gen()

List = {}

Map[f[1]][f[2]].w = 0
H_Add(f[1],f[2],0)

timer=os.clock()

while true do

    local sleep=os.clock()+0.05
    PrintMap()

    local e = true
    local r = 0
    local c = 0

    while e do  --  find the first entry in the list that hasn't already been evaulated, remove those that have
        if not List[1] then
            io.write ("\nNo path\n")
            while os.clock() < sleep + 2 do end
            io.write ("\27[?1049l")
        end
        r = List[1][1]
        c = List[1][2]
        table.remove(List,1)
        e = Map[r][c].e
--      io.write("Leading: (",r,", ",c,")\n")
    end

    local w = Map[r][c].w
--  io.write("Weight: ",w,"\n")

    Weight_Max = math.max(w,Weight_Max)
--  io.write("Largest weight: ",w,"\n")

    if r==t[1] and c==t[2] then
        break
    end

--  io.write("Exit loop\n")

    Map[r][c].e = true

    Nr = math.max(1,r-1)
    Ec = math.min(MapSize,c+1)
    Sr = math.min(MapSize,r+1)
    Wc = math.max(1,c-1)

    --[[
    io.write("Nr: ",Nr,"\n")
    io.write("Sr: ",Sr,"\n")
    io.write("Wc: ",Wc,"\n")
    io.write("Ec: ",Ec,"\n")
    --]]

    for rr=Nr,Sr do
        for rc=Wc,Ec do
            local nw = w + math.sqrt((r-rr)^2 + (c-rc)^2)
            if not (Map[rr][rc].e or Map[rr][rc].name == "Terrain") then

                if Map[rr][rc].w == nil then
                    Map[rr][rc].w = nw
                    Map[rr][rc].p = {r,c}

                    local h = nw + Map[rr][rc].h
                    H_Add(rr,rc,h)

                elseif Map[rr][rc].w > nw then
                    Map[rr][rc].w = nw
                    Map[rr][rc].p = {r,c}
                end
            end
        end
    end

    if pr then
        Map[pr][pc].active = nil
    end
    pr=r
    pc=c
    Map[r][c].active = true

    while os.clock() < sleep do end

end

timer=os.clock()-timer

--io.read()
r=t[1]
c=t[2]
while true do
    Map[r][c].name = "Route"
    if r==f[1] and c==f[2] then break end
    local p=Map[r][c].p
    r=p[1]
    c=p[2]
end

PrintMap()
io.write("\nEnd Path\n")
io.write("Compeleted in ",timer,"s\n")

local sleep=os.clock() + 2
while os.clock() < sleep do end
io.write ("\27[?1049l")
