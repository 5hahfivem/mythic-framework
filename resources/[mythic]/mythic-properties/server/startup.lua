local _ran = false

_properties = {}
_insideProperties = {}

function doPropertyThings(property)
	property.locked = property.locked or true

	property.location = property.location and json.decode(property.location) or nil
	property.upgrades = property.upgrades and json.decode(property.upgrades) or nil
	property.keys = property.keys and json.decode(property.keys) or nil
	property.data = property.data and json.decode(property.data) or nil
	property.owner = property.owner and json.decode(property.owner) or false
	property.sold = property.sold == 1
	property.foreclosed = property.foreclosed == 1

	if property.location then
		for k, v in pairs(property.location) do
			if v then
				for k2, v2 in pairs(v) do
					property.location[k][k2] = property.location[k][k2] + 0.0
				end
			end
		end
	end

	return property
end

function Startup()
	if _ran then
		return
	end

	local results = MySQL.query.await("SELECT * FROM properties", {})

	Logger:Trace("Properties", "Loaded ^2" .. #results .. "^7 Properties", { console = true })

	for k, v in ipairs(results) do
		_properties[v.id] = doPropertyThings(v)
	end

	_ran = true
end

RegisterNetEvent("Properties:RefreshProperties", function()
    local results = MySQL.query.await("SELECT * FROM properties", {})

    Logger:Warn("Properties", "Loaded ^2" .. #results .. "^7 Properties", { console = true })

    for k, v in ipairs(results) do
        _properties[v.id] = doPropertyThings(v)
    end
    TriggerLatentClientEvent("Properties:Client:Load", -1, 800000, _properties)
end)
