local showroomsLoaded = false

DEALERSHIPS.Showroom = {
    Load = function(self)
        local results = MySQL.query.await('SELECT * FROM dealer_showrooms', {})

        local showRoomData = {}
        if #results > 0 then
            for k, v in ipairs(results) do
                if _dealerships[v.dealership] then
                    showRoomData[v.dealership] = v.showroom and json.decode(v.showroom) or {}
                end
            end

            GlobalState.DealershipShowrooms = showRoomData
            showroomsLoaded = true
        end

        return true
    end,

    Update = function(self, dealershipId, showroom)
        if _dealerships[dealershipId] then
            if type(showroom) ~= 'table' then 
                showroom = {} 
            end
            
            local success = MySQL.query.await(
                'INSERT INTO dealer_showrooms (dealership, showroom) VALUES(?, ?) ON DUPLICATE KEY UPDATE showroom = VALUES(showroom)',
                {
                    dealershipId,
                    json.encode(showroom),
                }
            ) ~= nil

            if success then
                -- FiveM is dumb
                local currentData = GlobalState.DealershipShowrooms
                currentData[dealershipId] = showroom
                GlobalState.DealershipShowrooms = currentData

                TriggerClientEvent('Dealerships:Client:ShowroomUpdate', -1, dealershipId)
                return showroom
            end

            return false
        end
        return false
    end,
    
    UpdatePos = function(self, dealershipId, position, vehicleData)
        if _dealerships[dealershipId] and (#_dealerships[dealershipId].showroom >= position) then
            position = tostring(position)
            local showroomData = GlobalState.DealershipShowrooms[dealershipId] or {}
            showroomData[position] = type(vehicleData) == 'table' and vehicleData or nil

            return Dealerships.Showroom:Update(dealershipId, showroomData)
        end
        return false
    end,
}