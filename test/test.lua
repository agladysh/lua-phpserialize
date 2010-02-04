-- test.lua: lua-phpserialize module tests
-- This file is a part of lua-phpserialize library.
-- Copyright (c) lua-phpserialize authors (see file `COPYRIGHT` for the license)

local check_phpserialize = function(t, actual, expected)
  if actual ~= expected then
    print("Phpserialize test failed: ".. t ..".\nactual:\n'" .. tostring(actual) .. "'\nexpected:\n'" .. tostring(expected) .. "'\n")
  end
end

local check_phpserialize_match = function(t, actual, expected)
  if not actual:match(expected) then
    error("Phpserialize test_match failed: ".. t ..".\nactual:\n'" .. tostring(actual) .. "'\nexpected:\n'" .. tostring(expected) .. "'\n")
  end
end

local phpserialize = require "phpserialize"

-- Test that default array offset is 1
local test_serialize = function() 
  do
    local luatable = { "one" }
    local phpsrl = phpserialize.phpserialize(luatable);
    local expected = [=[a:1:{i:1;s:3:"one";}]=]
    check_phpserialize("step1",phpsrl,expected)
  end

  do
    local luatable = {}
    luatable['int1'] = 10
    luatable['int2'] = -10
    luatable['bool1'] = true
    luatable['bool2'] = false
    luatable['nil1'] = nil

    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = [=[a:4:{s:4:"int2";i:-10;s:4:"int1";i:10;s:5:"bool2";b:0;s:5:"bool1";b:1;}]=]
    check_phpserialize("step2",phpsrl,expected)
  end
  
  do
    local luatable = {}
    luatable['float3'] = 10.00000000000001
    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = [=[a:1:%{s:6:"float3";d:10%.00000000000001.-;%}]=]
    check_phpserialize_match("step2-1",phpsrl,expected)
  end

  do
    local luatable={}
    local phpsrl = phpserialize.phpserialize(luatable,3);
    local expected = [=[a:0:{}]=]
    check_phpserialize("step3",phpsrl,expected)
  end

  do
    local luatable = {}
    luatable[#luatable+1] = 1
    luatable[#luatable+1] = {}
    local phpsrl = phpserialize.phpserialize(luatable,0);
    local expected = [=[a:2:{i:0;i:1;i:1;a:0:{}}]=]
    check_phpserialize("step4",phpsrl,expected)
  end

  do
    local luatable = {}
    luatable["asd"] = 0/0
    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = nil
    check_phpserialize("step5",phpsrl,expected)
  end

  do
    local luatable={}
    luatable[#luatable+1] = "asdasd"
    luatable[#luatable+1] = 100
    luatable[#luatable+1] = -123
    local phpsrl = phpserialize.phpserialize(luatable,3);
    local expected = [=[a:3:{i:3;s:6:"asdasd";i:4;i:100;i:5;i:-123;}]=]
    check_phpserialize("step6",phpsrl,expected)
  end

  do
    local luatable = {asdasd=1,dfb="2",qweqwe=-5;}
    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = [=[a:3:{s:6:"qweqwe";i:-5;s:3:"dfb";s:1:"2";s:6:"asdasd";i:1;}]=]
    check_phpserialize("step7",phpsrl,expected)
  end

  do
    local luatable = {}
    luatable[ [=[aa"aa]=] ] = "aaa"
    luatable[ [=[bb\'bb]=] ] = "bbb"
    luatable[ [=[cc'cc]=] ] = "ccc"
    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = [=[a:3:{s:5:"aa"aa";s:3:"aaa";s:6:"bb\'bb";s:3:"bbb";s:5:"cc'cc";s:3:"ccc";}]=]
    check_phpserialize("step8",phpsrl,expected)
  end

  do
    local luatable = {}
    luatable[ "aaa" ] = [=[aa"aa]=]
    luatable[ "bbb" ] = [=[bb\'bb]=]
    luatable[ "ccc" ] = [=[cc'cc]=]
    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = [=[a:3:{s:3:"ccc";s:5:"cc'cc";s:3:"bbb";s:6:"bb\'bb";s:3:"aaa";s:5:"aa"aa";}]=]
    check_phpserialize("step9",phpsrl,expected)
  end

  do
    local luatable = {asdasd=1,dfb="2",qweqwe=-5;}
    local luatable2 = {tab2a = "asdasd", tab2b = 15}
    luatable.recurse1 = {}
    luatable.recurse2 = luatable2
    luatable.recurse1.blablalba = luatable2
    local phpsrl = phpserialize.phpserialize(luatable,0);
    local expected = [=[a:5:{s:8:"recurse2";a:2:{s:5:"tab2a";s:6:"asdasd";s:5:"tab2b";i:15;}s:8:"recurse1";a:1:{s:9:"blablalba";a:2:{s:5:"tab2a";s:6:"asdasd";s:5:"tab2b";i:15;}}s:6:"qweqwe";i:-5;s:3:"dfb";s:1:"2";s:6:"asdasd";i:1;}]=]
    check_phpserialize("step10",phpsrl,expected)
  end

  do
    local luatable = {asdasd=1,dfb="2",qweqwe=-5;}
    local luatable2 = {tab2a = "asdasd", tab2b = 15}
    luatable.recurse1 = {}
    luatable.recurse2 = luatable2
    luatable.recurse1.blablalba = luatable2
    local phpsrl = phpserialize.phpserialize(luatable,0);
    local expected = [=[a:5:{s:8:"recurse2";a:2:{s:5:"tab2a";s:6:"asdasd";s:5:"tab2b";i:15;}s:8:"recurse1";a:1:{s:9:"blablalba";a:2:{s:5:"tab2a";s:6:"asdasd";s:5:"tab2b";i:15;}}s:6:"qweqwe";i:-5;s:3:"dfb";s:1:"2";s:6:"asdasd";i:1;}]=]
    check_phpserialize("step11",phpsrl,expected)
  end

  do
    local luatable = {
      15;
      "123123";
      "sdfvxcv";
      rec2={12;zxcc=1;};
      rec3={xcxx="2wefrw";};
    }
    local phpsrl = phpserialize.phpserialize(luatable,0);
    local expected = [=[a:5:{i:0;i:15;i:1;s:6:"123123";i:2;s:7:"sdfvxcv";s:4:"rec3";a:1:{s:4:"xcxx";s:6:"2wefrw";}s:4:"rec2";a:2:{i:0;i:12;s:4:"zxcc";i:1;}}]=]
    check_phpserialize("step12",phpsrl,expected)
  end

  do
    local luatable = {}
    luatable[#luatable+1] = "111V_sdfv\"'=%$#@!^&*(*)_+_=-=xcv"
    luatable["222K_sdfv\"'=%$#@!^&*(*)_+_=-=xcv_KEYS2"] = "222VVVV_sdfv\"'=%$#@!^&*(*)_+_=-=xcv2"
    local phpsrl = phpserialize.phpserialize(luatable,0);
    local expected = [=[a:2:{i:0;s:32:"111V_sdfv"'=%$#@!^&*(*)_+_=-=xcv";s:38:"222K_sdfv"'=%$#@!^&*(*)_+_=-=xcv_KEYS2";s:36:"222VVVV_sdfv"'=%$#@!^&*(*)_+_=-=xcv2";}]=]
    check_phpserialize("step13",phpsrl,expected)
  end

  do
    local luatable = {}
    luatable[#luatable+1] = "val1"
    --luatable[12.1] = "val2-a"
    luatable[ 2110000000] = "val2-a"
    luatable[-2110000000] = "val2-b"
    luatable[-100] = "sdfsdfsdf"
    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = [=[a:4:{i:1;s:4:"val1";i:-2110000000;s:6:"val2-b";i:2110000000;s:6:"val2-a";i:-100;s:9:"sdfsdfsdf";}]=]
    check_phpserialize("step14",phpsrl,expected)
  end
end

-- fail patterns
local test_serializefails = function()
  do
    local luatable = {}
    luatable[-10/0] = "10 on zero"
    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = nil
    check_phpserialize("step15",phpsrl,expected)
  end

  do
    local luatable = {}
    luatable[10/0] = "10 on zero"
    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = nil
    check_phpserialize("step16",phpsrl,expected)
  end

  do
    local luatable = {asdasd=1,dfb="2",qweqwe=-5;}
    luatable[0.56] = "DrobnijFig"
    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = nil
    check_phpserialize("step17",phpsrl,expected)
  end

  do
    local luatable = {asdasd=1,dfb="2",qweqwe=-5;}
    luatable[true] = "???"
    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = nil
    check_phpserialize("step18",phpsrl,expected)
  end

  do
    local luatable = {asdasd=1,dfb="2",qweqwe=-5;}
    luatable[{1}] = "???"
    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = nil
    check_phpserialize("step19",phpsrl,expected)
  end

  do
    local luatable={asdasd=1,dfb="2",qweqwe=-5;}
    luatable.recurse1 = luatable
    local phpsrl = phpserialize.phpserialize(luatable,0);
    local expected = nil
    check_phpserialize("step20",phpsrl,expected)
  end

  do
    local luatable={asdasd=1,dfb="2",qweqwe=-5;}
    luatable.recurse1 = {}
    luatable.recurse1.blablalba = luatable
    local phpsrl = phpserialize.phpserialize(luatable,0);
    local expected = nil
    check_phpserialize("step21",phpsrl,expected)
  end

  do
    local luatable = {}
    luatable[12.1] = "val2-a"
    local phpsrl = phpserialize.phpserialize(luatable,1);
    local expected = nil
    check_phpserialize("step22",phpsrl,expected)
  end
end


local test_serializettbl = function()
  local serialize_result = function(tbl)
    return phpserialize.phpserialize(tbl,0)
  end
  local ensure_strequals = function(msg, serializedval, expectedval)
    check_phpserialize(msg, tostring(serializedval), tostring(expectedval))
  end
  local recursive_nil = false
  
  -- copy-pasted from test_tshort, table.lua
  ensure_strequals("", serialize_result({}), "a:0:{}")
  ensure_strequals("", serialize_result({1}), "a:1:{i:0;i:1;}")
  ensure_strequals("", serialize_result({a = 1}), [=[a:1:{s:1:"a";i:1;}]=])
  ensure_strequals("", serialize_result({a = 1, 1, 2, 3}), [=[a:4:{i:0;i:1;i:1;i:2;i:2;i:3;s:1:"a";i:1;}]=])
  ensure_strequals("", serialize_result({a = {}, 1, {1}, 3}), [=[a:4:{i:0;i:1;i:1;a:1:{i:0;i:1;}i:2;i:3;s:1:"a";a:0:{}}]=])
  ensure_strequals("", serialize_result({["1"]=2,[1]=3}), [=[nil]=])
  ensure_strequals("", serialize_result({a=false,[1]=false}), [=[a:2:{s:1:"a";b:0;i:0;b:0;}]=])
  ensure_strequals("", serialize_result(nil), [=[N;]=])
  ensure_strequals("", serialize_result(2), [=[i:2;]=])
  ensure_strequals("", serialize_result("a\""), [=[s:2:"a"";]=])
  ensure_strequals("", serialize_result(false), [=[b:0;]=])
  ensure_strequals("", serialize_result(true), [=[b:1;]=])
  ensure_strequals("", serialize_result(function()end),nil)
  ensure_strequals("", serialize_result(coroutine.create(function()end)),nil)
  ensure_strequals("", serialize_result(newproxy()),nil)
  ensure_strequals("", serialize_result({2}), [=[a:1:{i:0;i:2;}]=])
  ensure_strequals("", serialize_result({"a\""}), [=[a:1:{i:0;s:2:"a"";}]=])
  ensure_strequals("", serialize_result({"a\n"}), [=[a:1:{i:0;s:2:"a
";}]=])
  ensure_strequals("", serialize_result({false}), [=[a:1:{i:0;b:0;}]=])
  ensure_strequals("", serialize_result({true}), [=[a:1:{i:0;b:1;}]=])
  ensure_strequals("", serialize_result({function()end}),nil)
  ensure_strequals("", serialize_result({coroutine.create(function()end)}),nil)
  ensure_strequals("", serialize_result({newproxy()}),nil)
  ensure_strequals("", serialize_result({[2] = true}), [=[a:1:{i:1;b:1;}]=])
  ensure_strequals("", serialize_result({["a\""] = true}), [=[a:1:{s:2:"a"";b:1;}]=])
  ensure_strequals("", serialize_result({["a\n"] = true}), [=[a:1:{s:2:"a
";b:1;}]=])
  ensure_strequals("", serialize_result({[false] = true}), nil)
  ensure_strequals("", serialize_result({[true] = true}), nil)
  ensure_strequals("", serialize_result({[function()end] = true}),nil)
  ensure_strequals("", serialize_result({[coroutine.create(function()end)] = true}),nil)
  ensure_strequals("", serialize_result({[newproxy()] = true}),nil)
  ensure_strequals("", serialize_result({[0] = 2, [1] = 3, [2] = 4}), [=[a:3:{i:-1;i:2;i:1;i:4;i:0;i:3;}]=])
  ensure_strequals("", serialize_result({[-1] = 2, [1] = 3, [2] = 4}), [=[a:3:{i:0;i:3;i:1;i:4;i:-2;i:2;}]=])
  ensure_strequals("", serialize_result({[1] = 1, [2] = 2, [4] = 3}), [=[a:3:{i:0;i:1;i:1;i:2;i:3;i:3;}]=])
  ensure_strequals("", serialize_result({[1] = 1, [2] = 2, [1024] = 3}), [=[a:3:{i:0;i:1;i:1;i:2;i:1023;i:3;}]=])
  ensure_strequals("", serialize_result({[0.001] = 1}), nil)
  ensure_strequals("", serialize_result({[0.5] = 5, [1] = 10, [2] = 20}), nil)
  ensure_strequals("", serialize_result({[1] = 10, [1.5] = 15, [2] = 20}), nil)
  ensure_strequals("", serialize_result({[1] = 10, [2] = 20, [2.5] = 25}), nil)
  ensure_strequals("", serialize_result({nil, 7, nil, 18, nil, 64, nil, nil}), [=[a:3:{i:1;i:7;i:3;i:18;i:5;i:64;}]=])
  ensure_strequals("", serialize_result({a=nil, b=7, c=nil, 38, nil}), [=[a:2:{i:0;i:38;s:1:"b";i:7;}]=])
  ensure_strequals("", serialize_result({[{}]=7}), nil)
  ensure_strequals("", serialize_result({[{}]=true}), nil)
  ensure_strequals("plain", serialize_result({{1},[{1}]=true}), nil)
  local t = {1}
  if not recursive_nil then
    ensure_strequals("n1", serialize_result({t, t}), [=[a:2:{i:0;a:1:{i:0;i:1;}i:1;a:1:{i:0;i:1;}}]=])
    ensure_strequals("nested", serialize_result({[t] = true, t}), nil)
    ensure_strequals("n2", serialize_result({[t]=t}), nil)
  else
    ensure_strequals("n1-t", serialize_result({t, t}), [=[]=])
    ensure_strequals("nested-t", serialize_result({[t] = true, t}), [=[]=])
    ensure_strequals("n2-t", serialize_result({[t]=t}), [=[]=])
  end
  
  local r = {1}
  r[2] = r
  r.n = { r = r }
  if not recursive_nil then
    ensure_strequals("r1", serialize_result(r), nil) -- '{1,"table (recursive)",n={r="table (recursive)"}}')
  else
    ensure_strequals("r1-t", serialize_result(r), [=[]=])
  end

  local mt =
  {
    __index = function(t, k)
      rawset(t, k, k)
      return k
    end;
  }
  ensure_strequals("mt1", serialize_result(setmetatable({}, mt)), [=[a:0:{}]=]) -- Say no to infinite loops!
end

test_serialize()
test_serializefails()
test_serializettbl()

print("OK")
