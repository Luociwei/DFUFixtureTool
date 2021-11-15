--UART Communication
local HWIO = {}

local ui = require("LuaScript/Base/InterfaceView")
local json = require("LuaScript/Tech/json")
local common = require("LuaScript/Tech/Common")

function HWIO.cmdsTable()
    local scriptPath = ui.luaScriptPath()
    print('luaScriptPath--'..scriptPath)
    local hwio_content = common.readFile(scriptPath..'/Tech/HWIO.json')
    local cmdsTable = json.decode(hwio_content)
    -- print(cmdsTable["rpc_connect"][1])
    --for k in pairs(cmdsTable) do
        --print(k)
    --end
    return cmdsTable

end



function HWIO.getScriptCmds(script_name)
    local luaScriptPath = ui.luaScriptPath()
    local scriptPath = luaScriptPath..'/ScriptTestFiles/'..script_name
     -- ui.fixtureLog('scriptPath'..scriptPath,1)
    local hwio_content = common.readFile(scriptPath)
    local cmdsTable = json.decode(hwio_content)
    --for k in pairs(cmdsTable) do
        --print(k)
    --end
    return cmdsTable

end

function HWIO.ipPorts()

    local cmdsTable = HWIO.cmdsTable()
    return cmdsTable["rpc_connect"]

end

function HWIO.getCmds(key)

    local cmdsTable = HWIO.cmdsTable()
    local cmds = cmdsTable[key]
    return cmds

end

return HWIO
