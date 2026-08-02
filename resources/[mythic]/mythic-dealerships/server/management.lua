_managementData = {}

DEALERSHIPS.Management = {
    LoadData = function(self)
        local results = MySQL.query.await('SELECT * FROM dealer_data', {})

        local fuckface = {}
        for k, v in ipairs(results) do
            if v.dealership then
                fuckface[v.dealership] = json.decode(v.data)
            end
        end

        for k, v in pairs(_dealerships) do
            if fuckface[k] then
                _managementData[k] = fuckface[k]
            else
                _managementData[k] = _defaultDealershipSalesData
            end
        end

        return true
    end,
    SetData = function(self, dealerId, key, val)
        local data = _managementData[dealerId]
        if data then
            local dealerData = table.copy(data)
            dealerData.dealership = nil
            dealerData._id = nil
            dealerData[key] = val

            local success = MySQL.query.await(
                'INSERT INTO dealer_data (dealership, `data`) VALUES(?, ?) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)',
                {
                    dealerId,
                    json.encode(dealerData),
                }
            ) ~= nil

            if success then
                _managementData[dealerId] = dealerData
                return _managementData[dealerId]
            end

            return false
        end
        return false
    end,
    SetMultipleData = function(self, dealerId, updatingData)
        local data = _managementData[dealerId]
        if data then
            local dealerData = table.copy(data)
            dealerData.dealership = nil
            dealerData._id = nil

            for k, v in pairs(updatingData) do
                dealerData[k] = v
            end

            local success = MySQL.query.await(
                'INSERT INTO dealer_data (dealership, `data`) VALUES(?, ?) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)',
                {
                    dealerId,
                    json.encode(dealerData),
                }
            ) ~= nil

            if success then
                _managementData[dealerId] = dealerData
                return _managementData[dealerId]
            end

            return false
        end
        return false
    end,
    GetAllData = function(self, dealerId)
        return _managementData[dealerId]
    end,
    GetData = function(self, dealerId, key)
        local data = _managementData[dealerId]
        if data then
            return data[key]
        end
        return false
    end,
}