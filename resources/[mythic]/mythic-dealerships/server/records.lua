-- Dealership Sale Records

DEALERSHIPS.Records = {
    Get = function(self, dealership)
        if _dealerships[dealership] then
            local results = MySQL.query.await(
                'SELECT * FROM dealer_records WHERE dealership = ? ORDER BY time DESC LIMIT 100',
                { dealership }
            )

            return DecodeRecords(results)
        end
        return false
    end,
    GetPage = function(self, category, term, dealership, page, perPage)
        if _dealerships[dealership] then
            local skip = 0
            if page > 1 then
                skip = perPage * (page - 1)
            end

            local query = 'SELECT * FROM dealer_records WHERE dealership = ?'
            local params = { dealership }

            if #term > 0 then
                query = query .. ' AND (sellerName LIKE ? OR buyerName LIKE ? OR vehicleName LIKE ?)'

                local search = string.format('%%%s%%', term)
                table.insert(params, search)
                table.insert(params, search)
                table.insert(params, search)
            end

            if category ~= "all" then
                query = query .. ' AND category = ?'
                table.insert(params, category)
            end

            query = query .. ' ORDER BY time DESC LIMIT ? OFFSET ?'
            table.insert(params, perPage + 1)
            table.insert(params, skip)

            local results = MySQL.query.await(query, params)

            local more = false
            if #results > perPage then
                more = true
                table.remove(results)
            end

            return {
                data = DecodeRecords(results),
                more = more,
            }
        end
        return false
    end,
    Create = function(self, dealership, document)
        if type(document) == 'table' then
            document.dealership = dealership

            local inserted = MySQL.insert.await(
                'INSERT INTO dealer_records (dealership, time, category, sellerName, buyerName, vehicleName, record) VALUES(?, ?, ?, ?, ?, ?, ?)',
                {
                    dealership,
                    document.time or os.time(),
                    document.vehicle?.data?.category,
                    RecordName(document.seller),
                    RecordName(document.buyer),
                    RecordName(document.vehicle?.data, 'make', 'model'),
                    json.encode(document),
                }
            )

            return inserted ~= nil
        end
        return false
    end,
    CreateBuyBack = function(self, dealership, document)
        if type(document) == 'table' then
            document.dealership = dealership

            local inserted = MySQL.insert.await(
                'INSERT INTO dealer_records_buybacks (dealership, time, record) VALUES(?, ?, ?)',
                {
                    dealership,
                    document.time or os.time(),
                    json.encode(document),
                }
            )

            return inserted ~= nil
        end
        return false
    end,
}

function DecodeRecords(records)
    for k, v in ipairs(records) do
        local record = json.decode(v.record)
        record.id = v.id
        records[k] = record
    end

    return records
end

function RecordName(data, first, last)
    if type(data) ~= 'table' then
        return nil
    end

    return string.format('%s %s', data[first or 'First'] or '', data[last or 'Last'] or '')
end
