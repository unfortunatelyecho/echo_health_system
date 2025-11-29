-- Organ Donation Points
local organDonationBlip = nil
local blackMarketBlip = nil

CreateThread(function()
    if ECHO.Organs.Enabled then
        -- Hospital Blip
        organDonationBlip = AddBlipForCoord(ECHO.Organs.Locations.Hospital.x, ECHO.Organs.Locations.Hospital.y, ECHO.Organs.Locations.Hospital.z)
        SetBlipSprite(organDonationBlip, 61)
        SetBlipDisplay(organDonationBlip, 4)
        SetBlipScale(organDonationBlip, 0.8)
        SetBlipColour(organDonationBlip, 2)
        SetBlipAsShortRange(organDonationBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Organ Donation Center")
        EndTextCommandSetBlipName(organDonationBlip)
        
        -- Black Market Blip (Hidden until discovered)
        -- blackMarketBlip can be added similarly
    end
end)

-- Register as Organ Donor
RegisterCommand('registerdonor', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - ECHO.Organs.Locations.Hospital)
    
    if distance < 5.0 then
        TriggerServerEvent('echo:server:registerOrganDonor')
    else
        TriggerEvent('echo:notify', 'You must be at the Organ Donation Center!', 'error')
    end
end)

-- Browse Available Organs
RegisterCommand('browseorgans', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - ECHO.Organs.Locations.Hospital)
    
    if distance < 5.0 then
        TriggerServerEvent('echo:server:getAvailableOrgans', false)
    else
        TriggerEvent('echo:notify', 'You must be at the hospital!', 'error')
    end
end)

-- Receive Organs List
RegisterNetEvent('echo:client:receiveOrgans', function(organs)
    SendNUIMessage({
        action = 'showOrganList',
        organs = organs
    })
    SetNuiFocus(true, true)
end)

-- Purchase Organ (from NUI)
RegisterNUICallback('purchaseOrgan', function(data, cb)
    TriggerServerEvent('echo:server:purchaseOrgan', data.organId, data.isBlackMarket)
    cb('ok')
end)

-- Perform Transplant Animation
RegisterNetEvent('echo:client:performTransplant', function(organType)
    local playerPed = PlayerPedId()
    
    -- Animation
    RequestAnimDict("amb@medic@standing@tendtodead@base")
    while not HasAnimDictLoaded("amb@medic@standing@tendtodead@base") do
        Wait(10)
    end
    
    TaskPlayAnim(playerPed, "amb@medic@standing@tendtodead@base", "base", 8.0, -8.0, 15000, 1, 0, false, false, false)
    
    TriggerEvent('echo:notify', 'Receiving organ transplant...', 'info')
    
    Wait(15000)
    
    TriggerEvent('echo:notify', 'Transplant successful!', 'success')
    
    -- Health restoration
    SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
end)

-- Update Organ Inventory (refresh UI)
RegisterNetEvent('echo:client:updateOrganInventory', function()
    -- Refresh if UI is open
    SendNUIMessage({ action = 'refreshOrgans' })
end)

-- Target System Integration (if enabled)
if ECHO.Target.Enabled then
    CreateThread(function()
        if ECHO.Target.Type == 'qb-target' then
            exports['qb-target']:AddBoxZone("organ_donation", ECHO.Organs.Locations.Hospital, 2.0, 2.0, {
                name = "organ_donation",
                heading = 0,
                debugPoly = ECHO.Debug,
                minZ = ECHO.Organs.Locations.Hospital.z - 1,
                maxZ = ECHO.Organs.Locations.Hospital.z + 2,
            }, {
                options = {
                    {
                        type = "client",
                        event = "echo:client:openOrganMenu",
                        icon = "fas fa-heartbeat",
                        label = "Organ Donation Center",
                    }
                },
                distance = 2.5
            })
        end
    end)
end

RegisterNetEvent('echo:client:openOrganMenu', function()
    -- Open organ menu
    TriggerServerEvent('echo:server:getAvailableOrgans', false)
end)