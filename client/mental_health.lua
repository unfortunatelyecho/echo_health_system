local currentMentalHealth = 100
local inTherapy = false
local effectsActive = {
    shake = false,
    blur = false
}

-- Screen Effects Based on Mental Health
CreateThread(function()
    while true do
        Wait(1000)
        
        -- Find current stage
        local currentStage = nil
        for _, stage in ipairs(ECHO.MentalHealth.Stages) do
            if currentMentalHealth >= stage.min and currentMentalHealth <= stage.max then
                currentStage = stage
                break
            end
        end
        
        if currentStage and currentStage.effects then
            -- Stress Shake
            if currentStage.effects.stressShake and not effectsActive.shake then
                effectsActive.shake = true
                CreateThread(function()
                    while effectsActive.shake do
                        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.05)
                        Wait(100)
                    end
                end)
            elseif not currentStage.effects.stressShake then
                effectsActive.shake = false
            end
            
            -- Vision Blur
            if currentStage.effects.visionBlur and not effectsActive.blur then
                effectsActive.blur = true
                SetTimecycleModifier("MenuMGHeistIn")
            elseif not currentStage.effects.visionBlur and effectsActive.blur then
                effectsActive.blur = false
                ClearTimecycleModifier()
            end
        end
    end
end)

-- Panic Attack
RegisterNetEvent('echo:client:panicAttack', function()
    local playerPed = PlayerPedId()
    
    TriggerEvent('echo:notify', 'You are having a panic attack!', 'error')
    
    -- Heavy breathing
    SetPedMoveRateOverride(playerPed, 0.5)
    
    -- Screen effects
    SetTimecycleModifier("drug_drive_blend02")
    ShakeGameplayCam('DRUNK_SHAKE', 1.0)
    
    -- Force crouch
    SetPedStealthMovement(playerPed, true, "DEFAULT_ACTION")
    
    Wait(15000) -- 15 seconds
    
    -- Recover
    SetPedMoveRateOverride(playerPed, 1.0)
    ClearTimecycleModifier()
    StopGameplayCamShaking(true)
    SetPedStealthMovement(playerPed, false, "DEFAULT_ACTION")
    
    TriggerEvent('echo:notify', 'The panic attack has subsided...', 'info')
end)

-- Random Outburst
RegisterNetEvent('echo:client:randomOutburst', function()
    local playerPed = PlayerPedId()
    
    local outbursts = {
        "You suddenly scream!",
        "You throw a tantrum!",
        "You start crying uncontrollably!"
    }
    
    local message = outbursts[math.random(#outbursts)]
    TriggerEvent('echo:notify', message, 'error')
    
    -- Play animation
    RequestAnimDict("anim@move_f@waitress")
    while not HasAnimDictLoaded("anim@move_f@waitress") do
        Wait(10)
    end
    
    TaskPlayAnim(playerPed, "anim@move_f@waitress", "idle", 8.0, -8.0, 5000, 1, 0, false, false, false)
    
    -- Nearby players see emote
    TriggerServerEvent('echo:server:broadcastOutburst', GetPlayerServerId(PlayerId()))
end)

-- Therapy Session
RegisterNetEvent('echo:client:therapySession', function(otherPlayer)
    inTherapy = true
    
    SendNUIMessage({
        action = 'startTherapy',
        duration = ECHO.MentalHealth.TherapyDuration
    })
    
    Wait(ECHO.MentalHealth.TherapyDuration * 1000)
    
    inTherapy = false
    
    TriggerServerEvent('echo:server:completeTherapy', otherPlayer, "Session completed successfully")
end)

-- Request Therapy
RegisterCommand('requesttherapy', function()
    -- Find nearby therapist
    local players = GetActivePlayers()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, player in ipairs(players) do
        local targetPed = GetPlayerPed(player)
        local targetCoords = GetEntityCoords(targetPed)
        
        if #(playerCoords - targetCoords) < 5.0 and player ~= PlayerId() then
            TriggerServerEvent('echo:server:startTherapy', GetPlayerServerId(player))
            return
        end
    end
    
    TriggerEvent('echo:notify', 'No therapist nearby!', 'error')
end)

-- Meditation (self-help)
RegisterCommand('meditate', function()
    local playerPed = PlayerPedId()
    
    RequestAnimDict("rcmcollect_paperleadinout@")
    while not HasAnimDictLoaded("rcmcollect_paperleadinout@") do
        Wait(10)
    end
    
    TaskPlayAnim(playerPed, "rcmcollect_paperleadinout@", "meditiate_idle", 8.0, -8.0, -1, 1, 0, false, false, false)
    
    TriggerEvent('echo:notify', 'Meditating... (60 seconds)', 'info')
    
    Wait(60000)
    
    ClearPedTasks(playerPed)
    TriggerServerEvent('echo:server:affectMentalHealth', 'meditation')
end)