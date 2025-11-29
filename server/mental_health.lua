-- Affect Mental Health
RegisterNetEvent('echo:server:affectMentalHealth', function(eventType, customImpact)
    local src = source
    local identifier = echoGetIdentifier(src)
    
    if not identifier then return end
    
    local impact = customImpact
    local message = nil
    
    if not impact then
        local traumaEvent = ECHO.MentalHealth.TraumaEvents[eventType]
        local positiveEvent = ECHO.MentalHealth.PositiveEvents[eventType]
        
        if traumaEvent then
            impact = traumaEvent.impact
            message = traumaEvent.message
        elseif positiveEvent then
            impact = positiveEvent.impact
            message = "You feel better..."
        else
            return
        end
    end
    
    echoGetHealthData(identifier, function(data)
        if not data then return end
        
        local currentMental = data.mental_health
        local newMental = math.max(ECHO.MentalHealth.MinMental, math.min(ECHO.MentalHealth.MaxMental, currentMental + impact))
        
        echoUpdateHealthData(identifier, { mental_health = newMental })
        
        -- Log the event
        MySQL.insert('INSERT INTO echo_mental_logs (identifier, event_type, impact, mental_before, mental_after, timestamp) VALUES (?, ?, ?, ?, ?, ?)', {
            identifier,
            eventType,
            impact,
            currentMental,
            newMental,
            os.time()
        })
        
        -- Notify player
        if message then
            echoNotify(src, message, impact < 0 and 'error' or 'success')
        end
        
        -- Update client
        TriggerClientEvent('echo:client:updateMentalHealth', src, newMental)
        
        if ECHO.Debug then
            print(string.format('[ECHO Mental] %s: %d -> %d (%s)', identifier, currentMental, newMental, eventType))
        end
    end)
end)

-- Get Mental Health
RegisterNetEvent('echo:server:getMentalHealth', function()
    local src = source
    local identifier = echoGetIdentifier(src)
    
    if not identifier then return end
    
    echoGetHealthData(identifier, function(data)
        if data then
            TriggerClientEvent('echo:client:updateMentalHealth', src, data.mental_health)
        end
    end)
end)

-- Start Therapy Session
RegisterNetEvent('echo:server:startTherapy', function(therapistSource)
    local src = source
    local identifier = echoGetIdentifier(src)
    local therapistId = echoGetIdentifier(therapistSource)
    
    if not identifier or not therapistId then return end
    
    echoGetHealthData(identifier, function(data)
        if not data then return end
        
        local currentTime = os.time()
        local cooldown = ECHO.MentalHealth.PositiveEvents.therapy.cooldown
        
        if data.last_therapy and (currentTime - data.last_therapy) < cooldown then
            local timeLeft = cooldown - (currentTime - data.last_therapy)
            echoNotify(src, 'You need to wait ' .. math.ceil(timeLeft / 60) .. ' more minutes before another session.', 'error')
            return
        end
        
        if echoGetMoney(src, 'bank') < ECHO.MentalHealth.TherapyPrice then
            echoNotify(src, 'You cannot afford therapy ($' .. ECHO.MentalHealth.TherapyPrice .. ')', 'error')
            return
        end
        
        -- Start session
        TriggerClientEvent('echo:client:therapySession', src, therapistSource)
        TriggerClientEvent('echo:client:therapySession', therapistSource, src)
        
        echoNotify(src, 'Therapy session started...', 'info')
        echoNotify(therapistSource, 'Therapy session started with patient...', 'info')
    end)
end)

-- Complete Therapy Session
RegisterNetEvent('echo:server:completeTherapy', function(therapistSource, notes)
    local src = source
    local identifier = echoGetIdentifier(src)
    local therapistId = echoGetIdentifier(therapistSource)
    
    if not identifier or not therapistId then return end
    
    local mentalGain = ECHO.MentalHealth.PositiveEvents.therapy.impact
    
    -- Payment
    if echoRemoveMoney(src, ECHO.MentalHealth.TherapyPrice, 'bank') then
        echoAddMoney(therapistSource, ECHO.MentalHealth.Therapists.PaymentPerSession, 'bank')
        
        -- Update mental health
        TriggerEvent('echo:server:affectMentalHealth', src, 'therapy')
        
        -- Update last therapy time
        echoUpdateHealthData(identifier, { last_therapy = os.time() })
        
        -- Log session
        MySQL.insert('INSERT INTO echo_therapy_sessions (patient_identifier, therapist_identifier, duration, mental_gain, payment, notes, session_date) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            identifier,
            therapistId,
            ECHO.MentalHealth.TherapyDuration,
            mentalGain,
            ECHO.MentalHealth.TherapyPrice,
            notes or 'No notes provided',
            os.time()
        })
        
        echoNotify(src, 'Therapy session completed. You feel much better!', 'success')
        echoNotify(therapistSource, 'Session completed. You received $' .. ECHO.MentalHealth.Therapists.PaymentPerSession, 'success')
    end
end)

-- Mental Health Effects Thread
CreateThread(function()
    while true do
        Wait(30000) -- Check every 30 seconds
        
        local players = GetPlayers()
        
        for _, playerId in ipairs(players) do
            local src = tonumber(playerId)
            local identifier = echoGetIdentifier(src)
            
            if identifier then
                echoGetHealthData(identifier, function(data)
                    if data then
                        local mental = data.mental_health
                        
                        -- Determine stage
                        for _, stage in ipairs(ECHO.MentalHealth.Stages) do
                            if mental >= stage.min and mental <= stage.max then
                                if stage.effects.panicChance then
                                    local chance = math.random(1, 100)
                                    if chance <= stage.effects.panicChance then
                                        TriggerClientEvent('echo:client:panicAttack', src)
                                    end
                                end
                                
                                if stage.effects.outburst then
                                    local chance = math.random(1, 100)
                                    if chance <= 10 then -- 10% chance
                                        TriggerClientEvent('echo:client:randomOutburst', src)
                                    end
                                end
                                
                                break
                            end
                        end
                    end
                end)
            end
        end
    end
end)

-- Exports
exports('AffectMentalHealth', function(source, eventType, customImpact)
    TriggerEvent('echo:server:affectMentalHealth', source, eventType, customImpact)
end)