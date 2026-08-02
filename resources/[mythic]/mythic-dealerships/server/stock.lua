local _stockColumns = {
    dealership = true,
    vehicle = true,
    modelType = true,
    quantity = true,
    lastStocked = true,
    lastPurchase = true,
}

local function buildStockUpdate(setting)
    local clauses, params = {}, {}

    for k, v in pairs(setting) do
        local path = k:match('^data%.(.+)$')
        if path then
            table.insert(clauses, "`data` = JSON_SET(COALESCE(`data`, '{}'), ?, CAST(? AS JSON))")
            table.insert(params, string.format('$."%s"', path))
            table.insert(params, json.encode(v))
        elseif k == 'data' then
            table.insert(clauses, "`data` = ?")
            table.insert(params, json.encode(v))
        elseif _stockColumns[k] then
            table.insert(clauses, string.format("`%s` = ?", k))
            table.insert(params, v)
        end
    end

    return clauses, params
end

DEALERSHIPS.Stock = {
    FetchAll = function(self)
        local result = MySQL.query.await('SELECT * FROM dealer_stock', {})

        for k, v in ipairs(result) do
            result[k].data = v.data and json.decode(v.data) or nil
        end

        return result
    end,
    FetchDealer = function(self, dealerId)
        local result = MySQL.query.await('SELECT * FROM dealer_stock WHERE dealership = ?', { dealerId })

        for k, v in ipairs(result) do
            result[k].data = v.data and json.decode(v.data) or nil
        end

        return result
    end,
    FetchDealerVehicle = function(self, dealerId, vehModel)
        local result = MySQL.single.await('SELECT * FROM dealer_stock WHERE dealership = ? AND vehicle = ?', {
            dealerId,
            vehModel,
        })

        if result == nil then
            return false
        end

        result.data = result.data and json.decode(result.data) or nil

        return result
    end,
    HasVehicle = function(self, dealerId, vehModel)
        local vehicle = Dealerships.Stock:FetchDealerVehicle(dealerId, vehModel)
        if vehicle and vehicle.quantity > 0 then
            return vehicle.quantity
        else
            return false
        end
    end,
    Add = function(self, dealerId, vehModel, modelType, quantity, vehData)
        vehData = ValidateVehicleData(vehData)
        if _dealerships[dealerId] and vehModel and vehData and quantity > 0 then
            local isStocked = Dealerships.Stock:FetchDealerVehicle(dealerId, vehModel)
            if isStocked then -- The vehicle is already stocked
                local result = MySQL.query.await(
                    'UPDATE dealer_stock SET quantity = quantity + ?, `data` = ?, lastStocked = ? WHERE dealership = ? AND vehicle = ?',
                    {
                        quantity,
                        json.encode(vehData),
                        os.time(),
                        dealerId,
                        vehModel,
                    }
                )

                if result ~= nil then
                    return {
                        success = true,
                        existed = true,
                    }
                end
            else
                local result = MySQL.insert.await(
                    'INSERT INTO dealer_stock (dealership, vehicle, modelType, `data`, quantity, lastStocked) VALUES(?, ?, ?, ?, ?, ?)',
                    {
                        dealerId,
                        vehModel,
                        modelType,
                        json.encode(vehData),
                        quantity,
                        os.time(),
                    }
                )

                if result ~= nil then
                    return {
                        success = true,
                        existed = false,
                    }
                end
            end

            return false
        end
        return false
    end,
    Increase = function(self, dealerId, vehModel, amount)
        if _dealerships[dealerId] and vehModel and amount > 0 then
            local isStocked = Dealerships.Stock:FetchDealerVehicle(dealerId, vehModel)
            if isStocked then -- The vehicle is already stocked
                local result = MySQL.query.await(
                    'UPDATE dealer_stock SET quantity = quantity + ?, lastStocked = ? WHERE dealership = ? AND vehicle = ?',
                    {
                        amount,
                        os.time(),
                        dealerId,
                        vehModel,
                    }
                )

                if result ~= nil then
                    return { success = true }
                end

                return false
            else
                return false
            end
        end
        return false
    end,
    Update = function(self, dealerId, vehModel, setting)
        if _dealerships[dealerId] and vehModel and type(setting) == "table" then
            local isStocked = Dealerships.Stock:FetchDealerVehicle(dealerId, vehModel)
            if isStocked then -- The vehicle is already stocked
                local clauses, params = buildStockUpdate(setting)
                if #clauses == 0 then
                    return false
                end

                table.insert(params, dealerId)
                table.insert(params, vehModel)

                local result = MySQL.query.await(
                    string.format(
                        'UPDATE dealer_stock SET %s WHERE dealership = ? AND vehicle = ?',
                        table.concat(clauses, ', ')
                    ),
                    params
                )

                if result ~= nil then
                    return { success = true }
                end

                return false
            else
                return false
            end
        end
        return false
    end,
    Ensure = function(self, dealerId, vehModel, quantity, vehData)
        if _dealerships[dealerId] and vehModel then
            local isStocked = Dealerships.Stock:FetchDealerVehicle(dealerId, vehModel)
            if isStocked then
                local missingQuantity = quantity - isStocked.quantity
                if missingQuantity >= 1 then
                    return Dealerships.Stock:Add(dealerId, vehModel, missingQuantity, vehData)
                end
            else
                return Dealerships.Stock:Add(dealerId, vehModel, quantity, vehData)
            end
        end
        return false
    end,
    Remove = function(self, dealerId, vehModel, quantity)
        if _dealerships[dealerId] and vehModel and quantity > 0 then
            local isStocked = Dealerships.Stock:FetchDealerVehicle(dealerId, vehModel)

            if isStocked and isStocked.quantity > 0 then
                local newQuantity = isStocked.quantity - quantity
                if newQuantity >= 0 then
                    local result = MySQL.query.await(
                        'UPDATE dealer_stock SET quantity = ?, lastPurchase = ? WHERE dealership = ? AND vehicle = ?',
                        {
                            newQuantity,
                            os.time(),
                            dealerId,
                            vehModel,
                        }
                    )

                    if result ~= nil then
                        return newQuantity
                    end

                    return false
                end
            end
        end
        return false
    end,
}

local requiredAttributes = {
    make = 'string',
    model = 'string',
    class = 'string',
    category = 'string',
    price = 'number'
}

function ValidateVehicleData(data)
    if type(data) ~= 'table' then
        return false
    end
    for k, v in pairs(requiredAttributes) do
        if data[k] == nil or type(data[k]) ~= v then
            return false
        end
    end

    return data
end
