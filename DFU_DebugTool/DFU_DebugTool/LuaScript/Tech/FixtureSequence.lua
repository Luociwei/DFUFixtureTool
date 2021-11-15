
local FixtureSequence = {}
local rpc = require("LuaScript/Base/RPC")
local ui = require("LuaScript/Base/InterfaceView")
local hwio = require("LuaScript/Tech/HWIO")
local common = require("LuaScript/Tech/Common")
local thread = require("LuaScript/Base/Thread")


local function setFixtureActionStautsLedLight ()

    local cmds = hwio.getCmds('get_fixture_status')
    local cmd = cmds[1]

    local reply = rpc.fixtureWirteRead(cmd,1,false)
            -- local reply = 'in'
    if string.find(reply,'in') then
        ui.setFixtureActionStautsLedLight(1,'in')
        ui.setFixtureActionStautsLedLight(1,'up')
        ui.setFixtureActionStautsLedLight(0,'out')
        ui.setFixtureActionStautsLedLight(0,'down')
    elseif string.find(reply,'out') then
        ui.setFixtureActionStautsLedLight(1,'out')
        ui.setFixtureActionStautsLedLight(1,'up')
        ui.setFixtureActionStautsLedLight(0,'in')
        ui.setFixtureActionStautsLedLight(0,'down')

    elseif string.find(reply,'down') then
        ui.setFixtureActionStautsLedLight(1,'in')
        ui.setFixtureActionStautsLedLight(1,'down')
        ui.setFixtureActionStautsLedLight(0,'out')
        ui.setFixtureActionStautsLedLight(0,'up')

    else
        ui.setFixtureActionStautsLedLight(1,'in')
        ui.setFixtureActionStautsLedLight(0,'up')
        ui.setFixtureActionStautsLedLight(0,'out')
        ui.setFixtureActionStautsLedLight(0,'down')
    end


end

            
local function CheckDutSensor1(site)
    -- local sensor_slot = true
    -- local sensor_slot = rpc:isBoardDetected(site)

    local sensor_slot = rpc.isBoardDetected(site,false)
   
    if sensor_slot then
        local isPingOk = true
        -- local isPingOk = ui.pingIP('169.254.1.32')
        
        if isPingOk then 
            ui.setDutStautsLedLight(1,site)
        else
            ui.setDutStautsLedLight(0,site)
        end

    else
        ui.setDutStautsLedLight(0,site)
    end 
    common.sleep(0.3)

end

function FixtureSequence.CheckSensor ()
    setFixtureActionStautsLedLight ()
    CheckDutSensor1(1)
    CheckDutSensor1(2)
    CheckDutSensor1(3)
    CheckDutSensor1(4)

end
        

function FixtureSequence.actionClick (action)
-- body

   
    print('btn_title:'..action..'--')
    -- if rpc.object() == nil then
    --     ui.alert("Error","RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication.")
    --     return info
    -- end
    local key = string.lower(action)
    -- ui.fixtureLog('send_cmd:'..key,1)
    local isPrintDutLog = false
    if key == 'fixture_press' or key == 'fixture_release' then
        isPrintDutLog = true
        FixtureSequence.CheckSensor ()

    end

    
    if key == 'check sensor' then
        FixtureSequence.CheckSensor ()
        return ''
    end

    
    local cmds = hwio.getCmds(key)
    local result_str = ''
    for i=1, #cmds do 
        local cmd = cmds[i]
        ui.fixtureLog('send_cmd:'..cmd)
        local result_str = rpc.fixtureWirteRead(cmd,1,isPrintDutLog)
        ui.fixtureLog('result:'..result_str)

    end
    FixtureSequence.CheckSensor ()

    return result_str

end

function FixtureSequence.snWriteOrReadClick (btnTitle,sn)
-- body
    local result_str = 'btnTitle:'..btnTitle..'--sn:'..sn
    -- if rpc.object() == nil then
    --     ui.alert("Error","RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication.")
    --     return result_str
    -- end


    ui.fixtureLog(result_str)

    local key = 'fixtureSn_write'

    if string.lower(btnTitle) == 'write' then
        if sn==nil or #sn ~= 19 then
            ui.alert("Error","Pls check sn length!")
        --return ''
        end

        key = 'fixtureSn_write'

    elseif string.lower(btnTitle) == 'read' then

        key = 'fixtureSn_read'

    end

    local cmds = hwio.getCmds(key)

    
    -- for i=1, #cmds do 
    --     local cmd = cmds[i]
    --     if string.find(cmd,'%?') then cmd = string.gsub(cmd,"%?", sn) end
    --     ui.fixtureLog('send_cmd:'..cmd)
    --     local result_str = rpc.fixtureWirteRead(cmd,1)
    --     ui.fixtureLog('result:'..result_str)

    -- end

    rpc.fixtureSendCmds(cmds,1,sn)



    return result_str

end



function FixtureSequence.loopClick (btn_title,type,count,interval)
    if string.find(string.lower(btn_title),'loop in') then
        thread.loopTestThread_run(type,count,interval)

    elseif string.find(string.lower(btn_title),'loop out') then
        thread.loopTestThread_stop()
        
    end
    
end

function FixtureSequence.ledClick (channel, color)
    -- body
    local result_str = 'channel:'..channel..'--color:'..color
    -- if rpc.object() == nil then
    --     ui.alert("Error","RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication.")
    --     return result_str
    -- end

    ui.fixtureLog(result_str)
    if string.lower(channel) == 'all' then
        for i=1, 5 do
            local site = i
            local channel_str = 'uut'..i
            if i == 5 then
                site = 1
                channel_str = 'power'
            end

            local key = channel_str..'_led_'..string.lower(color)
            local cmds = hwio.getCmds(key) 
            rpc.fixtureSendCmds(cmds,site)

        end
    else

        local site = rpc.getSite (channel)
        local key = string.lower(channel)..'_led_'..string.lower(color)
        local cmds = hwio.getCmds(key)
    
        rpc.fixtureSendCmds(cmds,site)

    end



    return result_str

end


local function getFanSpeed(btnTitle,channel,speed)

    local result_str = 'btnTitle:'..btnTitle..'--channel:'..channel..'--speed:'..speed

    local cmds = hwio.getCmds('get_fan_speed')

    local site = rpc.getSite (channel)

    if string.lower(channel) == 'all' then 
        index_frist = 1
        index_end = 4
    end
    for i=index_frist, index_end do

        rpc.fixtureSendCmds(cmds,i,tostring(speed))

    end
    return result_str
end

local function setFanSpeed(btnTitle,channel,speed)
-- body

    local result_str = 'btnTitle:'..btnTitle..'--channel:'..channel..'--speed:'..speed
    ui.fixtureLog(result_str..type(speed))
    local cmds = hwio.getCmds('set_fan_speed')
    local sc_fan_speed = 100 - speed
    local site = rpc.getSite (channel)
    local index_frist = site
    local index_end = site
    if string.lower(channel) == 'all' then 
         index_frist = 1
         index_end = 4
     end
    -- ui.fixtureLog(cmds[1])

    if tonumber(speed) == 0 then
        for j =index_frist,index_end do
            -- ui.fixtureLog('site:'..j..'--send_cmd:'..cmds[j])
            rpc.fixtureWirteRead("io.set(bit29=0)",j)
            -- ui.fixtureLog('site:'..site..'result:'..result)
        end
    else

        for i=index_frist, index_end do

            rpc.fixtureSendCmds(cmds,i,tostring(sc_fan_speed))

        end

    end

    return result_str

end


local function is_fan_ok(btnTitle,channel,speed)
-- body
    setFanSpeed(btnTitle,channel,speed)
    getFanSpeed(btnTitle,channel,speed)
    setFanSpeed(btnTitle,channel,0)

end



function FixtureSequence.fanClick (btnTitle,channel,speed)
-- body
    local result_str = 'btnTitle:'..btnTitle..'--channel:'..channel..'--speed:'..speed
    -- ui.fixtureLog('result_str'..result_str)

    -- if rpc.object() == nil then
    --     ui.alert("Error","RPC is not connected!!! Pls click top left button to connect RPC communication. Pls click top left button to connect RPC communication.")
    --     return result_str
    -- end


    if string.find(string.lower(btnTitle),'set') then
        setFanSpeed(btnTitle,channel,speed)
    elseif string.find(string.lower(btnTitle),'get') then
        getFanSpeed(btnTitle,channel,speed)
        ui.fixtureLog(result_str)
    elseif string.find(string.lower(btnTitle),'is fan ok') then
        -- ui.fixtureLog('result_str'..result_str)
    else
        
    end

end

function FixtureSequence.mixFwUpdate (fwPath,btnTitle)
-- body
    
    local result_str = 'btnTitle:'..btnTitle..'--fwPath:'..fwPath..'--end'
    -- ui.fixtureLog('result_str--'..result_str)
    local scriptPath = ui.luaScriptPath()

    if string.find(string.lower(btnTitle),'read ver') then
        local mix_check_file = scriptPath..'/MixFw/fwdl_mix_check.exp'
        print('mix_check_file--'..mix_check_file)
        local reply = ui.runShellCmd(mix_check_file..' 169.254.1.32')
        ui.fixtureLog(reply)    
        
    elseif string.find(string.lower(btnTitle),'upgrade') then
        if fwPath == nil or fwPath == '' or string.find(fwPath,'tgz') == nil  then
            ui.fixtureLog('fw path is wrong format!!!') 
            return '' 
        end
        local mix_update_file = scriptPath..'/MixFw/fw_update.exp'
        local reply1 = ui.runShellCmd(mix_update_file..' '..fwPath..' 169.254.1.32')
        ui.fixtureLog(reply1)
        local mix_reboot_file = scriptPath..'/MixFw/reboot.exp'
        local reply2 = ui.runShellCmd(mix_reboot_file..' 169.254.1.32')
        ui.fixtureLog(reply2)
        ui.fixtureLog('update mix fw need ten more minutes to sucessful!!! pls wait...')

    else

        local mix_check_file = scriptPath..'/MixFw/fwdl_mix_check.exp'
        print('mix_check_file--'..mix_check_file)
        local reply3 = ui.runShellCmd(mix_check_file..' 169.254.1.32')
        ui.fixtureLog(reply3)
        -- if fwPath == nil or fwPath == '' then return '' end
        -- local mix_update_file = scriptPath..'/MixFw/fw_update.exp'
        -- local reply1 = ui.runShellCmd(mix_update_file..' '..fwPath..' 169.254.1.32')
        -- ui.fixtureLog(reply1)
        -- local mix_reboot_file = scriptPath..'/MixFw/reboot.exp'
        -- local reply2 = ui.runShellCmd(mix_reboot_file..' 169.254.1.32')
        -- ui.fixtureLog(reply1)
        
    end

end


return FixtureSequence
