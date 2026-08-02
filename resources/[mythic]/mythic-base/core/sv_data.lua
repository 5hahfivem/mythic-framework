local _data = {}
local _inserting = {}
local _schemas = {}

-- Seeded tables are a mix of typed rows (locations, properties) and document rows
-- (mdt_charges), so the columns a row actually maps to are read from the schema and
-- anything left over goes into the table's document column.
local function tableSchema(collection)
    if _schemas[collection] ~= nil then
        return _schemas[collection]
    end

    local rows = MySQL.query.await([[SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?]], { collection })

    local schema = {
        columns = {},
        documents = {},
    }

    for k, v in ipairs(rows or {}) do
        local name = v.COLUMN_NAME or v.column_name
        local dataType = v.DATA_TYPE or v.data_type

        schema.columns[name] = true
        if dataType == 'longtext' or dataType == 'text' then
            table.insert(schema.documents, name)
        end
    end

    _schemas[collection] = schema

    return schema
end

local function insertDefaults(collection, date, data)
    -- Prevents doing this operation multiple times because earlier
    -- Calls haven't finished yet
    while _inserting[collection] ~= nil do Wait(10) end

    for k, v in ipairs(data) do
        v.default = true
    end

    _inserting[collection] = true

    local schema = tableSchema(collection)

    if not schema.columns['default'] then
        COMPONENTS.Logger:Error('Data', ('%s Is Missing A `default` Column, Skipping Default Data'):format(collection), { console = true })
        _inserting[collection] = nil
        return
    end

    local existing = MySQL.single.await('SELECT date FROM defaults WHERE collection = ?', { collection })

    if existing == nil or existing.date < date then
        MySQL.query.await(('DELETE FROM `%s` WHERE `default` = 1'):format(collection), {})

        for k, v in ipairs(data) do
            local columns, values, document = {}, {}, {}

            for column, value in pairs(v) do
                if schema.columns[column] then
                    table.insert(columns, column)
                    table.insert(values, type(value) == 'table' and json.encode(value) or value)
                else
                    document[column] = value
                end
            end

            if next(document) ~= nil then
                for k2, name in ipairs(schema.documents) do
                    if v[name] == nil then
                        table.insert(columns, name)
                        table.insert(values, json.encode(document))
                        break
                    end
                end
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
