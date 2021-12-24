
local DutSequence = {}
local rpc = require("LuaScript/Base/RPC")
local ui = require("LuaScript/Base/InterfaceView")
local hwio = require("LuaScript/Tech/HWIO")
local common = require("LuaScript/Tech/Common")
local thread = require("LuaScript/Base/Thread")

function DutSequence.fixture_resetAll ()
    local cmds = hwio.getCmds('reset')
    rpc.sendCmds(cmds,1)
    rpc.sendCmds(cmds,2)
    rpc.sendCmds(cmds,3)
    rpc.sendCmds(cmds,4)
end


function DutSequence.resetClick (slotsSelected)
    
    if rpc.object() == nil then
        ui.alert("Error","RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication.")
        return result_str
    end
    local isSelectedSlot1 = slotsSelected['isSelectedSlot1']
    local isSelectedSlot2 = slotsSelected['isSelectedSlot2']
    local isSelectedSlot3 = slotsSelected['isSelectedSlot3']
    local isSelectedSlot4 = slotsSelected['isSelectedSlot4']
    local result_str = '--isSelectedSlot1--'..isSelectedSlot1..'--isSelectedSlot2--'..isSelectedSlot2..'--isSelectedSlot3--'..isSelectedSlot3..'--isSelectedSlot4--'..isSelectedSlot4..'--end'
    local cmds = hwio.getCmds('reset')

    if isSelectedSlot1 == 1 then
        rpc.sendCmds(cmds,1)
    end
    if isSelectedSlot2 == 1 then
        rpc.sendCmds(cmds,2)
    end
    if isSelectedSlot3 == 1 then
        rpc.sendCmds(cmds,3)
    end
    if isSelectedSlot4 == 1 then
        rpc.sendCmds(cmds,4)
    end


end



local function scriptRunTest (script_name,site)
    -- local isBoardDetected = rpc.isBoardDetected(site,false)
    -- if isBoardDetected == false then
    --     ui.fixtureLog('checked the board is not detected in slot'..tostring(site)..'. so no commands were sended!!!',site)
    --     return ''
    -- end
    ui.fixtureLog('scriptRunTest',site)
    local cmds = hwio.getScriptCmds(script_name)
    rpc.sendCmds(cmds,site)

end




function DutSequence.scriptRun (script_name,slotsSelected)
    
    -- if rpc.object() == nil then
    --     ui.alert("Error","RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication.")
    --     return result_str
    -- end
    -- script_name = 'sib_test.json'
    local isSelectedSlot1 = slotsSelected['isSelectedSlot1']
    local isSelectedSlot2 = slotsSelected['isSelectedSlot2']
    local isSelectedSlot3 = slotsSelected['isSelectedSlot3']
    local isSelectedSlot4 = slotsSelected['isSelectedSlot4']
    local result_str = '--isSelectedSlot1--'..isSelectedSlot1..'--isSelectedSlot2--'..isSelectedSlot2..'--isSelectedSlot3--'..isSelectedSlot3..'--isSelectedSlot4--'..isSelectedSlot4..'--end'
    
    ui.fixtureLog('result_str'..result_str..'script_name'..script_name,1)
    if isSelectedSlot1 == 1 then
        scriptRunTest(script_name,1)
    end
    if isSelectedSlot2 == 1 then
        scriptRunTest(script_name,2)
    end
    if isSelectedSlot3 == 1 then
        scriptRunTest(script_name,3)
    end
    if isSelectedSlot4 == 1 then
        scriptRunTest(script_name,4)
    end


end

local function forceDFU (isOn,site)
    -- local isBoardDetected = rpc.isBoardDetected(site,false)
    
    -- if isBoardDetected == false then
    --     ui.fixtureLog('checked the board is not detected in slot'..tostring(site)..'. so no commands were sended!!!',site)
    --     return ''
    -- end
    local key = ''
    if isOn then
        key = 'force_dfu_on'
    else
        key = 'force_dfu_off'
    end

    local cmds = hwio.getCmds(key)
    rpc.sendCmds(cmds,site)

end

function DutSequence.forceDFUClick (isOn,slotsSelected)

    print('isOn--type'..type(isOn)..'--slotsSelected--'..type(slotsSelected))

    -- if rpc.object() == nil then
    --     ui.alert("Error","RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication.")
    --     return ''
    -- end
    local isSelectedSlot1 = tonumber(slotsSelected['isSelectedSlot1'])
    local isSelectedSlot2 = tonumber(slotsSelected['isSelectedSlot2'])
    local isSelectedSlot3 = tonumber(slotsSelected['isSelectedSlot3'])
    local isSelectedSlot4 = tonumber(slotsSelected['isSelectedSlot4'])

   print('isSelectedSlot1--'..isSelectedSlot1)
    if isSelectedSlot1 == 1 then
        forceDFU(isOn,1)
    end
    if isSelectedSlot2 == 1 then
        forceDFU(isOn,2)
    end
    if isSelectedSlot3 == 1 then
        forceDFU(isOn,3)
    end
    if isSelectedSlot4 == 1 then
        forceDFU(isOn,4)
    end


end

local function enterDIags (isOn,site)
    -- local isBoardDetected = rpc.isBoardDetected(site,false)
    -- if isBoardDetected == false then
    --     ui.fixtureLog('checked the board is not detected in slot. so no commands were sended!!!',site)
    --     return ''
    -- end

    local key = ''
    if isOn then
        key = 'force_diags_on'
        thread.DutReadThread_run()
    else
        key = 'force_diags_off'
        thread.DutReadThread_stop()
    end

    local cmds = hwio.getCmds(key)
    rpc.sendCmds(cmds,site)

end


function DutSequence.enterDIagsClick (isOn,slotsSelected)
    -- if rpc.object() == nil then
    --     ui.alert("Error","RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication.")
    --     return ''
    -- end

    local isSelectedSlot1 = slotsSelected['isSelectedSlot1']
    local isSelectedSlot2 = slotsSelected['isSelectedSlot2']
    local isSelectedSlot3 = slotsSelected['isSelectedSlot3']
    local isSelectedSlot4 = slotsSelected['isSelectedSlot4']
   print('isSelectedSlot1--'..isSelectedSlot1)
    if isSelectedSlot1 == 1 then
        enterDIags(isOn,1)
    end
    if isSelectedSlot2 == 1 then
        enterDIags(isOn,2)
    end
    if isSelectedSlot3 == 1 then
        enterDIags(isOn,3)
    end
    if isSelectedSlot4 == 1 then
        enterDIags(isOn,4)
    end



end

function DutSequence.fixtureSendClick (cmd,slotsSelected)
    local isSelectedSlot1 = slotsSelected['isSelectedSlot1']
    local isSelectedSlot2 = slotsSelected['isSelectedSlot2']
    local isSelectedSlot3 = slotsSelected['isSelectedSlot3']
    local isSelectedSlot4 = slotsSelected['isSelectedSlot4']
--    print('isSelectedSlot1--'..isSelectedSlot1)
    if cmd == '' or cmd == nil then cmd = '\n' end
    if isSelectedSlot1 == 1 then
       -- enterDIags(isOn,1)
       rpc.fixtureWirteRead(cmd,1)
    end
    if isSelectedSlot2 == 1 then
        --enterDIags(isOn,2)
        rpc.fixtureWirteRead(cmd,2)
    end
    if isSelectedSlot3 == 1 then
        --enterDIags(isOn,3)
        rpc.fixtureWirteRead(cmd,3)
    end
    if isSelectedSlot4 == 1 then
        rpc.fixtureWirteRead(cmd,4)
        --enterDIags(isOn,4)
    end


end

function DutSequence.dutSendClick (cmd,slotsSelected)
    local isSelectedSlot1 = slotsSelected['isSelectedSlot1']
    local isSelectedSlot2 = slotsSelected['isSelectedSlot2']
    local isSelectedSlot3 = slotsSelected['isSelectedSlot3']
    local isSelectedSlot4 = slotsSelected['isSelectedSlot4']
    if cmd == '' or cmd == nil then cmd = '\n' end
    -- ui.fixtureLog('cmd--'..cmd,1)
 
    -- ui.fixtureLog('isSelectedSlot1--'..isSelectedSlot1,1)
    -- ui.fixtureLog('isSelectedSlot2--'..isSelectedSlot2,2)
    -- ui.fixtureLog('isSelectedSlot3--'..isSelectedSlot3,3)
    -- ui.fixtureLog('isSelectedSlot4--'..isSelectedSlot4,1)
    if isSelectedSlot1 == 1 then
        -- ui.dutLog('isSelectedSlot1--'..isSelectedSlot1,1)   
        rpc.dutWirte(cmd,1)
        common.sleep(0.1)
    end
    if isSelectedSlot2 == 1 then
        -- ui.dutLog('isSelectedSlot2--'..isSelectedSlot2,2)
        rpc.dutWirte(cmd,2)
        common.sleep(0.1)
    end
    if isSelectedSlot3 == 1 then
        -- ui.dutLog('isSelectedSlot3--'..isSelectedSlot3,3)
        rpc.dutWirte(cmd,3)
        common.sleep(0.1)
    end
    if isSelectedSlot4 == 1 then
        ui.dutLog('isSelectedSlot4--'..isSelectedSlot4,4)
        rpc.dutWirte(cmd,4)
        common.sleep(0.1)
    end

end


return DutSequence
