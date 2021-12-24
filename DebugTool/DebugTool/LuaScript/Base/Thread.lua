

--Created by Suncode Louis.luo begin with DFU_DebugTool v0.5

local ui = require("LuaScript/Base/InterfaceView")
local common = require("LuaScript/Tech/Common")
local hwio = require("LuaScript/Tech/HWIO")
local rpc = require("LuaScript/Base/RPC")
local Thread = {}

local function CheckDutSensor(site)
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



-- 启动线程
function Thread.CheckDutSensorThread_run()
    -- print('99999999999')

    local t = ThreadPlugin(function ()

        while(1)
        do
            CheckDutSensor(1)

            CheckDutSensor(2)

            CheckDutSensor(3)

            CheckDutSensor(4)


        end

    end);

    dutSensorThread = t;

    t:run();


end



-- 结束线程
function Thread.DutSensorThread_stop()

    if dutSensorThread ~= nil then
        dutSensorThread:exit();
    end

end



-- 启动线程
function Thread.checkActionSensorThread_run()

    local t = ThreadPlugin(function ()
        local cmds = hwio.getCmds('get_fixture_status')
        local cmd = cmds[1]
        while(1)
        do
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

    end);

    actionSensorThread = t;

    t:run();


end



-- 结束线程
function Thread.ActionSensorThread_stop()

    if actionSensorThread ~= nil then
        actionSensorThread:exit();
    end

end



function DutRead (site)

    local result = rpc.fixtureWirteRead('uart_test.read()',site,false)
    if result==nil or result == '' then 
        --ui.dutLog('site:'..tostring(site)..'--read:null',site)
        return '' 
    end
    ui.dutLog(result,site)
    return result

end

-- 启动线程
function Thread.DutReadThread_run()

    local t = ThreadPlugin(function ()

        while(1)
        do
            rpc.dutRead(1)
            common.sleep(0.03)
            rpc.dutRead(2)
            common.sleep(0.03)
            rpc.dutRead(3)
            common.sleep(0.03)
            rpc.dutRead(4)
            common.sleep(0.03)
            -- DutRead(1)
            -- common.sleep(0.1)
            -- DutRead(2)
            -- common.sleep(0.1)
            -- DutRead(3)
            -- common.sleep(0.1)
            -- DutRead(4)
            -- common.sleep(0.1)

        end

    end);

    dutReadThread = t;

    t:run();


end



-- 结束线程
function Thread.DutReadThread_stop()

    if dutReadThread ~= nil then dutReadThread:exit(); end

end



local function loopTest (type,count,interval)
    local test_times = tonumber(count)
    local fixture_status_cmds = hwio.getCmds('get_fixture_status')
    local fixture_release_cmds = hwio.getCmds('fixture_release')
    local fixture_press_cmds = hwio.getCmds('fixture_press')
    -- print('count:'..count..'--interval:'..interval)
    if string.find(string.lower(type),'up&down') then
        local cmds1 = hwio.getCmds('up')
        local cmds2 = hwio.getCmds('down')

        rpc.sendCmds(fixture_press_cmds,1,nil,false)
        for i=1, test_times do
            while (1) do
                common.sleep(0.2)
                local status = rpc.sendCmds(fixture_status_cmds,1,nil,false)
                if string.find(status,'down') then
                    break
                end

            end
            rpc.sendCmds(cmds1,1)
            common.sleep(interval)
            while (1) do
                common.sleep(0.2)
                local status = rpc.sendCmds(fixture_status_cmds,1,nil,false)
                if string.find(status,'in') then
                    break
                end
            end 
            rpc.sendCmds(cmds2,1,nil,false)
            common.sleep(interval)
        end
    elseif string.find(string.lower(type),'in&out') then
        local cmds1 = hwio.getCmds('in')
        local cmds2 = hwio.getCmds('out')

        rpc.sendCmds(fixture_release_cmds,1,nil,false)
        for i=1, test_times do
            while (1) do
                common.sleep(0.2)
                local status = rpc.sendCmds(fixture_status_cmds,1,nil,false)
                if string.find(status,'out') then
                    break
                end

            end
            rpc.sendCmds(cmds1,1)
            common.sleep(interval)
            while (1) do
                common.sleep(0.2)
                local status = rpc.sendCmds(fixture_status_cmds,1,nil,false)
                if string.find(status,'in') then
                    break
                end
            end 
            rpc.sendCmds(cmds2,1,nil,false)
            common.sleep(interval)
        end

    elseif string.find(string.lower(type),'release&press') then
        rpc.sendCmds(fixture_release_cmds,1,nil,false)
        for i=1, test_times do
            while (1) do
                common.sleep(0.2)
                local status = rpc.sendCmds(fixture_status_cmds,1,nil,false)
                if string.find(status,'out') then
                    break
                end

            end
            rpc.sendCmds(fixture_press_cmds,1)
            common.sleep(interval)
            while (1) do
                common.sleep(0.2)
                local status = rpc.sendCmds(fixture_status_cmds,1,nil,false)
                if string.find(status,'down') then
                    break
                end
            end 
            rpc.sendCmds(fixture_release_cmds,1,nil,false)
            common.sleep(interval)
        end     
    end
end


-- 启动线程
function Thread.loopTestThread_run(type,count,interval)

    local t = ThreadPlugin(function ()

        loopTest (type,count,interval)

        -- while(1)
        -- do

        --     loopTest (type,count,interval)
            
        -- end

    end);

    loopTestThread = t;

    t:run();


end



-- 结束线程
function Thread.loopTestThread_stop()

    if loopTestThread ~= nil then loopTestThread:exit(); end

end




return Thread
