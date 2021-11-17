
local SequenceControl = {}
local rpc = require("LuaScript/Base/RPC")
local ui = require("LuaScript/Base/InterfaceView")
local thread = require("LuaScript/Base/Thread")
local hwio = require("LuaScript/Tech/HWIO")
local common = require("LuaScript/Tech/Common")
local fixutre = require("LuaScript/Tech/FixtureSequence")
local dut = require("LuaScript/Tech/DutSequence")

function loadPulgins()
-- body

    local isPingOk = ui.pingIP('169.254.1.32')
    if isPingOk == false then
        ui.alert("Error","ping 169.254.1.32 failed!!! Pls check the mix is ready?")

        return nil
    end
    local ipPorts = hwio.ipPorts()
    local rpc = RPCPlugin:rpcPluginConnect(ipPorts)
    if rpc == nil then
        ui.alert("Error","RPC Connect fail!!!")
        
        return nil
    end
    ui.alert("Warning","RPC Connect successful.")
    -- local rpc = ''
    
    local Device = {}--- registered getDeviceInfo() method
    local interfaceView = InterfaceViewPlugin()
    Device['InterfaceViewPlugin'] = interfaceView
    Device['RPCPlugin'] = rpc

    return Device


end


local function regular (content, pattern)
    ---ss

    local all_methods_arr = {}
    for w in string.gmatch(content,pattern) do
        
        local Module = string.match(w,'"([%w_.]+)"%s*=%s*%(')
        for Doc,Function in string.gmatch(w,'doc%s*=%s*(.-);%s*name%s*=%s*(.-);') do
        local method_table = {}
            if Doc == nil then Doc = '' end
            if Function == nil then Function = '' end
            method_table.Module = Module
            method_table.Doc = Doc
            method_table.Function = Function
            table.insert(all_methods_arr,method_table)

        end

    end

    -- ui.fixtureLog('all_methods_arr count:'..#all_methods_arr..'--method[8]-doc:'..all_methods_arr[8]['Doc']..'--method[8]-Function:'..all_methods_arr[8]['Function'])

    return all_methods_arr

end

local function getAllMethods ()
    local all_monthed_cmd = 'server.all_methods()'
    local result_all_monthed = rpc.fixtureWirteRead(all_monthed_cmd,1,false)
    -- local result_all_monthed = ''
    if result_all_monthed == nil or result_all_monthed == '' then
        local resource_path = ui.appResourcePath()
    -- local path1 = '/Users/ciweiluo/Desktop/all_method.txt'
        local path = resource_path..'/LuaScript/all_method.txt'
        -- print(path2)
        result_all_monthed = common.readFile(path)

    end
    
   return regular(result_all_monthed,'"[%w_.]+"%s*=%s*%(%s+%{.-%);')
   
end

function appDidFinishLaunched()
-- body
    -- print('0000000000')
    rpc.uartOpen()

    thread.DutReadThread_stop()
    thread.DutSensorThread_stop()
    thread.loopTestThread_stop()
    -- thread.CheckDutSensorThread_run()
    -- thread.DutReadThread_run()
    fixutre.CheckSensor ()

    return getAllMethods ()

end

function appWillBeClose()
-- body
    print('APP will be closed!!!')
    thread.DutReadThread_stop()
    thread.DutSensorThread_stop()
    thread.loopTestThread_stop()
    --dut.fixture_resetAll ()
    --rpc.uartClose()
    --rpc.shutdown_all ()
-- uart_SoC.shutdown_all()
    --ui.alert("Warning","APP will be close!!")
end


function actionClick (action)
-- body

    fixutre.actionClick (action)

end


function mixFwUpdate (btnTitle,fwPath)
-- body

    fixutre.mixFwUpdate (btnTitle,fwPath)

end


function fixtureSnWriteOrReadClick (btnTitle,sn)
-- body
    fixutre.snWriteOrReadClick (btnTitle,sn)

end


function loopClick (title,type,count,interval)
    fixutre.loopClick (title,type,count,interval)
end

function ledClick (channel, color)
    -- body

    fixutre.ledClick (channel, color)

end



function fanClick (btnTitle,channel,speed)
-- body
    fixutre.fanClick (btnTitle,channel,speed)

end




function resetClick (slotsSelected)
    
    dut.resetClick (slotsSelected)

end




function scriptRun (scriptName,slotsSelected)


    dut.scriptRun (scriptName,slotsSelected)
    
end



function forceDFUClick (isOn,slotsSelected)

    dut.forceDFUClick (isOn,slotsSelected)


end



function enterDIagsClick (isOn,slotsSelected)

    dut.enterDIagsClick (isOn,slotsSelected)


end

function fixtureSendClick (cmd,slotsSelected)

    dut.fixtureSendClick (cmd,slotsSelected)
    
end

function dutSendClick (cmd,slotsSelected)
    dut.dutSendClick (cmd,slotsSelected)

end


return SequenceControl
