#!/usr/bin/env lua
local params = {...}
local cores = tonumber(io.popen('cat /proc/cpuinfo | grep processor | wc -l'):read('*all'))
local color = {
  black = {30,40},
  red = {31,41},
  green = {32,42},
  yellow = {33,43},
  blue = {34,44},
  magenta = {35,45},
  cyan = {36,46},
  white = {37,47}
}
function sleep(n)
  os.execute("sleep "..(n))
end
function percentage(Value, All)
local Count = (Value / All) * 100
local Percent = string.format("%.1f", Count)..'%';
if Count == 100 then
result = "[||||||||||||||||||||] ("..Percent..")"
elseif Count >= 95 then
result = "[||||||||||||||||||| ] ("..Percent..")"
elseif Count >= 90 then
result = "[||||||||||||||||||  ] ("..Percent..")"
elseif Count >= 85 then
result = "[|||||||||||||||||   ] ("..Percent..")"
elseif Count >= 80 then
result = "[||||||||||||||||    ] ("..Percent..")"
elseif Count >= 75 then
result = "[|||||||||||||||     ] ("..Percent..")"
elseif Count >= 70 then
result = "[||||||||||||||      ] ("..Percent..")"
elseif Count >= 65 then
result = "[|||||||||||||       ] ("..Percent..")"
elseif Count >= 60 then
result = "[||||||||||||        ] ("..Percent..")"
elseif Count >= 55 then
result = "[|||||||||||         ] ("..Percent..")"
elseif Count >= 50 then
result = "[||||||||||          ] ("..Percent..")"
elseif Count >= 45 then
result = "[|||||||||           ] ("..Percent..")"
elseif Count >= 40 then
result = "[||||||||            ] ("..Percent..")"
elseif Count >= 35 then
result = "[|||||||             ] ("..Percent..")"
elseif Count >= 30 then
result = "[||||||              ] ("..Percent..")"
elseif Count >= 25 then
result = "[|||||               ] ("..Percent..")"
elseif Count >= 20 then
result = "[||||                ] ("..Percent..")"
elseif Count >= 15 then
result = "[|||                 ] ("..Percent..")"
elseif Count >= 10 then
result = "[||                  ] ("..Percent..")"
elseif Count >= 5 then
result = "[|                   ] ("..Percent..")"
elseif Count >= 0 then
result = "[                    ] ("..Percent..")"
end
return result
end
local n, v = "serpent", 0.28
local c, d = "Paul Kulchenko", "Lua serializer and pretty printer"
local snum = {[tostring(1/0)]='1/0 --[[math.huge]]',[tostring(-1/0)]='-1/0 --[[-math.huge]]',[tostring(0/0)]='0/0'}
local badtype = {thread = true, userdata = true, cdata = true}
local keyword, globals, G = {}, {}, (_G or _ENV)
for _,k in ipairs({'and', 'break', 'do', 'else', 'elseif', 'end', 'false',
  'for', 'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
  'return', 'then', 'true', 'until', 'while'}) do keyword[k] = true end
for k,v in pairs(G) do globals[v] = k end 
for _,g in ipairs({'coroutine', 'debug', 'io', 'math', 'string', 'table', 'os'}) do
  for k,v in pairs(G[g] or {}) do globals[v] = g..'.'..k end end
local function s(t, opts)
  local name, indent, fatal, maxnum = opts.name, opts.indent, opts.fatal, opts.maxnum
  local sparse, custom, huge = opts.sparse, opts.custom, not opts.nohuge
  local space, maxl = (opts.compact and '' or ' '), (opts.maxlevel or math.huge)
  local iname, comm = '_'..(name or ''), opts.comment and (tonumber(opts.comment) or math.huge)
  local seen, sref, syms, symn = {}, {'local '..iname..'={}'}, {}, 0
  local function gensym(val) return '_'..(tostring(tostring(val)):gsub("[^%w]",""):gsub("(%d%w+)",
    function(s) if not syms[s] then symn = symn+1; syms[s] = symn end return tostring(syms[s]) end)) end
  local function safestr(s) return type(s) == "number" and tostring(huge and snum[tostring(s)] or s)
    or type(s) ~= "string" and tostring(s)
    or ("%q"):format(s):gsub("\010","n"):gsub("\026","\\026") end
  local function comment(s,l) return comm and (l or 0) < comm and ' --[['..tostring(s)..']]' or '' end
  local function globerr(s,l) return globals[s] and globals[s]..comment(s,l) or not fatal
    and safestr(select(2, pcall(tostring, s))) or error("Can't serialize "..tostring(s)) end
  local function safename(path, name)
    local n = name == nil and '' or name
    local plain = type(n) == "string" and n:match("^[%l%u_][%w_]*$") and not keyword[n]
    local safe = plain and n or '['..safestr(n)..']'
    return (path or '')..(plain and path and '.' or '')..safe, safe end
  local alphanumsort = type(opts.sortkeys) == 'function' and opts.sortkeys or function(k, o, n)
    local maxn, to = tonumber(n) or 12, {number = 'a', string = 'b'}
    local function padnum(d) return ("%0"..tostring(maxn).."d"):format(tonumber(d)) end
    table.sort(k, function(a,b)
      return (k[a] ~= nil and 0 or to[type(a)] or 'z')..(tostring(a):gsub("%d+",padnum))
           < (k[b] ~= nil and 0 or to[type(b)] or 'z')..(tostring(b):gsub("%d+",padnum)) end) end
  local function val2str(t, name, indent, insref, path, plainindex, level)
    local ttype, level, mt = type(t), (level or 0), getmetatable(t)
    local spath, sname = safename(path, name)
    local tag = plainindex and
      ((type(name) == "number") and '' or name..space..'='..space) or
      (name ~= nil and sname..space..'='..space or '')
    if seen[t] then
      sref[#sref+1] = spath..space..'='..space..seen[t]
      return tag..'nil'..comment('ref', level) end
    if type(mt) == 'table' and (mt.__serialize or mt.__tostring) then 
      seen[t] = insref or spath
      if mt.__serialize then t = mt.__serialize(t) else t = tostring(t) end
      ttype = type(t) end 
    if ttype == "table" then
      if level >= maxl then return tag..'{}'..comment('max', level) end
      seen[t] = insref or spath
      if next(t) == nil then return tag..'{}'..comment(t, level) end
      local maxn, o, out = math.min(#t, maxnum or #t), {}, {}
      for key = 1, maxn do o[key] = key end
      if not maxnum or #o < maxnum then
        local n = #o
        for key in pairs(t) do if o[key] ~= key then n = n + 1; o[n] = key end end end
      if maxnum and #o > maxnum then o[maxnum+1] = nil end
      if opts.sortkeys and #o > maxn then alphanumsort(o, t, opts.sortkeys) end
      local sparse = sparse and #o > maxn 
      for n, key in ipairs(o) do
        local value, ktype, plainindex = t[key], type(key), n <= maxn and not sparse
        if opts.valignore and opts.valignore[value]
        or opts.keyallow and not opts.keyallow[key]
        or opts.valtypeignore and opts.valtypeignore[type(value)] 
        or sparse and value == nil then 
        elseif ktype == 'table' or ktype == 'function' or badtype[ktype] then
          if not seen[key] and not globals[key] then
            sref[#sref+1] = 'placeholder'
            local sname = safename(iname, gensym(key))
            sref[#sref] = val2str(key,sname,indent,sname,iname,true) end
          sref[#sref+1] = 'placeholder'
          local path = seen[t]..'['..tostring(seen[key] or globals[key] or gensym(key))..']'
          sref[#sref] = path..space..'='..space..tostring(seen[value] or val2str(value,nil,indent,path))
        else
          out[#out+1] = val2str(value,key,indent,insref,seen[t],plainindex,level+1)
        end
      end
      local prefix = string.rep(indent or '', level)
      local head = indent and '{\n'..prefix..indent or '{'
      local body = table.concat(out, ','..(indent and '\n'..prefix..indent or space))
      local tail = indent and "\n"..prefix..'}' or '}'
      return (custom and custom(tag,head,body,tail) or tag..head..body..tail)..comment(t, level)
    elseif badtype[ttype] then
      seen[t] = insref or spath
      return tag..globerr(t, level)
    elseif ttype == 'function' then
      seen[t] = insref or spath
      local ok, res = pcall(string.dump, t)
      local func = ok and ((opts.nocode and "function() --[[..skipped..]] end" or
        "((loadstring or load)("..safestr(res)..",'@serialized'))")..comment(t, level))
      return tag..(func or globerr(t, level))
    else return tag..safestr(t) end
  end
  local sepr = indent and "\n" or ";"..space
  local body = val2str(t, name, indent)
  local tail = #sref>1 and table.concat(sref, sepr)..sepr or ''
  local warn = opts.comment and #sref>1 and space.."--[[incomplete output with shared/self-references skipped]]" or ''
  return not name and body..warn or "do local "..body..sepr..tail.."return "..name..sepr.."end"
end
local function deserialize(data, opts)
  local env = (opts and opts.safe == false) and G
    or setmetatable({}, {
        __index = function(t,k) return t end,
        __call = function(t,...) error("cannot call functions") end
      })
  local f, res = (loadstring or load)('return '..data, nil, nil, env)
  if not f then f, res = (loadstring or load)(data, nil, nil, env) end
  if not f then return f, res end
  if setfenv then setfenv(f, env) end
  return pcall(f)
end
local function merge(a, b) if b then for k,v in pairs(b) do a[k] = v end end; return a; end
local serpent = { _NAME = n, _COPYRIGHT = c, _DESCRIPTION = d, _VERSION = v, serialize = s,
  load = deserialize,
  dump = function(a, opts) return s(a, merge({name = '_', compact = true, sparse = true}, opts)) end,
  line = function(a, opts) return s(a, merge({sortkeys = true, comment = true}, opts)) end,
  block = function(a, opts) return s(a, merge({indent = '  ', sortkeys = true, comment = true}, opts)) end }
  
  function Decode(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
    if (x == '=') then return '' end
    local r,f='',(b:find(x)-1)
    for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
    return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if (#x ~= 8) then return '' end
    local c=0
    for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
    return string.char(c)
    end))
  end
  function Encode(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
    local r,b='',x:byte()
    for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
    return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if (#x < 6) then return '' end
    local c=0
    for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
    return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
  end
function SerializeToFile(data, file, uglify)
  file = io.open(file, 'w+')
  local serialized
  if not uglify then
    serialized = serpent.block(data, {
      comment = false,
      name = '_'
    })
  else
    serialized = serpent.dump(data)
  end
  file:write(serialized)
  file:close()
end
if type(params[1]) == 'nil' then
  local data = {}
  for i=1 , cores do
    os.execute("sudo tmux new-session -d -s SpeedTestLua-"..i.." 'lua ./testspeed.lua "..i.."'")
  end
  SerializeToFile(data, './.SpeedTest.lua')
  print("\027["..color.green[1]..";"..color.black[2].."m> The Operation Started, Please Wait...\027[00m")
  print("\027["..color.yellow[1]..";"..color.black[2].."mNote : This Operation Takes 30 seconds.\027[00m")
  local i = 0
  local run = true
  while run do 
   os.execute('clear')
   print("\027["..color.green[1]..";"..color.black[2].."m> The Operation Started, Please Wait...\027[00m")
   print("\027["..color.yellow[1]..";"..color.black[2].."mNote : This Operation Takes 30 seconds.\027[00m")
   print("\027["..color.yellow[1]..";"..color.black[2].."m"..percentage(i, 33).."\027[00m")
   i = i + 1
   sleep(1)
   if i == 34 then break end
  end
  local data = loadfile ("./.SpeedTest.lua")()
  local proces = 0
  if data then
    for k,v in pairs(data) do
      proces = proces + tonumber(v)
    end
  end
  if proces == 0 then
    print("\027["..color.red[1]..";"..color.black[2].."m> Error : Operation Failed !\027[00m")
  elseif proces >= 900 then
    print("\027["..color.green[1]..";"..color.black[2].."m> Excellent : Level 10 | Score : "..proces.."\027[00m")
  elseif proces >= 800 then
    print("\027["..color.green[1]..";"..color.black[2].."m> Very Good : Level 9 | Score : "..proces.."\027[00m")
  elseif proces >= 700 then
    print("\027["..color.green[1]..";"..color.black[2].."m> Good : Level 8 | Score : "..proces.."\027[00m")
  elseif proces >= 600 then
    print("\027["..color.yellow[1]..";"..color.black[2].."m> Normal : Level 7 | Score : "..proces.."\027[00m")
  elseif proces >= 500 then
    print("\027["..color.yellow[1]..";"..color.black[2].."m> Almost Medium : Level 6 | Score : "..proces.."\027[00m")
  elseif proces >= 400 then
    print("\027["..color.yellow[1]..";"..color.black[2].."m> Not Bad : Level 5 | Score : "..proces.."\027[00m")
  elseif proces >= 300 then
    print("\027["..color.magenta[1]..";"..color.black[2].."m> Almost Weak : Level 4 | Score : "..proces.."\027[00m")
  elseif proces >= 200 then
    print("\027["..color.red[1]..";"..color.black[2].."m> Weak : Level 3 | Score : "..proces.."\027[00m")
  elseif proces >= 100 then
    print("\027["..color.red[1]..";"..color.black[2].."m> Very Weak : Level 2 | Score : "..proces.."\027[00m")
  elseif proces >= 50 then
    print("\027["..color.red[1]..";"..color.black[2].."m> Very Slow : Level 1 | Score : "..proces.."\027[00m")
  elseif proces < 50 then
    print("\027["..color.red[1]..";"..color.black[2].."m> Very Bad : Level 0 | Score : "..proces.."\027[00m")
  else
    print("\027["..color.red[1]..";"..color.black[2].."m> Error : Unforeseen | Score : "..proces.."\027[00m")
  end
  os.execute("rm -rf ./.SpeedTest.lua")
elseif params[1] and params[1]:match('^(%d+)$') then
  local StopTime = os.time() + 30
  local i = 1
  while StopTime > os.time() do
    local Para = "VlOCXytw02cDB3NkoWz8MaR6W2YXkn6pP84Xpwopo1TS4lbOSWo2tB4vQBftde95FYDKtoT0BmYeaJcEHySmnfF0vx79xS3XrAg0onvbOXqRXaQpXM79nkHENiF2U0C2kAPvZVDx0rJ7gSMEqrksoBUECv1up0PpL68VDSOdLdoW9JgjYPqWC53bQYcHs2xQ9S6nHNv1IemCUOdWX6N3qD3NlyVUrQcuf7ua4UpFDE6TYPoYNumNjzvDLgrWhpuy"
	local FinalPara = ''
	for i = 1 , 60 do
	FinalPara = FinalPara..Para
	end
	local A = Encode(FinalPara)
	local B = Decode(A)
	i = i + 1
  end
  local data = loadfile ("./.SpeedTest.lua")()
  if data then
    data[params[1]] = i
    SerializeToFile(data, './.SpeedTest.lua')
  end
end
-- Copyright (C) 2018 ESET, Sajjad Momen.
