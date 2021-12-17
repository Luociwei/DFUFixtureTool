local function try(f, catch_f, ...)
    local status, exception = xpcall(f, debug.traceback, ...)
    if not status
    then
        catch_f(exception)
    end
end

local function truncateFailureMsg(failureMsg)
    return string.sub(failureMsg, 1, 510)
end

local function table_override(source, target, keys)
    -- early exit if source is nil
    if source == nil then return end
    -- loop over all keys and override source to target
    for _, keyName in ipairs(keys) do
        if source[keyName] ~= nil then
            target[keyName] = source[keyName]
        end
    end
end

local GSMConfiguration = require "GroupStateMachine/GSMConfiguration"

-- Main Module
local GSMCore = {}

-- Function Tables
local gsmFT = require "GroupStateMachine/GSMFunctionTable"
local groupFT = require "GroupStateMachine/GSMDefaultGroupFT"
local deviceFT = require "GroupStateMachine/GSMDefaultDeviceFT"
-- Plugin Tables
local groupPluginTable = {}
local devicePluginTable = {}
-- Internal GSM properties
local detectionTimeout = { 1, -1 }
local factoryAutomationEnabled = false
local resourcesEnabled = true

for k, v in pairs(GSMConfiguration) do
    if not string.match(k, "^__") then GSMCore[k] = v end
end

-- Initialize Group State Machine after the user provided values have been captured
local function groupStateMachineInit(groupArgumentsTable)
    GSMCore.groupArguments = groupArgumentsTable
    local registeredInfo = GSMConfiguration.__getConfiguration()
    table_override(registeredInfo[GSMConfiguration.__groupFunctionTableKey ], groupFT, {"setup", "getSlots", "start", "stop", "loopAgain", "groupShouldExit", "teardown"})
    table_override(registeredInfo[GSMConfiguration.__deviceFunctionTableKey], deviceFT, {"setup", "scheduleDAG", "scheduleFinalDAG", "teardown"})

    if registeredInfo[GSMConfiguration.__detectionTimeoutKey] then
        detectionTimeout = registeredInfo[GSMConfiguration.__detectionTimeoutKey]
    end
    if registeredInfo[GSMConfiguration.__enableFactoryAutomationKey] then
        factoryAutomationEnabled = true
    end
    if registeredInfo[GSMConfiguration.__disabledResourcesKey] then
        resourcesEnabled = false
    end
end

local function groupStateMachineTestMainPerDetection(slots)
    print ("GroupStateMachine : DeviceSetup")
    local devicePluginTable, mergedPluginTable = gsmFT.deviceSetup(deviceFT, groupPluginTable, slots)

    print ("GroupStateMachine : GroupStart")
    gsmFT.groupStart(groupFT, groupPluginTable)

    print ("GroupStateMachine : ExecuteTest")
    gsmFT.executeTest(deviceFT, mergedPluginTable)

    print ("GroupStateMachine : GroupStop")
    gsmFT.groupStop(groupFT, groupPluginTable)

    print ("GroupStateMachine : DeviceTeardown")
    local devicePluginTable = gsmFT.deviceTeardown(deviceFT, devicePluginTable, groupPluginTable)

    return true
end

local function groupStateMachineTestMain()
    print ("GroupStateMachine : GetSlots")
    local slots = gsmFT.groupGetSlots(groupFT, groupPluginTable, detectionTimeout)

    repeat
        try(groupStateMachineTestMainPerDetection,
        function (err)
            print("Software error was caught: " .. err)
            for _,device in ipairs(Group.allDevices()) do
                print(device .. ": Failing for software exception : " .. err)
                Group.failDevice(device, truncateFailureMsg(err))
                Group.stopDevice(device)
            end
        end,
        slots)
    until not gsmFT.loopAgain(groupFT, groupPluginTable)

    print ("GroupStateMachine : loops per detection done")
    return true
end

local function groupStateMachineMainPerSetup(...)
    print ("GroupStateMachine : Init")
    groupStateMachineInit({...})

    print ("GroupStateMachine : GroupSetup")
    groupPluginTable = gsmFT.groupSetup(groupFT, factoryAutomationEnabled, resourcesEnabled)

    print("GroupStateMachine : TestLoopStart")
    repeat
        try(groupStateMachineTestMain,
        function (err)
            print("GroupStateMachine : error was caught : " .. err)
        end)
    until gsmFT.groupShouldExit(groupFT, groupPluginTable)

    print ("GroupStateMachine : GroupTeardown")
    gsmFT.groupTeardown(groupFT, groupPluginTable)
end

GSMCore.groupStateMachineMain = function (...)
    try(function (...)
        groupStateMachineMainPerSetup(...)
    end,
    function (err)
        print("Exiting Group State Machine : error = " .. err)
    end, ...)
end

local readonlyTable = { main = GSMCore.groupStateMachineMain, GSM = GSMCore, GSMInternal = gsmFT }

setmetatable(_G, {
    __index=readonlyTable,
    __newindex= function (tab, name, value)
        if rawget(readonlyTable, name) then
            error(name ..' is a read only variable', 2)
        end
        rawset(tab, name, value)
    end
})
