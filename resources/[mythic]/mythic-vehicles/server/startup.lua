local _ran = false

function Startup()
    if _ran then return end
    _ran = true

    local ownedCount = MySQL.scalar.await('SELECT COUNT(*) FROM vehicles WHERE ownerType = 0', {})
    if ownedCount ~= nil then
        Logger:Trace('Vehicles', string.format('Loaded ^2%s^7 Character Owned Vehicles', ownedCount))
    end

    local fleetCount = MySQL.scalar.await('SELECT COUNT(*) FROM vehicles WHERE ownerType = 1', {})
    if fleetCount ~= nil then
        Logger:Trace('Vehicles', string.format('Loaded ^2%s^7 Fleet Owned Vehicles', fleetCount))
    end

    CreateThread(function()
        -- Let the server startup, no vehicles need to be saved in the first 2 mins
        Wait(120000)
        while true do
            local savingVINs = {}
            for k, v in pairs(ACTIVE_OWNED_VEHICLES) do
                if v ~= nil then
                    local vData = v:GetData()
                    if vData.EntityId and DoesEntityExist(vData.EntityId) then
                        local vehEnt = Entity(vData.EntityId)
                        if (vehEnt and vehEnt.state and vehEnt.state.NeedSave) then
                            vehEnt.state.NeedSave = false
                            table.insert(savingVINs, vData.VIN)
                        end
                    end
                end
            end

            if #savingVINs > 0 then
                local timeSpread = math.floor((720 * 1000) / #savingVINs)
                if timeSpread < 2000 then
                    timeSpread = 2000
                end
    
                Logger:Info('Vehicles', 'Running Periodical Save For '.. #savingVINs .. ' Vehicles')
    
                for k, v in ipairs(savingVINs) do
                    SaveVehicle(v)
                    Wait(timeSpread)
                end
            else
                Wait(180000)
            end
        end
    end)
end

function VehicleUpdateQuery(where)
    return string.format(
        'UPDATE vehicles SET Type = ?, RegisteredPlate = ?, FakePlate = ?, Make = ?, Model = ?, ownerType = ?, ownerId = ?, ownerWorkplace = ?, ownerLevel = ?, storageType = ?, storageId = ?, vehicle = ? WHERE %s',
        where
    )
end

function VehicleParams(data, VIN)
    return {
        data.Type,
        data.RegisteredPlate,
        data.FakePlate or '',
        data.Make or 'Unknown',
        data.Model or 'Unknown',
        data.Owner?.Type or 0,
        data.Owner?.Id or 0,
        data.Owner?.Workplace or '',
        data.Owner?.Level or 0,
        data.Storage?.Type or 0,
        data.Storage?.Id or 0,
        json.encode(data),
        VIN,
    }
end

function VehicleInsertParams(data)
    local params = VehicleParams(data, data.VIN)
    table.remove(params)
    table.insert(params, 1, data.VIN)

    return params
end
