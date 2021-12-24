--Created by Suncode Louis.luo begin with DFU_DebugTool v0.5
--[[
    registered method from TestPlatform:
    getDeviceInfo()
    rpc:fxitureWriteAndRead(cmd,site)
    rpc:dutWirte(cmd,site)
    rpc:dutWrite(cmd,site)

]]
--UART Communication
local hwio = require("LuaScript/Tech/HWIO")
local ui = require("LuaScript/Base/InterfaceView")

local RPC = {}

function RPC.object()

    local Device = getDeviceInfo()  
    local rpc = Device['RPCPlugin'];

    return rpc
end


function RPC.isConnect()

    if rpc.object() == nil then
        ui.alert("Error","RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication.")
        return true
    else
        return false
    end

end
function RPC.fixtureWirteRead (cmd, site , is_log)

    local rpc = RPC.object();
    if is_log == nil or is_log == true then ui.fixtureLog('site:'..tostring(site)..'--send_cmd:'..cmd,site) end
    
    local result = rpc:fxitureWriteAndRead(cmd,site)

    if is_log == nil or is_log == true then

        if string.match(cmd,'read_volt%(CH') then--([%d%.]+) mv ACK%(DONE%)
            local vol_str = string.match(result,'([%d%.]+) mv ACK%(DONE%)')
            print('debug--'..cmd)
            local vol = (tonumber(vol_str)+2)*1.5
            local name = ""
            if string.match(cmd,'read_volt%(CH0') then
                name = 'vbatt'
            elseif  string.match(cmd,'read_volt%(CH1') then
                name = 'vbus'
            elseif  string.match(cmd,'read_volt%(CH2') then
                name = 'vcc_main'
            elseif  string.match(cmd,'read_volt%(CH6') then
                name = 'vcc_high'
            end
            result = name..':'..tostring(vol)
      
        end
        ui.fixtureLog('result:'..result,site) 
    end
    
    return result

end


function RPC.sendCmds (cmds,site,gubStr,isPrintLog)
    -- body

    -- if RPC.object() == nil then
    --     ui.alert("Error","RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication.")
    -- end
    
    --ui.fixtureLog('send_cmd:'..cmds[1],site)

    local result_str = ''
    for i=1, #cmds do 
        local cmd = cmds[i]
        --ui.fixtureLog('send_cmd:'..cmd,site)
        if string.find(cmd,'%?') and gubStr ~=nil then cmd = string.gsub(cmd,"%?", gubStr) end
        -- ui.fixtureLog('send_cmd:'..cmd,site)
        local result = RPC.fixtureWirteRead(cmd,site,isPrintLog)
        result_str = result_str..result
        -- ui.fixtureLog('result:'..result,site)

    end

    return result_str

end

function RPC.fixtureSendCmds (cmds,site,gubStr)
    -- body

    -- if RPC.object() == nil then
    --     ui.alert("Error","RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication.")
    -- end
    
    --ui.fixtureLog('send_cmd:'..cmds[1],site)
    
    local result_str = ''
    for i=1, #cmds do 
        local cmd = cmds[i]
        --ui.fixtureLog('send_cmd:'..cmd,site)
        if string.find(cmd,'%?') and gubStr ~=nil then cmd = string.gsub(cmd,"%?", gubStr) end
        ui.fixtureLog('site:'..tostring(site)..'--send_cmd:'..cmd)
        local result = RPC.fixtureWirteRead(cmd,site,false)
        result_str = result_str..result
        ui.fixtureLog('site:'..tostring(site)..'result:'..result)

    end

    return result_str

end




function RPC.isBoardDetected(site,is_log)
    
    -- local rpc = RPC.object();
    -- if rpc == nil then 
    --     ui.fixtureLog(site,'Board is not Detected...')
    --     return false 
    -- end
    -- local result = rpc:isBoardDetected(site)
    
    local cmds = hwio.getCmds('is_board_detected') 
    local cmd = cmds[1]

    local result = RPC.fixtureWirteRead (cmd, site ,is_log)
    if tonumber(result) == 0 then
        return true
    else
        return false
    end

    -- return result

end


function RPC.dutWirte (cmd, site)


    -- local rpc = RPC.object();
    local isBoardDetected = RPC.isBoardDetected(site,false)
    -- ui.fixtureLog('dutWirte---',site)
    if isBoardDetected == false then
        ui.dutLog('checked the board is not detected. so command was refused!!!',site)
        return ''
    end
    if cmd == nil then
        cmd = ''
    else
        ui.dutLog(cmd,site)
    end
    -- local rpc = RPC.object();
    -- local result = rpc:fxitureWriteAndRead(cmd,site)

    local dut_cmd = 'uart_test.write('..cmd..'\r)'
    local result = RPC.fixtureWirteRead(dut_cmd, site , false)
    -- local result = rpc:fxitureWriteAndRead(dut_cmd,site)
    return result

end


function RPC.dutRead1 (site)

    --ui.dutLog('site:'..site..'--read:'..'testa2222f8ssdfjtytacgggg',site)
    local rpc = RPC.object();
    local result = rpc:dutRead(site)
    if result==nil or result == '' then return '' end
    ui.dutLog(result,site)
    return result

end
function RPC.dutRead (site)

    local result = RPC.fixtureWirteRead('uart_test.read()',site,false)
    if result==nil or result == '' then 
        --ui.dutLog('site:'..tostring(site)..'--read:null',site)
        return '' 
    end
    ui.dutLog(result,site)
    return result

end





function RPC.getSite (channel_str)
    local site = 0 
    local channel = string.lower(channel_str)
    -- local site = string.match(channel,'uut(%d)') 
    if channel == 'uut1' or channel == 'power' then
        site = 1
    elseif channel == 'uut2' then
        site = 2
    elseif channel == 'uut3' then
        site = 3
    elseif channel == 'uut4' then
        site = 4
        
    end

    return site

end

function RPC.uartOpen ()
    RPC.fixtureWirteRead('uart.open()',1)
    RPC.fixtureWirteRead('uart.open()',2)
    RPC.fixtureWirteRead('uart.open()',3)
    RPC.fixtureWirteRead('uart.open()',4)
end

function RPC.uartClose ()
    RPC.fixtureWirteRead('uart.close()',1)
    RPC.fixtureWirteRead('uart.close()',2)
    RPC.fixtureWirteRead('uart.close()',3)
    RPC.fixtureWirteRead('uart.close()',4)
end

function RPC.shutdown_all ()
-- body
--uart_SoC.shutdown_all()
    local rpc = RPC.object();
    rpc:shutdownAll()

end

-- function RPC.sendCmdsAndGubStr (site,cmds,gubStr)
--     -- body
--     if gubStr == nil then 
--         return RPC.sendCmds (site,cmds)
--     end

--     if RPC.object() == nil then
--         ui.alert("Error","RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication.")
--     end
    
--     for i=1, #cmds do 
--         local cmd = cmds[i]
--         if string.find(cmd,'%?') then cmd = string.gsub(cmd,"%?", gubStr) end
--         ui.fixtureLog('send_cmd:'..cmd)
--         local result_str = RPC.fixtureWirteRead(cmd,site)
--         ui.fixtureLog('result:'..result_str)

--     end

--     return result_str

-- end

return RPC
