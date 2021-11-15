
local Common = {}

function Common.writeFile(filepath,str)
	local file = io.open(filepath,"w")
	if file then
		file:write(str)
		file:close()
		return true
	end
	return false
end


-- read file contents
-- @param path: string type
-- @return file contents, string type
function Common.readFile(path)
  if not path then return nil end
  local file = io.open(path, "r")
  if file then
    data = file:read("*all")
    file:close()
    return data
  end
  return ""
end


-- string split by a single delimiter.
-- Delimiter ",,," will be treated as ",,,".
-- Empty element between delimiters will be treated as empty string.
-- @param input: string type
-- @param delimiter: string type
-- @return string array after split
-- e.g. splitString("a,b,,,c,d",",") => {"a","b","","","c","d"}
function Common.splitString(input, delimiter)
    if not input or not delimiter then return nil end
    input = tostring(input)
    delimiter = tostring(delimiter)
    if delimiter=='' then return false end
    local pos,arr = 0, {}
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

-- string split by a mixed delimiter.
-- Delimiter "&|" will be treated as any delimiter composed by consecutive "&" and "|".
-- @param input: string type
-- @param delimiter: string type
-- @return string array after split
-- e.g. splitBySeveralDelimiter("a&&b||c&&d","&|") => {"a","b","c","d"}
function Common.splitBySeveralDelimiter(input,delimiter)
    if not input or not delimiter then return nil end
    local resultStrArr = {}
    string.gsub(input,'[^'..delimiter..']+',function (w)
        table.insert(resultStrArr,w)
    end)
    return resultStrArr
end

-- gain delimiter sequence in a string.
-- Delimiter "&|" will be treated as any delimiter composed by consecutive "&" and "|".
-- @param input: string type
-- @param delimiter: string type
-- @return delimiter array in a string
-- e.g. gainDelimiterSequence("a&&b||c&&d","&|") => {"&&","||","&&"}
function Common.gainDelimiterSequence(input,delimiter)
    if not input or not delimiter then return nil end
    local resultStrArr = {}
    string.gsub(input,'['..delimiter..']+',function (w)
        table.insert(resultStrArr,w)
    end)
    return resultStrArr
end

-- remove extra spaces at begin and end
-- @param str: input string
-- @return string after trimmed
-- e.g. trim(" a == b  ") => "a == b"
function Common.trim(str)
    if not str then
        return nil
    else
        return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
    end
end

-- present table as key-value string format
-- @param o: input table
-- @return key-value string format
-- e.g. dump({"a","b","c",["d"] = 4, ["e"] = 5,}) => { [1] = a,[2] = b,[3] = c,["d"] = 4,["e"] = 5,}
function Common.dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. Common.dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

-- deepCompare if 2 object are the same, support table recursively value compare
-- @param t1: a table to compare
-- @param t2: a table to compare against t1.
function Common.deepCompare(t1, t2)
    local type1 = type(t1)
    local type2 = type(t2)
    if type1 ~= type2 then return false end
    if type(t1) ~= 'table' and type(t2) ~= 'table' then return t1 == t2 end

    -- keys that has been compared
    local compared = {}
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not Common.deepCompare(v1, v2) then return false end
        compared[k1] = true
    end

    for k2, v2 in pairs(t2) do
        if not compared[k2] then return false end
    end
    return true
end

-- return true if given table1 and table2 are identical: same length, same values.
-- return false and the different node index.
-- used to check if CSV title row is expected.
-- only works for array; do not support dictionary with key-value pairs.
function Common.arrayCmp(t1, t2)
    local i = 1
    while true do
        if t1[i] == nil and t2[i] == nil then
            return true
        end
        if t1[i] ~= t2[i] then
            return false, i
        end
        i = i + 1
    end
end

-- check if file exists at designated path
-- @param path: string type
-- @return whether the file exists
-- e.g. fileExists("/Users/gdlocal/Library/Atlas2/Assets/Main.csv") => true
function Common.fileExists(path)
  if not path then return nil end
  local file = io.open(path, "rb")
  if file then
    file:close()
    return true
  end
  return false
end


-- check if key exists in a dictionary
-- e.g. hasKey({["d"] = 4, ["e"] = 5,},"d") => true
function Common.hasKey(tab, key)
  if not tab or not key then return nil end
  for k, v in pairs(tab) do
      if k == key then
          return true
      end
  end
  return false
end

-- check if value exists in an array
-- e.g. hasVal({"d", "e",},"d") => true
function Common.hasVal(valueArr,valueStr)
    for _,value in ipairs(valueArr) do
        if value == valueStr then
            return true
        end
    end
    return false
end

-- return keys of a table
-- e.g. tableKeys({4,5,["a"]="44",}) => {1,2,"a",}
function Common.tableKeys(input_table)
    if not input_table then return nil end
    local output_keys = {}
    for k, v in pairs(input_table) do
        table.insert(output_keys, k)
    end
    return output_keys
end

-- system sleep
function Common.sleep(n)
    os.execute("sleep " .. tonumber(n))
end

-- run function catch_f if function f throws any exception
function Common.try(f, catch_f)
    local status, exception = xpcall(f,debug.traceback)
    if not status
    then
        catch_f(exception)
    end
end

-- calculate boolean logic for condition column
-- @param str: input condition string
-- @return boolean value
-- e.g. calConditionVal(" sn == 2 && ver != 4",{["sn"] = "2",["ver"] = "4",["boardid"] = "C"}) => false
function Common.calConditionVal(str,conditionValueTable)
    if type(str) ~= "string" then
        error("expect a string equation")
    end

    local boolStrArr = Common.splitBySeveralDelimiter(Common.trim(str),"&|")
    local boolLogicArr = Common.gainDelimiterSequence(Common.trim(str),"&|")
    local boolValArr = {}
    for _,v in ipairs(boolStrArr) do
        local vGroup = Common.splitBySeveralDelimiter(v,"!=")
        local vLogic = Common.gainDelimiterSequence(v,"!=")[1]
        local vLeft = Common.trim(vGroup[1])
        local vRight = Common.trim(vGroup[2])
        local vLeftVal,vRightVal
        if conditionValueTable[vLeft] == nil and conditionValueTable[vRight] == nil then
            error('Condition ' .. vLeft .. ' or ' .. vRight .. ' value not set')
        end

        if conditionValueTable[vLeft] then
            vLeftVal = conditionValueTable[vLeft]
        else
            vLeftVal = tostring(vLeft)
        end

        if conditionValueTable[vRight] then
            vRightVal = conditionValueTable[vRight]
        else
            vRightVal = tostring(vRight)
        end

        if vLogic == "==" then
            table.insert(boolValArr,vLeftVal == vRightVal)
        elseif vLogic == "!=" then
            table.insert(boolValArr,vLeftVal ~= vRightVal)
        else
            -- other valid boolean logics can be expanded here

            error(string.format("Invalid operator : %s",vLogic))
        end
    end

    local conditionResult = boolValArr[1]
    for i,v in ipairs(boolLogicArr) do
        if v == "&&" then
            conditionResult = conditionResult and boolValArr[i+1]
        elseif v == "||" then
            conditionResult = conditionResult or boolValArr[i+1]
        else
            -- other valid boolean logics can be expanded here

            error(string.format("Invalid operator : %s",v))
        end
    end

    return conditionResult
end

-- parse and return parameter list for further indexing, support dictionaries and arrays
-- @param paraStr: input parameter string
-- @return parameter dictionary or array
-- e.g. parseParameter("{\"Input\":\"success\",\"Output\":\"SN\",\"timeout\": 50}")
--      => { ["Input"] = "success",["Output"] = "SN",["timeout"] = "50",}
--      parseParameter("[a,b,c,1,2,3]")
--      => {"a","b","c","1","2","3"}
function Common.parseParameter(paraStr)
    local paraList = {}
    local json = require("Matchbox/json")
    if paraStr == "" then
        return paraList
    else
        return json.decode(paraStr)
    end
end

-- parse static conditions and store in an array
-- @param allowValStr: allowable value string, seperate by ";"
-- @return condition array
-- e.g. parseValArr("00011a;00011b;000111") => {"00011a","00011b","000111",}
function Common.parseValArr(allowValStr)
    local allowValArr = {}
    allowValStr = Common.trim(allowValStr)
    allowValArr = Common.splitBySeveralDelimiter(allowValStr,";")
    for i in ipairs(allowValArr) do
        allowValArr[i] = Common.trim(allowValArr[i])
    end
    return allowValArr
end


function Common.toFloat( str )
  -- body
  -- if type(str) == tonumber then return str end
  if str == nil or str == '' then return 0 end

  return tonumber(string.format("%0.6f",str))
end 

-- function Common.popen(cmd)
--   local l = io.popen(cmd)
--   local str = l:read("*all")
--   print("popen read:"..str)
--   l:close()
--   return str
-- end

function Common.getItemTable(content)
  -- body
  local arr = {}
  -- for vaule in io.lines(content) do
  --   print(vaule)
  -- end

  for vaule in string.gmatch(content,'([^,]+)') do
    vaule = string.gsub(vaule,"\n", "")
    vaule = string.gsub(vaule,"\r", "")
    vaule = string.gsub(vaule,",", "")
    table.insert(arr,vaule)
    print(vaule)

  end

  return arr
end



-- function Common.pingIP( ip )
--     local pingCmd = "ping " .. ip .. " -c 1 -t 1"
--     local reply = Common.popen(pingCmd)--
--     if string.find(reply,'0.0%% packet loss') or string.match(reply,'(icmp_seq=%d+%sttl=)') then
--       return true
--     else
--         return false
--       end
    
-- end

-- 　 lfs.attributes(filepath [, aname]) 获取路径指定属性
--     lfs.chdir(path) 改变当前工作目录，成功返回true，失败返回nil加上错误信息
--     lfs.currentdir 获取当前工作目录，成功返回路径，失败为nil加上错误信息
--     lfs.dir(path) 返回一个迭代器（function）和一个目录（userdata），每次迭代器都会返回一个路径，直到不是文件目录为止，则迭代器返回nil
--     lfs.lock(filehandle, mode[, start[, length]])
--     lfs.mkdir(dirname)  创建一个新目录
--     lfs.rmdir(dirname) 删除一个已存在的目录，成功返回true，失败返回nil加上错误信息
function Common.GetAllFiles(rootPath)
    local allFilePath = {}
    local lfs = require "lfs"
    for entry in lfs.dir(rootPath) do
        if entry~='.' and entry~='..' then
            local path = rootPath..'/'..entry
            local attr = lfs.attributes(path)
            assert(type(attr)=="table") --如果获取不到属性表则报错
            -- PrintTable(attr)
            if(attr.mode == "directory") then
                print("Dir:",path)
                GetAllFiles(path) --自调用遍历子目录
            elseif attr.mode=="file" then
                print(attr.mode,path)
                table.insert(allFilePath,path)
            end
        end
    end
    return allFilePath
end
-- local a = os.time()
-- -- print(a)

-- os.execute("sleep 5")

-- local b = os.time()
-- print(b)
-- local c = os.difftime(b, a)

-- local lfs = require "lfs"
-- local currentdir = lfs.currentdir()
-- os.execute('ls'..' &> '..currentdir..'test.txt')
-- GetAllFiles('/Users/ciweiluo/Desktop/Compare_CycleTime')

return Common
