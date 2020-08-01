
--local BACKUP_AND_ERASE = "[F[K"
--local BACKUP_AND_ERASE = "[F[40G"
local BACKUP_AND_ERASE = ""

local Breakpoints = {}
local StackLevel			-- Current stack level for inspection

function dbgEscape (s)
	return ("%q"):format (s)
end

function dbgSaveState (mode)
	local f = io.open ("dbg-state-"..mode..".txt", "w")
	
	f:write ("--V0.0.0\n")
	f:write ("return{bp={")
	for k,_ in pairs (Breakpoints) do
		f:write (("[%q]=true,"):format (k))
	end
	f:write ("}}")
	f:close ()
end

function dbgLoadState (mode)
	
	f,e = loadfile ("dbg-state-"..mode..".txt")
	if f == nil then
		io.write ("Failed to load dbg-state-"..mode..".txt, invalid file:\n", e, "\n")
	else
		e,f = pcall (f)
		if e then	
			Breakpoints = f.bp
		else
			io.write ("Failed to load dbg-state-"..mode..".txt, invalid file:\n", e, "\n")
		end
	end
end

function dbgPrintBreakpoints ()
	local l = {}
	for k,_ in pairs (Breakpoints) do
		table.insert (l, k)
	end
	if #l == 0 then
		io.write ("no breakpoints\n")
	else
		local s
		if #l == 1 then s = "" else s = "s" end
		io.write (#l, " breakpoint", s," set:\n", table.concat (l, ", "), "\n")
	end
end

DebugCommand = ""

function dbgConfigureDebugHook (want)
	DebugCommand = want
	
	local mask = dbgComputeBreakpointMode ()
	
	if want == "return" then
		mask = mask .. "r"
	elseif want == "next" then
		mask = mask .. "l"
	elseif want == "continue" then
	else
		error ("unknown request '"..want.."'")
	end
	
	print ("mask = ", mask)
	debug.sethook (dbgHook, mask)
end

-- if call breakpoint -> +call
-- if line breakpoint -> +line
-- if 'n'             -> +line
-- if 'u'             -> +return

function dbgHook (event)

	StackLevel = 2
	local info = debug.getinfo (StackLevel)
	
	print (event)
	
	if event == "call" then
		if Breakpoints[info.name] then
			goto breakpoint_hit
		end
	elseif DebugCommand == "next" then
		goto line_hit
	elseif event == "line" and info.name and info.currentline then
		if Breakpoints[info.name..":"..info.currentline] then
			goto breakpoint_hit
		end
		print ("not breakpoint match continuing")
		return
	
	elseif event == "assert" or event == "error" then
		goto fault_hit	
		
	elseif event == nil then
		goto manual_hit
	else
		return
	end
	print ("unknown")
	
	
::breakpoint_hit::
::manual_hit::
::line_hit::
::fault_hit::
	local vars
	
	if event then
		io.write ("DEBUGER triggered on ", event, "\n")
		vars = Trace ()
	else
		io.write ("DEBUGER manually triggered\n")
	end
	

	
	
	while true do
		
		io.write ("[1;92mcmd: ") io.flush ()
		local cmdline = io.read ("*l")
		local cmd = (cmdline:match ("%s*(%S+)") or ""):lower ()
		
		io.write ("[0m")
		
		if cmd == "h" or cmd == "?" or cmd == "help" then
			io.write ("h           help\n")
			io.write ("c           continue\n")
			io.write ("n           next line\n")
			io.write ("u           until return\n")
			io.write ("r           restart program\n")
			io.write ("b <f>[:l]   break on entering function\n")
			io.write ("rb <f>      remove break point (* for all)\n")
			io.write ("lb <f>      list breakpoints\n")
			io.write ("p $n        print var\n")
			io.write ("t           stack trace\n")
			io.write ("q           quit\n")
			io.write ("d           \"detach\" debugger\n")
			io.write ("mu          walk up stack\n")
			io.write ("md          walk down stack\n")
			io.write ("sc          source code\n")
			io.write ("ss          save state\n")
			io.write ("rs          load state\n")
			
		elseif cmd == "c" then
			dbgConfigureDebugHook ("continue")
			return
			
		elseif cmd == "n" then
			dbgConfigureDebugHook ("next")
			return
	
		elseif cmd == "u" then
			dbgConfigureDebugHook ("return")
			return
			
			
			
			
		elseif cmd == "lb" then
			dbgPrintBreakpoints ()
			
		elseif cmd == "b" then
			local func = cmdline:match ("%s*%S+%s+(%S+)")
			if dbgAddBreakpoint (func) then
				io.write (BACKUP_AND_ERASE, "Breakpoint on ", func, " set\n")
			else
				io.write (BACKUP_AND_ERASE, "Breakpoint on ", func, " alread set\n")
			end
			
		elseif cmd == "rb" then	
			local func = cmdline:match ("%s*%S+%s+(%S+)")
			if dbgRemoveBreakpoint (func) then
				if func == "*" then
					io.write (BACKUP_AND_ERASE, "Removed all breakpoints\n")
				else
					io.write (BACKUP_AND_ERASE, "Removed breakpoint on ", func, "\n")
				end
			else
				if func == "*" then
					io.write (BACKUP_AND_ERASE, "No breakpoints to remove\n")
				else
					io.write (BACKUP_AND_ERASE, "No breakpoint on ", func, "\n")
				end
			end
			
			
		elseif cmd == "sc" then
			local info = debug.getinfo (StackLevel)
			local n = cmdline:match ("%s*%S+%s+(%S+)")
			if n then n = tonumber (n) end
			n = n or 12
			Source (n, info.short_src, info.currentline)
		
		elseif cmd == "d" then
			dbgRemoveBreakpoint ("*")				-- remove all breakpoints
			debug.sethook ()						-- clear hook
			return									-- run
		
		elseif cmd == "p" then
			error "Not done"
			
		elseif cmd == "ss" then
			dbgSaveState ("auto")
		
		elseif cmd == "q" then
			io.write ("debug session terminated\n")
			os.exit ()
		
		elseif cmd == "t" then			
			vars = Trace ()
		else
			io.write ("Unknown command check help\n")
		end
	end
end

function dbgAddBreakpoint (funcName)
	local p = Breakpoints[funcName]
	Breakpoints[funcName] = true
	return not p
end

function dbgRemoveBreakpoint (funcName)
	if funcName == "*" then
		local l = {}
		for k,_ in pairs (Breakpoints) do
			table.insert (l, k)
		end
		if #l == 0 then
			return false
		else
			local s
			if #l == 1 then s = "" else s = "s" end
			io.write (#l, " breakpoint", s," removed:\n", table.concat (l, ", "), "\n")
		end
		Breakpoints = {}
	else
		local p = Breakpoints[funcName]
		if not p then
			return false
		else
			Breakpoints[funcName] = nil
		end
	end
	return true
end

--! Computes wether Lua can "run" freely, stop only on "call"s or must go "line" by line (for from the breakpoint's perspective)
function dbgComputeBreakpointMode ()
	local any = false
	for k,_ in pairs (Breakpoints) do
		any = true
		if k:find (":%d+") then
			return "l"
		end
	end
	if any then
		return "c"
	else
		return ""
	end
end

function TraceLine (t, p)
	io.write (string.format (" %s $%-3u %s %s = %s\n", t, p.id, p.type, p.name, p.value))
end

function iff (c, t, f) if c then return t else return f end end

function ShortType (v)
	local t = type (v)
		if t == "boolean"	then return "bol"
	elseif t == "number"    then if math.type then return iff (math.type (v) == "integer", "int", "flt") else return "flt" end
	elseif t == "string"	then return "str"
	elseif t == "file"		then return "ios"
	elseif t == "table"		then return iff (getmetatable (v) ~= nil, "obj", "tab")
	elseif t == "nil"		then return "nil"
	elseif t == "function"	then return "fun"
	elseif t == "userdata"	then return "usr"
	else
		return "?"
	end
end

function Trace ()
	local vars = {}
	local layer = 3
	
	local info = debug.getinfo (layer)
	
	io.write ("[1;93m", "================================================================\n[0m")
	Source (3, info.short_src, info.currentline)
	io.write ("[1;93m", "================================================================\n")
	io.write ("Kind ID Type Name = Value\n")
	
	repeat
		io.write ("[1;93m", "function '", info.name or "?", "' from ", info.short_src, ":", info.linedefined, "-", info.lastlinedefined, " line ", info.currentline, "[0m", "\n")
		
		-- get upvalues
		for i = 1, info.nups do
			local n, v = debug.getupvalue (info.func, i)			
			local p = {
				id = #vars,
				name = n,
				value = v,
				type = ShortType (v),
				func = info.name,
			}
			vars[#vars+1] = p
			TraceLine ("U", p)
		end
		-- get params
		for i = 1, info.nparams do
			local n, v = debug.getlocal (layer, i)			
			local p = {
				id = #vars,
				name = n,
				value = v,
				type = ShortType (v),
				func = info.name,
			}
			vars[#vars+1] = p
			TraceLine ("A", p)
		end
		-- get locals
		local i = info.nparams + 1
		local n, v = debug.getlocal (layer, i)
		while n ~= nil do
			local p = {
				id = #vars,
				name = n:gsub ("%(for (.)[^%)]+%)", "for:%1"):gsub ("%(%*temporary%)", "?"),
				value = v,
				type = ShortType (v),
				func = info.name,
			}
			vars[#vars+1] = p
			TraceLine ("L", p)
			i = i + 1
			n, v = debug.getlocal (layer, i)
		end
		
		layer = layer + 1
		info = debug.getinfo (layer)
	until info == nil
	
	io.write ("[1;93m", "================================================================", "[0m\n")
	
	return vars
end

local SourceKeywords = {
	"nil", "true", "false", "goto", "if", "else", "elseif", "then", "end", "local", "function", "break", "goto", "for", "in", "and", "or", "not", "return", "while", "do", "repeat", "until"
}
local SourceSemiKeywords = {
	"print", "assert", "error",
	"ipairs", "pairs", "type", "next",
	"tostring", "tonumber",
	"getmetatable", "setmetatable", "rawset", "rawget", "rawlen",
	"__tostring", "__len", "__add", "__sub", "__mul", "__div", "__idiv", "__mod", "__bor", "__band", "__bnot", "__bxor", "__index", "__newindex", "__call",
	
		"table%.insert",
		"table%.remove",
		"table%.sort",
		"table%.pack",
		"table%.unpack",
		"table%.concat",
	"table",
	
		"string%.rep",
		"string%.len",
		"string%.find",
		"string%.match",
		"string%.gmatch",
		"string%.gsub",
		"string%.upper",
		"string%.lower",
		"string%.format",
		":rep",
		":len",
		":find",
		":match",
		":gmatch",
		":gsub",
		":upper",
		":lower",
		":format",
	"string",
	
		"io%.read",
		"io%.write",
		"io%.open",
		"io%.close",
		"io%.flush",
		":read",
		":write",
		":close",
		":flush",
	"io",
		
		"debug%.sethook",
		"debug%.getinfo",
		"debug%.getlocal",
		"debug%.getupvalue",
	"debug",
	
		"math%.pi",
		"math%.min",
		"math%.max",
		"math%.sin",
		"math%.cos",
		"math%.tan",
		"math%.asin",
		"math%.acos",
		"math%.atan",
		"math%.type",
	"math",
	
}

function Source (count, fname, line)
	local f = io.open (fname, r)
	
	if f == nil then
		io.write ("no source code for", fname, ":", line, "\n")
		
	else
	
		local i = 1
		local delimiters = (".,;:<=>@#~+-*/^%{}[]()"):gsub (".", "%%%1")
		
		while i < line - count do
			f:read ("l")
			i = i + 1
		end
		
		while i <= line + count do
			local l = f:read ("l")
			if l == nil then break end
			local l = " "..l.." "
			
			-- 	comment
			-- 	keyword
			-- 	semi keyword
			-- 	number
			-- 	delimiter
			
			-- perform simple pattern matching on numbers and keywords to help readablity
			l = l:gsub ("\t", "    ")
			l = l:gsub ("%-%-.+", "%0")
			
			for _, k in ipairs (SourceSemiKeywords) do
				l = l:gsub (k.."%f[%A]", "%0")
			end
			for _, k in ipairs (SourceKeywords) do
				l = l:gsub ("%f[%a]"..k.."%f[%A]", "%0")
			end
						
			l = l:gsub ("([%s"..delimiters.."])(0x%x+)(%s"..delimiters.."])", "%1%2%3")
			l = l:gsub ("([%s"..delimiters.."])([%d%.]+)([%s"..delimiters.."])", "%1%2%3")
			l = l:gsub ("["..delimiters.."]", "%0")
			l = l:gsub ("%.%.", "%0")			
			
						
			-- filling rules
			-- comment is highest
			l = l:gsub ("%b", function (m) return "[0;32m"..m:gsub ("[]", "").."[0m" end)
			-- keyword
			l = l:gsub ("%b", function (m) return "[1;94m"..m:gsub ("[]", "").."[0m" end)
			-- semi keyword
			l = l:gsub ("%b", function (m) return "[0;95m"..m:gsub ("[]", "").."[0m" end)
			-- number
			l = l:gsub ("%b", function (m) return "[0;96m"..m:gsub ("[]", "").."[0m" end)
			-- delimiter
			l = l:gsub ("%b", function (m) return "[0;33m"..m:gsub ("[]", "").."[0m" end)
			

--			l = l:gsub ("[]", "")
			
			-- print the line with marker for current & line marker
			io.write (string.format ("%s%5u%s\n", iff (i == line, ">", " "), i, l))
			i = i + 1
		end
	end
end


--! Replace the default errors
local _assert = assert
function assert (expr, msg)
	if not expr then
		dbgHook ("assert")
	end
	_assert (expr, msg)
end
local _error = error
function error (msg)
	dbgHook ("error")
	_error (msg)
end


dbgHook ()
--[[
function test1 (v,a)
	local t = v..a
	return t:rep (2)
end
function test2 (y,a)
	for i = 1, y do
		test1 (i,a)
	end
end
function test3 (u,q)
	test2 (u,q.."f")
end


assert (false, "test")
error ("foo")

local a = string.rep (("a"):rep (5), math.min (1, 3))
test3 (2, 6)
--]]