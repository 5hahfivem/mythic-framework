local _data = {}
local _inserting = {}

local function insertDefaults(collection, date, data)
    -- Prevents doing this operation multiple times because earlier
    -- Calls haven't finished yet
    while _inserting[collection] ~= nil do Wait(10) end

    for k, v in ipairs(data) do
        v.default = true
    end

    _inserting[collection] = true

    local existing = MySQL.single.await('SELECT date FROM defaults WHERE collection = ?', { collection })

    if existing == nil or existing.date < date then
        MySQL.query.await(('DELETE FROM `%s` WHERE `default` = 1'):format(collection), {})

        for k, v in ipairs(data) do
            local columns, values = {}, {}
            for column, value in pairs(v) do
                table.insert(columns, column)
                table.insert(values, type(value) == 'table' and json.encode(value) or value)
            end

            MySQL.query.await(('INSERT INTO `%s` (`%s`) VALUES(%s)'):format(
                collection,
                table.concat(columns, '`, `'),
                ('?, '):rep(#columns - 1) .. '?'
            ), values)
        end

        MySQL.query.await('INSERT INTO defaults (collection, date) VALUES(?, ?) ON DUPLICATE KEY UPDATE date = VALUES(date)', {
            collection,
            date,
        })

        COMPONENTS.Logger:Trace('Data', ('Added Default Data For %s'):format(collection), { console = true })
    end

    _inserting[collection] = nil
end

COMPONENTS.Default = {
    _required = { 'Add' },
    _name = { 'base' },
    _protected = true,
    Add = function(self, collection, date, data)
        insertDefaults(collection, date, data)
    end,
    AddAuth = function(self, collection, date, data)
        insertDefaults(collection, date, data)
    end
}
