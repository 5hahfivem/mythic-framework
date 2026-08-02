AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['mythic-base']:RegisterComponent('EntityTypes', ENTITYTYPES)
end)

ENTITYTYPES = {
    Get = function(self, cb)
        local results = MySQL.query.await('SELECT * FROM entitytypes', {})

        for k, v in ipairs(results) do
            results[k].data = v.data and json.decode(v.data) or nil
        end

        cb(results)
    end,
    GetID = function(self, id, cb)
        cb(LoadedEntitys[id])
    end
}