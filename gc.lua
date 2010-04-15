print('testing garbage collection')

collectgarbage()

assert(collectgarbage("isrunning"))


-- test weird parameters
do
  -- save original parameters
  local a = collectgarbage("setpause", 200)
  local b = collectgarbage("setstepmul", 200)
  local t = {0, 2, 10, 90, 100, 500, 5000, 30000}
  for i = 1, #t do
    local p = t[i]
    for j = 1, #t do
      local m = t[j]
      collectgarbage("setpause", p)
      collectgarbage("setstepmul", m)
      collectgarbage("step", 0)
      collectgarbage("step", 10000)
    end
  end
  -- restore original parameters
  collectgarbage("setpause", a)
  collectgarbage("setstepmul", b)
end


_G["while"] = 234

limit = 5000


local function GC1 ()
  local u = newproxy(true)
  local finish = false
  getmetatable(u).__gc = function () finish = true end
  u = nil
  repeat local a = {} until finish
end

local function GC()  GC1(); GC1() end


contCreate = 0

print('tables')
while contCreate <= limit do
  local a = {}; a = nil
  contCreate = contCreate+1
end

a = "a"

contCreate = 0
print('strings')
while contCreate <= limit do
  a = contCreate .. "b";
  a = string.gsub(a, '(%d%d*)', string.upper)
  a = "a"
  contCreate = contCreate+1
end


contCreate = 0

a = {}

print('functions')
function a:test ()
  while contCreate <= limit do
    loadstring(string.format("function temp(a) return 'a%d' end", contCreate))()
    assert(temp() == string.format('a%d', contCreate))
    contCreate = contCreate+1
  end
end

a:test()

-- collection of functions without locals, globals, etc.
do local f = function () end end


print("functions with errors")
prog = [[
do
  a = 10;
  function foo(x,y)
    a = sin(a+0.456-0.23e-12);
    return function (z) return sin(%x+z) end
  end
  local x = function (w) a=a+w; end
end
]]
do
  local step = 1
  if rawget(_G, "_soft") then step = 13 end
  for i=1, string.len(prog), step do
    for j=i, string.len(prog), step do
      pcall(loadstring(string.sub(prog, i, j)))
    end
  end
end

print('long strings')
x = "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
assert(string.len(x)==80)
s = ''
n = 0
k = 300
while n < k do s = s..x; n=n+1; j=tostring(n)  end
assert(string.len(s) == k*80)
s = string.sub(s, 1, 20000)
s, i = string.gsub(s, '(%d%d%d%d)', math.sin)
assert(i==20000/4)
s = nil
x = nil

assert(_G["while"] == 234)

local k,b = collectgarbage("count")
assert(k*1024 == math.floor(k)*1024 + b)


local bytes = gcinfo()
while 1 do
  local nbytes = gcinfo()
  if nbytes < bytes then break end   -- run until gc
  bytes = nbytes
  a = {}
end


local function dosteps (siz)
  collectgarbage()
  collectgarbage"stop"
  assert(not collectgarbage("isrunning"))
  local a = {}
  for i=1,100 do a[i] = {{}}; local b = {} end
  local x = gcinfo()
  local i = 0
  repeat
    i = i+1
  until collectgarbage("step", siz)
  assert(gcinfo() < x)
  return i
end

assert(dosteps(0) > 10)
assert(dosteps(6) < dosteps(2))
assert(dosteps(10000) == 1)
assert(collectgarbage("step", 1000000) == true)
assert(collectgarbage("step", 1000000))
assert(not collectgarbage("isrunning"))


do
  local x = gcinfo()
  collectgarbage()
  collectgarbage"stop"
  assert(not collectgarbage("isrunning"))
  repeat
    local a = {}
  until gcinfo() > 1000
  collectgarbage"restart"
  assert(collectgarbage("isrunning"))
  repeat
    local a = {}
  until gcinfo() < 1000
end

lim = 15
a = {}
-- fill a with `collectable' indices
for i=1,lim do a[{}] = i end
b = {}
for k,v in pairs(a) do b[k]=v end
-- remove all indices and collect them
for n in pairs(b) do
  a[n] = nil
  assert(type(n) == 'table' and next(n) == nil)
  collectgarbage()
end
b = nil
collectgarbage()
for n in pairs(a) do error'cannot be here' end
for i=1,lim do a[i] = i end
for i=1,lim do assert(a[i] == i) end


print('weak tables')
a = {}; setmetatable(a, {__mode = 'k'});
-- fill a with some `collectable' indices
for i=1,lim do a[{}] = i end
-- and some non-collectable ones
for i=1,lim do a[i] = i end
for i=1,lim do local s=string.rep('@', i); a[s] = s..'#' end
collectgarbage()
local i = 0
for k,v in pairs(a) do assert(k==v or k..'#'==v); i=i+1 end
assert(i == 2*lim)

a = {}; setmetatable(a, {__mode = 'v'});
a[1] = string.rep('b', 21)
collectgarbage()
assert(a[1])   -- strings are *values*
a[1] = nil
-- fill a with some `collectable' values (in both parts of the table)
for i=1,lim do a[i] = {} end
for i=1,lim do a[i..'x'] = {} end
-- and some non-collectable ones
for i=1,lim do local t={}; a[t]=t end
for i=1,lim do a[i+lim]=i..'x' end
collectgarbage()
local i = 0
for k,v in pairs(a) do assert(k==v or k-lim..'x' == v); i=i+1 end
assert(i == 2*lim)

a = {}; setmetatable(a, {__mode = 'vk'});
local x, y, z = {}, {}, {}
-- keep only some items
a[1], a[2], a[3] = x, y, z
a[string.rep('$', 11)] = string.rep('$', 11)
-- fill a with some `collectable' values
for i=4,lim do a[i] = {} end
for i=1,lim do a[{}] = i end
for i=1,lim do local t={}; a[t]=t end
collectgarbage()
assert(next(a) ~= nil)
local i = 0
for k,v in pairs(a) do
  assert((k == 1 and v == x) or
         (k == 2 and v == y) or
         (k == 3 and v == z) or k==v);
  i = i+1
end
assert(i == 4)
x,y,z=nil
collectgarbage()
assert(next(a) == string.rep('$', 11))


-- ephemerons
local mt = {__mode = 'k'}
a = {}; setmetatable(a, mt)
x = nil
for i = 1, 100 do local n = {}; a[n] = {k = {x}}; x = n end
GC()
local n = x
local i = 0
while n do n = a[n].k[1]; i = i + 1 end
assert(i == 100)
x = nil
GC()
assert(next(a) == nil)

local K = {}
a[K] = {}
for i=1,10 do a[K][i] = {}; a[a[K][i]] = setmetatable({}, mt) end
x = nil
local k = 1
for j = 1,100 do
  local n = {}; local nk = k%10 + 1
  a[a[K][nk]][n] = {x, k = k}; x = n; k = nk
end
GC()
local n = x
local i = 0
while n do local t = a[a[K][k]][n]; n = t[1]; k = t.k; i = i + 1 end
assert(i == 100)
K = nil
GC()
assert(next(a) == nil)


-- testing errors during GC
do
collectgarbage("stop")   -- stop collection
local u = newproxy(true)
local s = {}; setmetatable(s, {__mode = 'k'})
getmetatable(u).__gc = function (o)
  local i = s[o]
  s[i] = true
  assert(not s[i - 1])   -- check proper finalization order
  if i == 8 then error("here") end   -- error during GC
end

for i = 6, 10 do local n = newproxy(u); s[n] = i end

assert(not pcall(collectgarbage))
for i = 8, 10 do assert(s[i]) end

for i = 1, 5 do local n = newproxy(u); s[n] = i end

collectgarbage()
for i = 1, 10 do assert(s[i]) end

getmetatable(u).__gc = false

end
print '+'


-- testing userdata
collectgarbage("stop")   -- stop collection
local u = newproxy(true)
local s = 0
local a = {[u] = 0}; setmetatable(a, {__mode = 'vk'})
for i=1,10 do a[newproxy(u)] = i end
for k in pairs(a) do assert(getmetatable(k) == getmetatable(u)) end
local a1 = {}; for k,v in pairs(a) do a1[k] = v end
for k,v in pairs(a1) do a[v] = k end
for i =1,10 do assert(a[i]) end
getmetatable(u).a = a1
getmetatable(u).u = u
do
  local u = u
  getmetatable(u).__gc = function (o)
    assert(a[o] == 10-s)
    assert(a[10-s] == nil) -- udata already removed from weak table
    assert(getmetatable(o) == getmetatable(u))
    assert(getmetatable(o).a[o] == 10-s)
    s=s+1
  end
end
a1, u = nil
assert(next(a) ~= nil)
collectgarbage()
assert(s==11)
collectgarbage()
assert(next(a) == nil)  -- finalized keys are removed in two cycles


-- __gc x weak tables
local u = newproxy(true)
setmetatable(getmetatable(u), {__mode = "v"})
getmetatable(u).__gc = function (o) os.exit(1) end  -- cannot happen
collectgarbage()

local u = newproxy(true)
local m = getmetatable(u)
m.x = {[{0}] = 1; [0] = {1}}; setmetatable(m.x, {__mode = "kv"});
m.__gc = function (o)
  assert(next(getmetatable(o).x) == nil)
  m = 10
end
u, m = nil
collectgarbage()
assert(m==10)


-- errors during collection
u = newproxy(true)
getmetatable(u).__gc = function () error "!!!" end
u = nil
assert(not pcall(collectgarbage))


if not rawget(_G, "_soft") then
  print("deep structures")
  local a = {}
  for i = 1,200000 do
    a = {next = a}
  end
  collectgarbage()
end

-- create many threads with self-references and open upvalues
local thread_id = 0
local threads = {}

function fn(thread)
    local x = {}
    threads[thread_id] = function()
                             thread = x
                         end
    coroutine.yield()
end

while thread_id < 1000 do
    local thread = coroutine.create(fn)
    coroutine.resume(thread, thread)
    thread_id = thread_id + 1
end

do
  local x = gcinfo()
  collectgarbage()
  collectgarbage"stop"
  repeat
    for i=1,100 do local a = {} end
    collectgarbage("step", 1)   -- steps should not unblock the collector
  until gcinfo() > 1000
  collectgarbage"restart"
end


if T then
  print("emergency collections")
  collectgarbage()
  collectgarbage()
  T.totalmem(T.totalmem() + 200)
  for i=1,200 do local a = {} end
  T.totalmem(1000000000)
  collectgarbage()
  local t = T.totalmem("table")
  local a = {{}, {}, {}}   -- create 4 new tables
  assert(T.totalmem("table") == t + 4)
  t = T.totalmem("function")
  a = function () end   -- create 1 new closure
  assert(T.totalmem("function") == t + 1)
  t = T.totalmem("thread")
  a = coroutine.create(function () end)   -- create 1 new coroutine
  assert(T.totalmem("thread") == t + 1)
end

-- create a userdata to be collected when state is closed
do
  local newproxy,assert,type,print,getmetatable =
        newproxy,assert,type,print,getmetatable
  local u = newproxy(true)
  local tt = getmetatable(u)
  ___Glob = {u}   -- avoid udata being collected before program end
  tt.__gc = function (o)
    assert(getmetatable(o) == tt)
    -- create new objects during GC
    local a = 'xuxu'..(10+3)..'joao', {}
    ___Glob = o  -- ressurect object!
    newproxy(o)  -- creates a new one with same metatable
    print(">>> closing state " .. "<<<\n")
  end
end

-- create several udata to raise errors when collected while closing state
do
  local u = newproxy(true)
  getmetatable(u).__gc = function (o) return o + 1 end
  table.insert(___Glob, u)  -- preserve udata until the end
  for i = 1,10 do table.insert(___Glob, newproxy(u)) end
end

print('OK')
