local withdrawalActive = false
local currentWithdrawalStage = 0

-- Withdrawal Effects
RegisterNetEvent('echo:client:withdrawalEffects', function(substance, stage)
    if withdrawalActive and currentWithdrawalStage >= stage then
        return -- Don't downgrade effects
    end
    
    withdrawalActive = true
    currentWithdrawalStage = stage
    
    local symptoms = ECHO.Addiction.WithdrawalSymptoms[stage]
    
    if not symptoms then return end
    
    TriggerEvent('echo:notify', 'Withdrawal: ' .. symptoms.level .. ' (' .. substance .. ')', 'error')
    
    local playerPed = PlayerPedId()
    
    -- Apply effects based on symptoms
    for _, effect in ipairs(symptoms.effects) do
        if effect == "shaking" then
            CreateThread(function()
                while withdrawalActive and currentWithdrawalStage >= stage do
                    ShakeGameplayCam('HAND_SHAKE', 0.3)
                    Wait(1000)
                end
            end)
        elseif effect == "sweating" then
            -- Visual effect
            SetPedSweat(playerPed, 100.0)
        elseif effect == "nausea" then
            CreateThread(function()
                while withdrawalActive and currentWithdrawalStage >= stage do
                    SetTimecycleModifier("drug_flying_01")
                    Wait(5000)
                    ClearTimecycleModifier()
                    Wait(10000)
                end
            end)
        elseif effect == "hallucinations" then
            CreateThread(function()
                while withdrawalActive and currentWithdrawalStage >= stage do
                    StartScreenEffect("DrugsMichaelAliensFight", 0, false)
                    Wait(15000)
                    StopScreenEffect("DrugsMichaelAliensFight")
                    Wait(30000)
                end
            end)
        elseif effect == "seizures" then
            CreateThread(function()
                while withdrawalActive and currentWithdrawalStage >= stage do
                    Wait(math.random(60000, 180000))
                    
                    -- Seizure animation
                    SetPedToRagdoll(playerPed, 10000, 10000, 0, 0, 0, 0)
                    ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.0)
                    
                    TriggerEvent('echo:notify', 'You are having a seizure!', 'error')
                    
                    Wait(10000)
                end
            end)
        end
    end
    
    -- Stat penalties
    SetPlayerHealthRechargeMultiplier(PlayerId(), 1.0 - (symptoms.statPenalty / 100))
end)

-- Use Substance (Example integration)
RegisterCommand('usesubstance', function(source, args)
    if not args[1] then
        TriggerEvent('echo:notify', 'Usage: /usesubstance [substance]', 'error')
        return
    end
    
    local substance = args[1]
    
    if not ECHO.Addiction.Substances[substance] then
        TriggerEvent('echo:notify', 'Invalid substance!', 'error')
        return
    end
    
    TriggerServerEvent('echo:server:useSubstance', substance)
    TriggerEvent('echo:notify', 'You used ' .. ECHO.Addiction.Substances[substance].label, 'info')
    
    -- Clear withdrawal temporarily
    withdrawalActive = false
    currentWithdrawalStage = 0
    StopAllScreenEffects()
    ClearTimecycleModifier()
    SetPlayerHealthRechargeMultiplier(PlayerId(), 1.0)
end)

-- Join Recovery Program
RegisterCommand('joinrecovery', function(source, args)
    if not args[1] then
        TriggerEvent('echo:notify', 'Usage: /joinrecovery [substance]', 'error')
        return
    end
    
    local substance = args[1]
    TriggerServerEvent('echo:server:joinRecovery', substance)
end)

-- Attend Meeting
RegisterCommand('attendmeeting', function(source, args)
    if not args[1] then
        TriggerEvent('echo:notify', 'Usage: /attendmeeting [substance]', 'error')
        return
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Check if near meeting location
    local nearLocation = false
    for _, loc in ipairs(ECHO.Addiction.RecoveryProgram.Locations) do
        if #(playerCoords - loc) < 10.0 then
            nearLocation = true
            break
        end
    end
    
    if not nearLocation then
        TriggerEvent('echo:notify', 'You must be at a recovery meeting location!', 'error')
        return
    end
    
    local substance = args[1]
    TriggerServerEvent('echo:server:attendMeeting', substance)
end)

-- Start Meeting
RegisterNetEvent('echo:client:startMeeting', function(substance)
    local playerPed = PlayerPedId()
    
    TriggerEvent('echo:notify', 'Meeting started. Duration: ' .. (ECHO.Addiction.RecoveryProgram.MeetingDuration / 60) .. ' minutes', 'info')
    
    -- Sit animation
    RequestAnimDict("anim@heists@prison_heiststation@cop_reactions")
    while not HasAnimDictLoaded("anim@heists@prison_heiststation@cop_reactions") do
        Wait(10)
    end
    
    TaskPlayAnim(playerPed, "anim@heists@prison_heiststation@cop_reactions", "cop_b_idle", 8.0, -8.0, -1, 1, 0, false, false, false)
    
    Wait(ECHO.Addiction.RecoveryProgram.MeetingDuration * 1000)
    
    ClearPedTasks(playerPed)
    TriggerServerEvent('echo:server:completeMeeting', substance)
end)

-- Set Sponsor
RegisterCommand('setsponsor', function(source, args)
    if not args[1] or not args[2] then
        TriggerEvent('echo:notify', 'Usage: /setsponsor [playerid] [substance]', 'error')
        return
    end
    
    local targetId = tonumber(args[1])
    local substance = args[2]
    
    TriggerServerEvent('echo:server:setSponsor', targetId, substance)
end)