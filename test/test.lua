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

local test_stackoverflow = function()
local t = {
    {title="some long title",id=1,kind=0,rows={
      {value=3404,user_gender=2,user_nick="01234567890",user_id=6922},
      {value=3185,user_gender=2,user_nick="01234567890",user_id=2778},
      {value=2636,user_gender=1,user_nick="01234567890",user_id=12004},
      {value=2551,user_gender=1,user_nick="01234567890",user_id=11013},
      {value=2323,user_gender=1,user_nick="01234567890",user_id=20891},
      {value=2263,user_gender=1,user_nick="01234567890",user_id=2037},
      {value=1850,user_gender=2,user_nick="01234567890",user_id=9827},
      {value=1698,user_gender=2,user_nick="01234567890",user_id=20160},
      {value=1696,user_gender=1,user_nick="01234567890",user_id=1186},
      {value=1588,user_gender=1,user_nick="01234567890",user_id=105500},
      {value=1569,user_gender=2,user_nick="01234567890",user_id=117509},
      {value=1543,user_gender=1,user_nick="01234567890",user_id=13315},
      {value=1465,user_gender=1,user_nick="01234567890",user_id=12756},
      {value=1446,user_gender=2,user_nick="01234567890",user_id=3195},
      {value=1438,user_gender=1,user_nick="01234567890",user_id=368442},
      {value=1423,user_gender=2,user_nick="01234567890",user_id=7468},
      {value=1409,user_gender=1,user_nick="01234567890",user_id=269852},
      {value=1406,user_gender=1,user_nick="01234567890",user_id=3007},
      {value=1399,user_gender=2,user_nick="01234567890",user_id=12051},
      {value=1391,user_gender=1,user_nick="01234567890",user_id=23909},
      {value=1368,user_gender=1,user_nick="01234567890",user_id=10846},
      {value=1352,user_gender=1,user_nick="01234567890",user_id=140900},
      {value=1263,user_gender=2,user_nick="01234567890",user_id=36668},
      {value=1256,user_gender=2,user_nick="01234567890",user_id=32},
      {value=1228,user_gender=2,user_nick="01234567890",user_id=29901},
      {value=1222,user_gender=2,user_nick="01234567890",user_id=37142},
      {value=1213,user_gender=2,user_nick="01234567890",user_id=31},
      {value=1200,user_gender=2,user_nick="01234567890",user_id=51668},
      {value=1198,user_gender=1,user_nick="01234567890",user_id=27347},
      {value=1185,user_gender=1,user_nick="01234567890",user_id=18299},
      {value=1180,user_gender=1,user_nick="01234567890",user_id=235980},
      {value=1177,user_gender=1,user_nick="01234567890",user_id=120193},
      {value=1168,user_gender=2,user_nick="01234567890",user_id=11251},
      {value=1163,user_gender=1,user_nick="01234567890",user_id=445691},
      {value=1161,user_gender=2,user_nick="01234567890",user_id=39336},
      {value=1144,user_gender=1,user_nick="01234567890",user_id=324648},
      {value=1139,user_gender=1,user_nick="01234567890",user_id=2617},
      {value=1137,user_gender=2,user_nick="01234567890",user_id=7314},
      {value=1125,user_gender=1,user_nick="01234567890",user_id=263948},
      {value=1120,user_gender=1,user_nick="01234567890",user_id=461572},
      {value=1119,user_gender=1,user_nick="01234567890",user_id=6361},
      {value=1110,user_gender=2,user_nick="01234567890",user_id=43337},
      {value=1109,user_gender=1,user_nick="01234567890",user_id=196229},
      {value=1106,user_gender=1,user_nick="01234567890",user_id=22973},
      {value=1100,user_gender=2,user_nick="01234567890",user_id=11946},
      {value=1098,user_gender=1,user_nick="01234567890",user_id=31553},
      {value=1096,user_gender=1,user_nick="01234567890",user_id=286184},
      {value=1094,user_gender=1,user_nick="01234567890",user_id=286704},
      {value=1094,user_gender=1,user_nick="01234567890",user_id=39},
      {value=1086,user_gender=1,user_nick="01234567890",user_id=31120}},
      descrption="some long description"
    },
    {title="some long title2",id=2,kind=0,rows={
      {value=879156,user_gender=2,user_nick="01234567890",user_id=6922},
      {value=870840,user_gender=1,user_nick="01234567890",user_id=1227},
      {value=834413,user_gender=2,user_nick="01234567890",user_id=2778},
      {value=779940,user_gender=1,user_nick="01234567890",user_id=11013},
      {value=771886,user_gender=1,user_nick="01234567890",user_id=12004},
      {value=696306,user_gender=1,user_nick="01234567890",user_id=11044},
      {value=552185,user_gender=1,user_nick="01234567890",user_id=8886},
      {value=540953,user_gender=1,user_nick="01234567890",user_id=2617},
      {value=503989,user_gender=2,user_nick="01234567890",user_id=20160},
      {value=503523,user_gender=1,user_nick="01234567890",user_id=286184},
      {value=500319,user_gender=1,user_nick="01234567890",user_id=89},
      {value=467098,user_gender=1,user_nick="01234567890",user_id=1186},
      {value=453344,user_gender=1,user_nick="01234567890",user_id=377},
      {value=447110,user_gender=2,user_nick="01234567890",user_id=27223},
      {value=430384,user_gender=2,user_nick="01234567890",user_id=11054},
      {value=423897,user_gender=1,user_nick="01234567890",user_id=244154},
      {value=417563,user_gender=2,user_nick="01234567890",user_id=1688},
      {value=410874,user_gender=2,user_nick="01234567890",user_id=7314},
      {value=401740,user_gender=1,user_nick="01234567890",user_id=39},
      {value=401085,user_gender=1,user_nick="01234567890",user_id=20891},
      {value=391896,user_gender=2,user_nick="01234567890",user_id=117509},
      {value=379260,user_gender=2,user_nick="01234567890",user_id=32},
      {value=366247,user_gender=2,user_nick="01234567890",user_id=58748},
      {value=363655,user_gender=1,user_nick="01234567890",user_id=25591},
      {value=357264,user_gender=1,user_nick="01234567890",user_id=269852},
      {value=347827,user_gender=2,user_nick="01234567890",user_id=9827},
      {value=347399,user_gender=1,user_nick="01234567890",user_id=6038},
      {value=346551,user_gender=2,user_nick="01234567890",user_id=8664},
      {value=341588,user_gender=2,user_nick="01234567890",user_id=12270},
      {value=321805,user_gender=2,user_nick="01234567890",user_id=3195},
      {value=319622,user_gender=2,user_nick="01234567890",user_id=274749},
      {value=317440,user_gender=2,user_nick="01234567890",user_id=6013},
      {value=311992,user_gender=2,user_nick="01234567890",user_id=167355},
      {value=310080,user_gender=2,user_nick="01234567890",user_id=360998},
      {value=306893,user_gender=1,user_nick="01234567890",user_id=461572},
      {value=305951,user_gender=1,user_nick="01234567890",user_id=140900},
      {value=304156,user_gender=1,user_nick="01234567890",user_id=6361},
      {value=299714,user_gender=2,user_nick="01234567890",user_id=12051},
      {value=295021,user_gender=2,user_nick="01234567890",user_id=37142},
      {value=290926,user_gender=1,user_nick="01234567890",user_id=2037},
      {value=287596,user_gender=2,user_nick="01234567890",user_id=306461},
      {value=287480,user_gender=2,user_nick="01234567890",user_id=11855},
      {value=286542,user_gender=2,user_nick="01234567890",user_id=31},
      {value=286281,user_gender=2,user_nick="01234567890",user_id=29901},
      {value=285217,user_gender=2,user_nick="01234567890",user_id=8181},
      {value=284868,user_gender=1,user_nick="01234567890",user_id=10846},
      {value=283742,user_gender=2,user_nick="01234567890",user_id=9117},
      {value=283248,user_gender=2,user_nick="01234567890",user_id=11251},
      {value=282526,user_gender=2,user_nick="01234567890",user_id=292031},
      {value=275837,user_gender=1,user_nick="01234567890",user_id=2885}},
      descrption="some long description2"
    },
    {title="some long title3",id=3,kind=0,rows={
      {value=452,user_gender=1,user_nick="01234567890",user_id=20891},
      {value=280,user_gender=2,user_nick="01234567890",user_id=6922},
      {value=277,user_gender=1,user_nick="01234567890",user_id=25591},
      {value=249,user_gender=1,user_nick="01234567890",user_id=263648},
      {value=227,user_gender=2,user_nick="01234567890",user_id=20160},
      {value=218,user_gender=1,user_nick="01234567890",user_id=496618},
      {value=214,user_gender=1,user_nick="01234567890",user_id=532323},
      {value=197,user_gender=1,user_nick="01234567890",user_id=525419},
      {value=195,user_gender=1,user_nick="01234567890",user_id=272666},
      {value=194,user_gender=1,user_nick="01234567890",user_id=2617},
      {value=172,user_gender=2,user_nick="01234567890",user_id=483682},
      {value=159,user_gender=1,user_nick="01234567890",user_id=124369},
      {value=156,user_gender=1,user_nick="01234567890",user_id=338203},
      {value=155,user_gender=2,user_nick="01234567890",user_id=377667},
      {value=147,user_gender=1,user_nick="01234567890",user_id=286184},
      {value=127,user_gender=1,user_nick="01234567890",user_id=402266},
      {value=122,user_gender=1,user_nick="01234567890",user_id=175083},
      {value=122,user_gender=2,user_nick="01234567890",user_id=31697},
      {value=118,user_gender=1,user_nick="01234567890",user_id=520979},
      {value=112,user_gender=1,user_nick="01234567890",user_id=263948},
      {value=104,user_gender=2,user_nick="01234567890",user_id=2778},
      {value=103,user_gender=2,user_nick="01234567890",user_id=31},
      {value=100,user_gender=1,user_nick="01234567890",user_id=611218},
      {value=100,user_gender=1,user_nick="01234567890",user_id=385851},
      {value=96,user_gender=2,user_nick="01234567890",user_id=299627},
      {value=94,user_gender=1,user_nick="01234567890",user_id=478842},
      {value=91,user_gender=1,user_nick="01234567890",user_id=550750},
      {value=91,user_gender=2,user_nick="01234567890",user_id=506750},
      {value=91,user_gender=1,user_nick="01234567890",user_id=39279},
      {value=90,user_gender=1,user_nick="01234567890",user_id=269852},
      {value=86,user_gender=1,user_nick="01234567890",user_id=244154},
      {value=86,user_gender=2,user_nick="01234567890",user_id=117509},
      {value=86,user_gender=1,user_nick="01234567890",user_id=2129},
      {value=85,user_gender=2,user_nick="01234567890",user_id=439407},
      {value=85,user_gender=2,user_nick="01234567890",user_id=29974},
      {value=84,user_gender=1,user_nick="01234567890",user_id=286704},
      {value=84,user_gender=1,user_nick="01234567890",user_id=10846},
      {value=83,user_gender=1,user_nick="01234567890",user_id=519785},
      {value=83,user_gender=1,user_nick="01234567890",user_id=8886},
      {value=80,user_gender=2,user_nick="01234567890",user_id=39336},
      {value=80,user_gender=1,user_nick="01234567890",user_id=6038},
      {value=80,user_gender=1,user_nick="01234567890",user_id=5740},
      {value=79,user_gender=2,user_nick="01234567890",user_id=368240},
      {value=78,user_gender=2,user_nick="01234567890",user_id=282038},
      {value=76,user_gender=1,user_nick="01234567890",user_id=355622},
      {value=75,user_gender=1,user_nick="01234567890",user_id=296531},
      {value=75,user_gender=1,user_nick="01234567890",user_id=12004},
      {value=74,user_gender=1,user_nick="01234567890",user_id=511894},
      {value=73,user_gender=1,user_nick="01234567890",user_id=349904},
      {value=71,user_gender=1,user_nick="01234567890",user_id=579619}},
      descrption="some long description3"
    },
    {title="some long title4",id=4,kind=1,rows={
      {value=986967,user_gender=2,user_nick="01234567890",user_id=2778},
      {value=840776,user_gender=1,user_nick="01234567890",user_id=11013},
      {value=825484,user_gender=1,user_nick="01234567890",user_id=12004},
      {value=764637,user_gender=1,user_nick="01234567890",user_id=12756},
      {value=747398,user_gender=1,user_nick="01234567890",user_id=2037},
      {value=684397,user_gender=1,user_nick="01234567890",user_id=105500},
      {value=680494,user_gender=2,user_nick="01234567890",user_id=167355},
      {value=628037,user_gender=2,user_nick="01234567890",user_id=233774},
      {value=623581,user_gender=1,user_nick="01234567890",user_id=196229},
      {value=615290,user_gender=2,user_nick="01234567890",user_id=7468},
      {value=590593,user_gender=1,user_nick="01234567890",user_id=140900},
      {value=585232,user_gender=2,user_nick="01234567890",user_id=37142},
      {value=577838,user_gender=1,user_nick="01234567890",user_id=9114},
      {value=548899,user_gender=2,user_nick="01234567890",user_id=9827},
      {value=541470,user_gender=2,user_nick="01234567890",user_id=237989},
      {value=538520,user_gender=2,user_nick="01234567890",user_id=4065},
      {value=536104,user_gender=2,user_nick="01234567890",user_id=107135},
      {value=530338,user_gender=1,user_nick="01234567890",user_id=13315},
      {value=528542,user_gender=2,user_nick="01234567890",user_id=6922},
      {value=524878,user_gender=2,user_nick="01234567890",user_id=12051},
      {value=520896,user_gender=1,user_nick="01234567890",user_id=235980},
      {value=519491,user_gender=2,user_nick="01234567890",user_id=14259},
      {value=514126,user_gender=2,user_nick="01234567890",user_id=117509},
      {value=512395,user_gender=2,user_nick="01234567890",user_id=36668},
      {value=510855,user_gender=2,user_nick="01234567890",user_id=39336},
      {value=509947,user_gender=2,user_nick="01234567890",user_id=12889},
      {value=508609,user_gender=1,user_nick="01234567890",user_id=25637},
      {value=506813,user_gender=1,user_nick="01234567890",user_id=150611},
      {value=505543,user_gender=1,user_nick="01234567890",user_id=3326},
      {value=503774,user_gender=1,user_nick="01234567890",user_id=1186},
      {value=500840,user_gender=2,user_nick="01234567890",user_id=8181},
      {value=499252,user_gender=2,user_nick="01234567890",user_id=147897},
      {value=493696,user_gender=2,user_nick="01234567890",user_id=29901},
      {value=492974,user_gender=2,user_nick="01234567890",user_id=11946},
      {value=492776,user_gender=2,user_nick="01234567890",user_id=7314},
      {value=492453,user_gender=1,user_nick="01234567890",user_id=30619},
      {value=489908,user_gender=1,user_nick="01234567890",user_id=6361},
      {value=483260,user_gender=2,user_nick="01234567890",user_id=181605},
      {value=479187,user_gender=2,user_nick="01234567890",user_id=408065},
      {value=477070,user_gender=2,user_nick="01234567890",user_id=11251},
      {value=476043,user_gender=2,user_nick="01234567890",user_id=383623},
      {value=473512,user_gender=2,user_nick="01234567890",user_id=139383},
      {value=472954,user_gender=1,user_nick="01234567890",user_id=296122},
      {value=470538,user_gender=2,user_nick="01234567890",user_id=3195},
      {value=468716,user_gender=2,user_nick="01234567890",user_id=20160},
      {value=468223,user_gender=1,user_nick="01234567890",user_id=150641},
      {value=467207,user_gender=2,user_nick="01234567890",user_id=267728},
      {value=466187,user_gender=1,user_nick="01234567890",user_id=134043},
      {value=466063,user_gender=1,user_nick="01234567890",user_id=286704},
      {value=465972,user_gender=2,user_nick="01234567890",user_id=241855}},
      descrption="some long description4"
    }
  }
  local result = phpserialize.phpserialize(t)
  print(result)
end


test_serialize()
test_serializefails()
test_serializettbl()
test_stackoverflow()

print("OK")
