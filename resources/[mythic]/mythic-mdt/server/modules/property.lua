_MDT.Properties = {
	Search = function(self, term)
		local search = string.format("%%%s%%", term)
		local rows = MySQL.query.await(
			[[SELECT * FROM properties
				WHERE type != 'container'
					AND (label LIKE ? OR CAST(JSON_EXTRACT(owner, '$.SID') AS CHAR) LIKE ?
						OR CONCAT(JSON_VALUE(owner, '$.First'), ' ', JSON_VALUE(owner, '$.Last')) LIKE ?)]],
			{ search, search, search }
		)

		GlobalState['MDT:Metric:Search'] = GlobalState['MDT:Metric:Search'] + 1

		local properties = {}
		for k, v in ipairs(rows) do
			table.insert(properties, doPropertySearchResult(v))
		end

		return properties
	end,
	View = function(self, id)
		local row = MySQL.single.await("SELECT * FROM properties WHERE id = ?", { id })

		if row == nil then
			return false
		end

		local property = doPropertySearchResult(row)

		property.foreclosed = row.foreclosed == 1
		property.soldAt = row.soldAt
		property.upgrades = row.upgrades and json.decode(row.upgrades) or nil

		if property.owner and property.owner.SID then
			property.owner.Person = MDT.People:View(property.owner.SID)
		end

		-- Keys are stored keyed by character id, the UI wants a plain list
		property.keys = {}
		if row.keys then
			for k, v in pairs(json.decode(row.keys)) do
				table.insert(property.keys, v)
			end
		end

		GlobalState['MDT:Metric:Search'] = GlobalState['MDT:Metric:Search'] + 1

		return property
	end,
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:Search:property", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Properties:Search(data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:View:property", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Properties:View(data))
		else
			cb(false)
		end
	end)
end)

function doPropertySearchResult(row)
	local property = {
		id = row.id,
		_id = row.id,
		label = row.label,
		type = row.type,
		price = row.price,
		sold = row.sold == 1,
		owner = row.owner and json.decode(row.owner) or false,
		location = row.location and json.decode(row.location) or nil,
	}

	return property
end
