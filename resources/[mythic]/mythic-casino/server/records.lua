function UpdateCharacterCasinoStats(source, statType, isWin, amount)
    local plyr = Fetch:Source(source)
    if plyr then
        local char = plyr:GetData("Character")
        if char then
            local sid = char:GetData("SID")
            local result = MySQL.single.await("SELECT stats FROM casino_statistics WHERE SID = ?", { sid })
            local stats = result and json.decode(result.stats) or {}

            if stats[statType] == nil then
                stats[statType] = {}
            end

            table.insert(stats[statType], {
                Win = isWin,
                Amount = amount,
            })

            if isWin then
                stats.AmountWon = stats.AmountWon or {}
                stats.TotalAmountWon = (stats.TotalAmountWon or 0) + amount
                stats.AmountWon[statType] = (stats.AmountWon[statType] or 0) + amount
            else
                stats.AmountLost = stats.AmountLost or {}
                stats.TotalAmountLost = (stats.TotalAmountLost or 0) + amount
                stats.AmountLost[statType] = (stats.AmountLost[statType] or 0) + amount
            end

            local updated = MySQL.query.await(
                "INSERT INTO casino_statistics (SID, stats) VALUES(?, ?) ON DUPLICATE KEY UPDATE stats = VALUES(stats)",
                {
                    sid,
                    json.encode(stats),
                }
            )

            if not updated then
                return false
            end

            return stats
        end
    end
    return false
end

function SaveCasinoBigWin(source, machine, prize, data)
    local plyr = Fetch:Source(source)
    if plyr then
        local char = plyr:GetData("Character")
        if char then
            local id = MySQL.insert.await(
                'INSERT INTO casino_bigwins (Type, Time, Winner, Prize, MetaData) VALUES(?, ?, ?, ?, ?)',
                {
                    machine,
                    os.time(),
                    json.encode({
                        SID = char:GetData("SID"),
                        First = char:GetData("First"),
                        Last = char:GetData("Last"),
                        ID = char:GetData("ID"),
                    }),
                    prize,
                    json.encode(data),
                }
            )

            return id ~= nil
        end
    end
    return false
end