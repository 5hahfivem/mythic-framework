function GetCharacterCreditScore(stateId)
    local result = MySQL.single.await('SELECT Score FROM loans_credit_scores WHERE SID = ?', { stateId })

    if result == nil then
        return _creditScoreConfig.default
    end

    return result.Score
end

function SetCharacterCreditScore(stateId, score)
    local p = promise.new()

    if score > _creditScoreConfig.max then
        score = _creditScoreConfig.max
    end

    if score < _creditScoreConfig.min then
        score = _creditScoreConfig.min
    end

    local success = MySQL.query.await(
        'INSERT INTO loans_credit_scores (SID, Score) VALUES(?, ?) ON DUPLICATE KEY UPDATE Score = VALUES(Score)',
        { stateId, score }
    ) ~= nil

    do
        if success then
            p:resolve(score)
        else
            p:resolve(false)
        end
    end

    local res = Citizen.Await(p)
    return res
end

function IncreaseCharacterCreditScore(stateId, amount)
    local creditScore = GetCharacterCreditScore(stateId)
    return SetCharacterCreditScore(stateId, math.min(_creditScoreConfig.max, creditScore + amount))
end

function DecreaseCharacterCreditScore(stateId, amount)
    local creditScore = GetCharacterCreditScore(stateId)
    return SetCharacterCreditScore(stateId, math.max(_creditScoreConfig.min, creditScore - amount))
end

AddEventHandler('Job:Server:DutyAdd', function(dutyData, source, stateId)
    if dutyData?.Id and stateId then
        local isBoosted = _creditScoreConfig.boostingJobs[dutyData.Id]
        if isBoosted then
            local creditScore = GetCharacterCreditScore(stateId)
            -- Don't give item them if their credit is or they have more than that credit
            if creditScore >= 150 and creditScore < isBoosted then
                SetCharacterCreditScore(stateId, isBoosted)
            end
        end
    end
end)