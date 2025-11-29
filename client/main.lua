local PlayerData = {}
local healthData = {
    bloodType = "O+",
    mentalHealth = 100,
    addictions = {}
}

-- Initialize
CreateThread(function()
    Wait(1000)
    TriggerServerEvent('echo:server:initializePlayer')
    TriggerServerEvent('echo:server:getMentalHealth')
    TriggerServerEvent('echo:server:getAddictionData')
end)

-- Notification Handler
RegisterNetEvent('echo:notify', function(message, type, duration)
    -- Default notification
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end)

-- Update Mental Health
RegisterNetEvent('echo:client:updateMentalHealth', function(mental)
    healthData.mentalHealth = mental
    SendNUIMessage({
        action = 'updateMental',
        mental = mental
    })
end)

-- Update Addiction
RegisterNetEvent('echo:client:updateAddiction', function(substance, level)
    healthData.addictions[substance] = level
    SendNUIMessage({
        action = 'updateAddiction',
        substance = substance,
        level = level
    })
end)

-- Receive Addiction Data
RegisterNetEvent('echo:client:receiveAddictionData', function(addictions)
    for _, addiction in ipairs(addictions) do
        healthData.addictions[addiction.substance] = addiction.addiction_level
    end
end)

-- HUD Display Toggle
RegisterCommand('echohud', function()
    SendNUIMessage({ action = 'toggleHUD' })
end)

-- Debug Info
if ECHO.Debug then
    CreateThread(function()
        while true do
            Wait(5000)
            print(string.format('[ECHO Debug] Mental: %d | Addictions: %d', 
                healthData.mentalHealth, 
                table.count(healthData.addictions)
            ))
        end
    end)
end

-- Helper function
function table.count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end