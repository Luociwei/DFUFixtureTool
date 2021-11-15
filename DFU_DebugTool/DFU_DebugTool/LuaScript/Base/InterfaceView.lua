--Created by Suncode Louis.luo begin with DFU_DebugTool v0.5
-- UI Control
--[[
    registered method from TestPlatform:
    
    InterfaceViewPlugin:appResourcePath ()
    InterfaceViewPlugin:runShellCmd(cmd)
    InterfaceViewPlugin:popupAlert(title,info)

    ui = getDeviceInfo()['InterfaceViewPlugin']
    ui:printFixtureLog(log,slot)
    ui:setDutStautsLedLight(isLight,channel)
    ui:printDutLog(log,slot)
    ui:setFixtureActionStautsLedLight(isLight,status)

]]
local InterfaceView = {}

-----类方法------
function InterfaceView.appResourcePath ()
    --local ui = InterfaceView.object()
    local resourcePath = InterfaceViewPlugin:appResourcePath ()
    return resourcePath

end

function InterfaceView.runShellCmd (cmd)
    
    local reply = InterfaceViewPlugin:runShellCmd(cmd)
    return reply

end


function InterfaceView.pingIP( ip )
    local pingCmd = "ping " .. ip .. " -c 1 -t 1"
    local reply = InterfaceView.runShellCmd(pingCmd)--
    print('reply--'..reply..'----end')
    if string.find(reply,'100.0%% packet loss') then
        return false
    else
        return true
    end
    
end

function InterfaceView.luaScriptPath ()

    local resourcePath = InterfaceView.appResourcePath ()
    print('resourcePath'..resourcePath)
    local luaScriptPath = resourcePath..'/LuaScript'
    return luaScriptPath

end

--弹框
function InterfaceView.alert (title, info)
    if title == nil then title = 'Wraning' end
    if info == nil then info = '' end

    InterfaceViewPlugin:popupAlert(title,info)

end

-----对象方法------register in appLaunchAndLoadPlugins first

function InterfaceView.object()

    local Device = getDeviceInfo();
    local ui = Device['InterfaceViewPlugin'];
    return ui

end

function InterfaceView.fixtureLog(log,slot)
    print(log)
    if slot == nil then slot = 0 end ---fixture interface view test log
    if log == nil then return nil end
    local ui = InterfaceView.object()
    ui:printFixtureLog(log,slot)

end

function InterfaceView.dutLog(log,slot)
    if slot == nil then slot = 0 end -----fixture interface view test log
    if log == nil then return nil end
    local ui = InterfaceView.object()
    ui:printDutLog(log,slot)

end

function InterfaceView.setDutStautsLedLight(isLight,channel)

    local ui = InterfaceView.object()
    ui:setDutStautsLedLight(isLight,channel)

end


function InterfaceView.setFixtureActionStautsLedLight(isLight,status)

    local ui = InterfaceView.object()
    ui:setFixtureActionStautsLedLight(isLight,status)

end

function InterfaceView.setFixtureRunningTime(time)

    local ui = InterfaceView.object()
    ui:setFixtureRunningTime(time)

end



return InterfaceView

