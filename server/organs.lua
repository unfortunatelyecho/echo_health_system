-- Get Organ Compatibility
function echoCheckOrganCompatibility(donorBlood, recipientBlood)
    local compatible = ECHO.Organs.Compatibility[donorBlood]
    if compatible then
        for _, blood in ipairs(compatible) do
            if blood == recipientBlood then
                return true
            end
        end
    end
    return false
end

-- Register as Organ Donor
RegisterNetEvent('echo:server:registerOrganDonor', function()
    local src = source
    local identifier = echoGetIdentifier(src)
    
    if not identifier then return end
    
    echoGetHealthData(identifier, function(data)
        if data then
            if data.organ_donor == 1 then
                echoNotify(src, 'You are already registered as an organ donor!', 'error')
                return
            end
            
            echoUpdateHealthData(identifier, { organ_donor = 1 })
            echoAddMoney(src, ECHO.Organs.LegalDonationReward, 'bank')
            echoNotify(src, 'Thank you for registering as an organ donor! You received $' .. ECHO.Organs.LegalDonationReward, 'success')
        end
    end)
end)

-- Harvest Organ (Legal)
RegisterNetEvent('echo:server:harvestOrgan', function(organType, isBlackMarket)
    local src = source
    local identifier = echoGetIdentifier(src)
    
    if not identifier then return end
    
    -- Check if player is dead or authorized
    local Player = echoGetPlayer(src)
    if not Player then return end
    
    echoGetHealthData(identifier, function(data)
        if not data then return end
        
        if not isBlackMarket and data.organ_donor == 0 then
            echoNotify(src, 'This person is not registered as an organ donor!', 'error')
            return
        end
        
        local organConfig = nil
        for _, organ in ipairs(ECHO.Organs.Types) do
            if organ.name == organType then
                organConfig = organ
                break
            end
        end
        
        if not organConfig then return end
        
        local currentTime = os.time()
        local expiryTime = currentTime + (organConfig.decay * 60)
        
        MySQL.insert('INSERT INTO echo_organs (organ_type, blood_type, quality, donor_identifier, is_black_market, harvested_at, expires_at) VALUES (?, ?, ?, ?, ?, ?, ?)', {
            organType,
            data.blood_type,
            100,
            identifier,
            isBlackMarket and 1 or 0,
            currentTime,
            expiryTime
        }, function(organId)
            if organId then
                local message = isBlackMarket and 
                    'Organ harvested for black market!' or 
                    'Organ successfully harvested and stored!'
                echoNotify(src, message, 'success')
                
                TriggerClientEvent('echo:client:updateOrganInventory', -1)
            end
        end)
    end)
end)

-- Get Available Organs
RegisterNetEvent('echo:server:getAvailableOrgans', function(isBlackMarket)
    local src = source
    local currentTime = os.time()
    
    MySQL.query('SELECT * FROM echo_organs WHERE is_black_market = ? AND expires_at > ? AND quality > 0', {
        isBlackMarket and 1 or 0,
        currentTime
    }, function(organs)
        TriggerClientEvent('echo:client:receiveOrgans', src, organs or {})
    end)
end)

-- Purchase Organ
RegisterNetEvent('echo:server:purchaseOrgan', function(organId, isBlackMarket)
    local src = source
    local identifier = echoGetIdentifier(src)
    
    if not identifier then return end
    
    MySQL.query('SELECT * FROM echo_organs WHERE id = ?', {organId}, function(result)
        if not result or #result == 0 then
            echoNotify(src, 'Organ not found!', 'error')
            return
        end
        
        local organ = result[1]
        local organConfig = nil
        
        for _, config in ipairs(ECHO.Organs.Types) do
            if config.name == organ.organ_type then
                organConfig = config
                break
            end
        end
        
        if not organConfig then return end
        
        local price = isBlackMarket and 
            math.floor(organConfig.price * ECHO.Organs.BlackMarketMultiplier) or 
            organConfig.price
        
        -- Check compatibility if needed
        echoGetHealthData(identifier, function(playerData)
            if not playerData then return end
            
            if organConfig.compatibility then
                if not echoCheckOrganCompatibility(organ.blood_type, playerData.blood_type) then
                    echoNotify(src, 'Blood type incompatible! This organ cannot be used.', 'error')
                    return
                end
            end
            
            if echoGetMoney(src, 'bank') < price then
                echoNotify(src, 'Insufficient funds!', 'error')
                return
            end
            
            if echoRemoveMoney(src, price, 'bank') then
                -- Record transaction
                MySQL.insert('INSERT INTO echo_organ_transactions (organ_id, buyer_identifier, price, transaction_type, timestamp) VALUES (?, ?, ?, ?, ?)', {
                    organId,
                    identifier,
                    price,
                    isBlackMarket and 'blackmarket' or 'legal',
                    os.time()
                })
                
                -- Remove organ from inventory
                MySQL.update('DELETE FROM echo_organs WHERE id = ?', {organId})
                
                echoNotify(src, 'Organ purchased successfully for $' .. price, 'success')
                TriggerClientEvent('echo:client:performTransplant', src, organ.organ_type)
                TriggerClientEvent('echo:client:updateOrganInventory', -1)
            end
        end)
    end)
end)

-- Sell Organ on Black Market
RegisterNetEvent('echo:server:sellOrganBlackMarket', function(organType)
    local src = source
    local identifier = echoGetIdentifier(src)
    
    if not identifier then return end
    
    local organConfig = nil
    for _, organ in ipairs(ECHO.Organs.Types) do
        if organ.name == organType then
            organConfig = organ
            break
        end
    end
    
    if not organConfig then return end
    
    local price = math.floor(organConfig.price * ECHO.Organs.BlackMarketMultiplier)
    
    if echoAddMoney(src, price, 'cash') then
        echoNotify(src, 'Organ sold for $' .. price .. ' (Black Market)', 'success')
        
        -- Add mental health penalty
        TriggerEvent('echo:server:affectMentalHealth', src, 'witnessExecution')
    end
end)

-- Organ Decay System
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        local currentTime = os.time()
        
        -- Update organ quality based on time
        MySQL.query('SELECT * FROM echo_organs WHERE expires_at > ?', {currentTime}, function(organs)
            if organs then
                for _, organ in ipairs(organs) do
                    local organConfig = nil
                    for _, config in ipairs(ECHO.Organs.Types) do
                        if config.name == organ.organ_type then
                            organConfig = config
                            break
                        end
                    end
                    
                    if organConfig then
                        local timeRemaining = organ.expires_at - currentTime
                        local totalTime = organConfig.decay * 60
                        local quality = math.floor((timeRemaining / totalTime) * 100)
                        
                        if quality < 0 then quality = 0 end
                        
                        MySQL.update('UPDATE echo_organs SET quality = ? WHERE id = ?', {quality, organ.id})
                    end
                end
            end
        end)
        
        -- Delete expired organs
        MySQL.update('DELETE FROM echo_organs WHERE expires_at <= ? OR quality <= 0', {currentTime})
    end
end)

-- Exports
exports('CheckOrganCompatibility', echoCheckOrganCompatibility)