-- Framework Detection
local Framework = nil
local FrameworkType = nil

function echoGetFramework()
    if ECHO.Framework ~= "auto" then
        FrameworkType = ECHO.Framework
    else
        if GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started' then
            FrameworkType = 'qbcore'
        elseif GetResourceState('es_extended') == 'started' then
            FrameworkType = 'esx'
        else
            FrameworkType = 'custom'
        end
    end
    
    if FrameworkType == 'qbcore' then
        Framework = exports['qb-core']:GetCoreObject()
    elseif FrameworkType == 'esx' then
        Framework = exports['es_extended']:getSharedObject()
    end
    
    print('^2[ECHO Health System]^7 Framework detected: ^3' .. FrameworkType .. '^7')
    return Framework
end

-- Initialize Framework
CreateThread(function()
    echoGetFramework()
end)

-- Unified Player Identifier
function echoGetIdentifier(source)
    if FrameworkType == 'qbcore' then
        local Player = Framework.Functions.GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    elseif FrameworkType == 'esx' then
        local Player = Framework.GetPlayerFromId(source)
        return Player and Player.identifier or nil
    else
        return GetPlayerIdentifierByType(source, 'license') or nil
    end
end

-- Unified Player Object
function echoGetPlayer(source)
    if FrameworkType == 'qbcore' then
        return Framework.Functions.GetPlayer(source)
    elseif FrameworkType == 'esx' then
        return Framework.GetPlayerFromId(source)
    else
        return { source = source, identifier = echoGetIdentifier(source) }
    end
end

-- Unified Money Management
function echoAddMoney(source, amount, type)
    local Player = echoGetPlayer(source)
    if not Player then return false end
    
    if FrameworkType == 'qbcore' then
        return Player.Functions.AddMoney(type or 'cash', amount)
    elseif FrameworkType == 'esx' then
        Player.addMoney(amount)
        return true
    else
        TriggerClientEvent('echo:notify', source, 'Received $' .. amount, 'success')
        return true
    end
end

function echoRemoveMoney(source, amount, type)
    local Player = echoGetPlayer(source)
    if not Player then return false end
    
    if FrameworkType == 'qbcore' then
        return Player.Functions.RemoveMoney(type or 'cash', amount)
    elseif FrameworkType == 'esx' then
        Player.removeMoney(amount)
        return true
    else
        TriggerClientEvent('echo:notify', source, 'Paid $' .. amount, 'error')
        return true
    end
end

function echoGetMoney(source, type)
    local Player = echoGetPlayer(source)
    if not Player then return 0 end
    
    if FrameworkType == 'qbcore' then
        return Player.PlayerData.money[type or 'cash'] or 0
    elseif FrameworkType == 'esx' then
        return Player.getMoney()
    else
        return 10000 -- Default for custom
    end
end

-- Unified Notifications
function echoNotify(source, message, type, duration)
    if ECHO.Notifications.Type == 'qb' and FrameworkType == 'qbcore' then
        TriggerClientEvent('QBCore:Notify', source, message, type, duration)
    elseif ECHO.Notifications.Type == 'esx' and FrameworkType == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message)
    elseif ECHO.Notifications.Type == 'ox' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Health System',
            description = message,
            type = type
        })
    else
        TriggerClientEvent('echo:notify', source, message, type, duration)
    end
end

-- Initialize Player Health Data
RegisterNetEvent('echo:server:initializePlayer', function()
    local src = source
    local identifier = echoGetIdentifier(src)
    
    if not identifier then return end
    
    MySQL.query('SELECT * FROM echo_health_data WHERE identifier = ?', {identifier}, function(result)
        if not result or #result == 0 then
            local bloodTypes = ECHO.Organs.BloodTypes
            local randomBlood = bloodTypes[math.random(#bloodTypes)]
            
            MySQL.insert('INSERT INTO echo_health_data (identifier, blood_type, mental_health) VALUES (?, ?, ?)', {
                identifier,
                randomBlood,
                ECHO.MentalHealth.StartingMental
            })
            
            print('^2[ECHO]^7 Created health profile for: ' .. identifier)
        end
    end)
end)

-- Get Player Health Data
function echoGetHealthData(identifier, cb)
    MySQL.query('SELECT * FROM echo_health_data WHERE identifier = ?', {identifier}, function(result)
        if result and result[1] then
            cb(result[1])
        else
            cb(nil)
        end
    end)
end

-- Update Health Data
function echoUpdateHealthData(identifier, data)
    local updates = {}
    local values = {}
    
    for k, v in pairs(data) do
        table.insert(updates, k .. ' = ?')
        table.insert(values, v)
    end
    
    table.insert(values, identifier)
    
    local query = 'UPDATE echo_health_data SET ' .. table.concat(updates, ', ') .. ' WHERE identifier = ?'
    MySQL.update(query, values)
end

-- Debug Command
RegisterCommand('echodebug', function(source, args)
    if source == 0 then
        ECHO.Debug = not ECHO.Debug
        print('^2[ECHO]^7 Debug mode: ' .. tostring(ECHO.Debug))
    end
end, false)

-- Export Functions
exports('GetFramework', echoGetFramework)
exports('GetIdentifier', echoGetIdentifier)
exports('GetPlayer', echoGetPlayer)
exports('AddMoney', echoAddMoney)
exports('RemoveMoney', echoRemoveMoney)
exports('GetMoney', echoGetMoney)
exports('Notify', echoNotify)
exports('GetHealthData', echoGetHealthData)
exports('UpdateHealthData', echoUpdateHealthData)

print('^2========================================^7')
print('^2[ECHO Health System]^7 Successfully loaded!')
print('^2[Version]^7 2.0.0 Advanced Edition')
print('^2========================================^7')