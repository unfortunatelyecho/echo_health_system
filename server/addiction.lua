-- Track Substance Use
RegisterNetEvent('echo:server:useSubstance', function(substance)
    local src = source
    local identifier = echoGetIdentifier(src)
    
    if not identifier then return end
    
    local substanceConfig = ECHO.Addiction.Substances[substance]
    if not substanceConfig then return end
    
    MySQL.query('SELECT * FROM echo_addictions WHERE identifier = ? AND substance = ?', {identifier, substance}, function(result)
        if result and #result > 0 then
            local addiction = result[1]
            local newLevel = math.min(substanceConfig.maxAddiction, addiction.addiction_level + substanceConfig.addictionRate)
            
            MySQL.update('UPDATE echo_addictions SET addiction_level = ?, last_use = ?, total_uses = total_uses + 1, clean_since = NULL WHERE id = ?', {
                newLevel,
                os.time(),
                addiction.id
            })
            
            -- Check if relapse
            if addiction.clean_since then
                MySQL.update('UPDATE echo_addictions SET relapses = relapses + 1 WHERE id = ?', {addiction.id})
                echoNotify(src, 'You have relapsed...', 'error')
                
                -- Reset recovery progress
                MySQL.update('DELETE FROM echo_recovery WHERE identifier = ? AND substance = ?', {identifier, substance})
            end
            
            TriggerClientEvent('echo:client:updateAddiction', src, substance, newLevel)
        else
            -- First time use
            MySQL.insert('INSERT INTO echo_addictions (identifier, substance, addiction_level, last_use, total_uses) VALUES (?, ?, ?, ?, ?)', {
                identifier,
                substance,
                substanceConfig.addictionRate,
                os.time(),
                1
            })
            
            TriggerClientEvent('echo:client:updateAddiction', src, substance, substanceConfig.addictionRate)
        end
        
        if ECHO.Debug then
            print(string.format('[ECHO Addiction] %s used %s', identifier, substance))
        end
    end)
end)

-- Get Addiction Data
RegisterNetEvent('echo:server:getAddictionData', function()
    local src = source
    local identifier = echoGetIdentifier(src)
    
    if not identifier then return end
    
    MySQL.query('SELECT * FROM echo_addictions WHERE identifier = ?', {identifier}, function(result)
        TriggerClientEvent('echo:client:receiveAddictionData', src, result or {})
    end)
end)

-- Join Recovery Program
RegisterNetEvent('echo:server:joinRecovery', function(substance)
    local src = source
    local identifier = echoGetIdentifier(src)
    
    if not identifier then return end
    
    MySQL.query('SELECT * FROM echo_addictions WHERE identifier = ? AND substance = ?', {identifier, substance}, function(result)
        if not result or #result == 0 then
            echoNotify(src, 'You are not addicted to this substance.', 'error')
            return
        end
        
        local addiction = result[1]
        
        if addiction.addiction_level < 20 then
            echoNotify(src, 'Your addiction level is too low to require a recovery program.', 'info')
            return
        end
        
        MySQL.query('SELECT * FROM echo_recovery WHERE identifier = ? AND substance = ? AND program_completed = 0', {identifier, substance}, function(recovery)
            if recovery and #recovery > 0 then
                echoNotify(src, 'You are already enrolled in a recovery program for this substance.', 'error')
                return
            end
            
            MySQL.insert('INSERT INTO echo_recovery (identifier, substance, program_started) VALUES (?, ?, ?)', {
                identifier,
                substance,
                os.time()
            })
            
            -- Set clean date
            MySQL.update('UPDATE echo_addictions SET clean_since = ? WHERE identifier = ? AND substance = ?', {
                os.time(),
                identifier,
                substance
            })
            
            echoNotify(src, 'You have joined the recovery program for ' .. ECHO.Addiction.Substances[substance].label, 'success')
        end)
    end)
end)

-- Attend Meeting
RegisterNetEvent('echo:server:attendMeeting', function(substance)
    local src = source
    local identifier = echoGetIdentifier(src)
    
    if not identifier then return end
    
    MySQL.query('SELECT * FROM echo_recovery WHERE identifier = ? AND substance = ? AND program_completed = 0', {identifier, substance}, function(result)
        if not result or #result == 0 then
            echoNotify(src, 'You are not enrolled in a recovery program for this substance.', 'error')
            return
        end
        
        local recovery = result[1]
        local currentTime = os.time()
        local timeSinceLastMeeting = currentTime - recovery.last_meeting
        
        if timeSinceLastMeeting < ECHO.Addiction.RecoveryProgram.MeetingInterval then
            local timeLeft = ECHO.Addiction.RecoveryProgram.MeetingInterval - timeSinceLastMeeting
            echoNotify(src, 'You must wait ' .. math.ceil(timeLeft / 60) .. ' more minutes before attending another meeting.', 'error')
            return
        end
        
        -- Start meeting
        TriggerClientEvent('echo:client:startMeeting', src, substance)
    end)
end)

-- Complete Meeting
RegisterNetEvent('echo:server:completeMeeting', function(substance)
    local src = source
    local identifier = echoGetIdentifier(src)
    
    if not identifier then return end
    
    MySQL.query('SELECT * FROM echo_recovery WHERE identifier = ? AND substance = ? AND program_completed = 0', {identifier, substance}, function(recovery)
        if not recovery or #recovery == 0 then return end
        
        local recoveryData = recovery[1]
        local newMeetings = recoveryData.meetings_attended + 1
        
        -- Update meetings
        MySQL.update('UPDATE echo_recovery SET meetings_attended = ?, last_meeting = ? WHERE id = ?', {
            newMeetings,
            os.time(),
            recoveryData.id
        })
        
        -- Reduce addiction level
        local reductionBonus = ECHO.Addiction.RecoveryProgram.RecoveryBonus
        
        -- Check if has sponsor
        if recoveryData.sponsor_identifier then
            reductionBonus = reductionBonus + ECHO.Addiction.RecoveryProgram.SponsorBonus
        end
        
        MySQL.query('SELECT * FROM echo_addictions WHERE identifier = ? AND substance = ?', {identifier, substance}, function(addiction)
            if addiction and #addiction > 0 then
                local currentLevel = addiction[1].addiction_level
                local newLevel = math.max(0, currentLevel - reductionBonus)
                
                MySQL.update('UPDATE echo_addictions SET addiction_level = ? WHERE identifier = ? AND substance = ?', {
                    newLevel,
                    identifier,
                    substance
                })
                
                echoNotify(src, 'Meeting completed! Addiction reduced by ' .. reductionBonus .. '%', 'success')
                TriggerClientEvent('echo:client:updateAddiction', src, substance, newLevel)
                
                -- Check if program completed
                if newMeetings >= ECHO.Addiction.RecoveryProgram.MinMeetings and newLevel <= 10 then
                    MySQL.update('UPDATE echo_recovery SET program_completed = 1, completion_date = ? WHERE id = ?', {
                        os.time(),
                        recoveryData.id
                    })
                    
                    echoNotify(src, 'Congratulations! You have completed the recovery program!', 'success')
                    echoAddMoney(src, 5000, 'bank') -- Reward
                end
            end
        end)
    end)
end)

-- Set Sponsor
RegisterNetEvent('echo:server:setSponsor', function(targetSource, substance)
    local src = source
    local identifier = echoGetIdentifier(src)
    local sponsorId = echoGetIdentifier(targetSource)
    
    if not identifier or not sponsorId then return end
    
    MySQL.update('UPDATE echo_recovery SET sponsor_identifier = ? WHERE identifier = ? AND substance = ?', {
        sponsorId,
        identifier,
        substance
    })
    
    echoNotify(src, 'Sponsor assigned!', 'success')
    echoNotify(targetSource, 'You are now sponsoring someone in recovery.', 'info')
end)

-- Withdrawal Effects Thread
CreateThread(function()
    while true do
        Wait(300000) -- Check every 5 minutes
        
        MySQL.query('SELECT * FROM echo_addictions WHERE addiction_level > 20', {}, function(addictions)
            if addictions then
                for _, addiction in ipairs(addictions) do
                    local substanceConfig = ECHO.Addiction.Substances[addiction.substance]
                    
                    if substanceConfig then
                        local timeSinceUse = os.time() - addiction.last_use
                        local withdrawalStart = substanceConfig.withdrawalStart * 3600
                        
                        if timeSinceUse >= withdrawalStart then
                            -- Calculate withdrawal stage
                            local hoursWithdrawing = (timeSinceUse - withdrawalStart) / 3600
                            local stage = math.min(4, math.floor(hoursWithdrawing / 4) + 1)
                            
                            -- Trigger withdrawal effects on client
                            local players = GetPlayers()
                            for _, playerId in ipairs(players) do
                                local playerSrc = tonumber(playerId)
                                if echoGetIdentifier(playerSrc) == addiction.identifier then
                                    TriggerClientEvent('echo:client:withdrawalEffects', playerSrc, addiction.substance, stage)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- Exports
exports('TrackSubstanceUse', function(source, substance)
    TriggerEvent('echo:server:useSubstance', source, substance)
end)