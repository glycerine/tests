print('testando coleta de lixo')

collectgarbage()

setglobal("while", 234)

limit = 5000


contCreate = 0

print('tabelas')
while contCreate <= limit do
  local a = {}; a = nil
  contCreate = contCreate+1
end

a = "a"

contCreate = 0
print('strings')
while contCreate <= limit do
  a = contCreate .. "b";
  a = gsub(a, '(%d%d*)', strupper)
  a = "a"
  contCreate = contCreate+1
end


contCreate = 0

a = {}

print('funcoes')
function a:test ()
  while contCreate <= limit do
    dostring(format("function temp(a) return 'a%d' end", contCreate))
    assert(temp() == format('a%d', contCreate))
    contCreate = contCreate+1
  end
end

a:test()

-- coleta de funcao sem locais, globais, etc.
do local f = function () end end


print("funcoes com erros")
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
  local old = _ERRORMESSAGE
  local a = {msg=nil}
  _ERRORMESSAGE = function (s) %a.msg = s end
  local step = 1
  if _soft then step = 13 end
  for i=1, strlen(prog), step do
    for j=i, strlen(prog), step do
      dostring(strsub(prog, i, j))
    end
  end
  _ERRORMESSAGE = old
end

print('strings longos')
x = "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
assert(strlen(x)==80)
s = ''
n = 0
k = 300
while n < k do s = s..x; n=n+1; j=tostring(n)  end
assert(strlen(s) == k*80)
s = strsub(s, 1, 20000)
s, i = gsub(s, '(%d%d%d%d)', sin)
assert(i==20000/4)
s = nil
x = nil

assert(getglobal("while") == 234)


local bytes = gcinfo()
while 1 do
  local nbytes = gcinfo()
  if nbytes < bytes then break end   -- run until gc
  bytes = nbytes
  a = {}
end

collectgarbage()

do  -- testa collectgarbage com valores
  local a,b = gcinfo()
  collectgarbage(b+10)
  local c,d = gcinfo(); assert(c<=d)
  assert(d == b+10)
  collectgarbage(2^30)
  c,d = gcinfo(); assert(c<=d)
  assert(d == 2^22-1)   -- ULONG_MAX/1K
  collectgarbage(b)     -- restore original value
  c,d = gcinfo(); assert(c<=d)
  assert(d == b)
end

a = {}
-- fill a with `collectable' indices
for i=1,15 do a[{}] = i end
b = {}
for k,v in a do b[k]=v end
-- remove all indices and collect them
for n,_ in b do
  a[n] = nil
  assert(type(n) == 'table' and next(n) == nil)
  collectgarbage()
end
b = nil
collectgarbage()
for n,_ in a do error'cannot be here' end
for i=1,15 do a[i] = i end
for i=1,15 do assert(a[i] == i) end

if not _soft then
  print("deep structures")
  local a = {}
  for i = 1,200000 do
    a = {next = a}
  end
  collectgarbage()
end

print('OK')
