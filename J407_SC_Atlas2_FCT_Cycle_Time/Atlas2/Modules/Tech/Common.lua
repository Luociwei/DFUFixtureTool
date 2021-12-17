Common = {}
local Log = require("Matchbox/logging")
local dutCmd = require("Tech/DUTCmd")
local fixture = require("Tech/Fixture")
local powersupply = require("Tech/PowerSupply")
local comFunc = require("Matchbox/CommonFunc")
local Record = require 'Matchbox/record'
local dockchannel = require("Tech/DockChannel")
local orion = require("Tech/Orion")
local dmm = require("Tech/Dmm")
local relay = require("Tech/Relay")
local battcharger = require("Tech/BatteryCharger")
local eload = require("Tech/Eload")
local flow_log = require("Tech/WriteLog")


function Common.dataReportSetup(param)
    local interactiveView = Device.getPlugin("InteractiveView")
    local status,data = xpcall(interactiveView.getData,debug.traceback,Device.systemIndex)
    local sn = data --tostring(param.Input)
    Log.LogInfo("$$$$$ dataReportSetup sn " .. tostring(sn))
    if sn and #sn >0 then
        Log.LogInfo("Unit serial number: ".. sn)
        DataReporting.primaryIdentity(sn)
        -- DataReporting.limitsVersion("v25.4.0.1_DOE")
        Log.LogInfo("Station reporter is ready.")
    end
end


function Common.addLogToInsight(param)
    Log.LogInfo('adding user/ log folder to insight')
    local slot_num = tonumber(Device.identifier:sub(-1))
    Archive.addPathName(Device.userDirectory, Archive.when.endOfTest)
end


function Common.delay(param)
    local testname = param.AdditionalParameters.testname or param.Technology
    local subtestname = param.AdditionalParameters.subtestname or param.TestName
    local subsubtestname = param.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(param)
    os.execute('sleep ' .. ( tonumber(param.AdditionalParameters.delay)/1000) )
    if param.AdditionalParameters.record ==nil or param.AdditionalParameters.record == "YES" then
        Record.createBinaryRecord(true, testname, subtestname, subsubtestname)
    end
    flow_log.writeFlowLimitAndResult(param,"True")
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
end


function Common.getSNFromInteractiveView(param)
    local interactiveView = Device.getPlugin("InteractiveView")
    local status,data = xpcall(interactiveView.getData,debug.traceback,Device.systemIndex)
    Log.LogInfo("$$$$$ getSNFromInteractiveView" .. data)
    if not status then
        data = "no scanned sn"
    end
    return data
end


function Common.relay_switch( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = relay.relay_switch(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end


function Common.power_supply( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = powersupply.power_supply(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end

function Common.read_voltage( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dmm.read_voltage(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end



function Common.frequence( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dmm.frequence(paraTab)
    
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end

function Common.readbattcurr( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dmm.readbattcurr(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end

function Common.frequence_high( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dmm.frequence_high(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end

function Common.read_gpio( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = fixture.read_gpio(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end



function Common.sendFixtureCmd( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = fixture.sendCmd(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end


function Common.dockconfig_writeRead( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dockchannel.writeRead(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end

function Common.dockport_waitDFU( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dockchannel.waitDFU(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end

function Common.dockport_writeRead( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret =  dockchannel.dp_writeRead(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end

function Common.dockport_diagsParse( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret =  dockchannel.dp_writeRead(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret

end

function Common.dockport_parse( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret =  dockchannel.dp_parse(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end

function Common.dockport_diagsParseBit( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret =  dockchannel.dp_writeReadBit(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end

function Common.dockport_diagsParseGetBit( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dockchannel.dp_writeReadtBitHex(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end

function Common.dockport_diagsParseBit2Hex( paraTab )

    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dockchannel.dp_writeReadtBitHex(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret

end


function Common.dut_diagsParse( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dutCmd.dut_writeRead(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret

end

function Common.dut_parse( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dutCmd.dut_parse(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret

end

function Common.dut_sendString( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dutCmd.dut_sendString(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret

end

function Common.dut_detect_Hibernation( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dutCmd.dut_detect_Hibernation(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret

end


function Common.gpio_state( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dmm.gpio_state(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end


function Common.set_ad8253_gain( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = relay.set_ad8253_gain(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret

end

---------------------------eload--------
function Common.read_eload_current( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = eload.read_eload_current(paraTab)

    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end

function Common.setEload( paraTab ) ---set_ccload
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = eload.setEload(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret
end

function Common.vbus_check( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname

    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dmm.vbus_check(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret

end

function Common.vbus_fb_connect( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname

    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLogStart(paraTab)
    local ret = dmm.vbus_fb_connect(paraTab)
    Timer.tock(testname.." "..subtestname.." "..subsubtestname)
    flow_log.writeFlowLimitAndResult(paraTab,ret)
    return ret

end

function Common.sendVDMCmd( paraTab )
    local testname = paraTab.AdditionalParameters.testname or paraTab.Technology
    local subtestname = paraTab.AdditionalParameters.subtestname or paraTab.TestName
    local subsubtestname = paraTab.AdditionalParameters.subsubtestname
    Timer.tick(testname.." "..subtestname.." "..subsubtestname)
    fixture.sendVDMCmd( paraTab )
    Timer.tock(testname.." "..subtestname.." "..subsubtestname) 
end

return Common

