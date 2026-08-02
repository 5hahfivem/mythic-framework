function RegisterMiddleware()
	Middleware:Add("Characters:Spawning", function(source)
		TriggerLatentClientEvent("Properties:Client:Load", source, 800000, _properties)
	end)

	Middleware:Add("Characters:Logout", function(source)
		local char = Fetch:Source(source):GetData("Character")
		if char ~= nil then
			GlobalState[string.format("Char:Properties:%s", charId)] = nil
		end
		local property = GlobalState[string.format("%s:Property", source)]
		if property then
			TriggerClientEvent("Properties:Client:Cleanup", source, property)
			if _insideProperties[property] then
				_insideProperties[property][source] = nil
			end

			GlobalState[string.format("%s:Property", source)] = nil
		end

		if Player(source)?.state?.tpLocation then
			Player(source).state.tpLocation = nil
		end
	end)

	Middleware:Add("Characters:GetSpawnPoints", function(source, charId)
		local results = MySQL.query.await(
			"SELECT id FROM properties WHERE JSON_EXTRACT(`keys`, ?) IS NOT NULL AND foreclosed = 0 AND type NOT IN ('container', 'warehouse')",
			{ string.format('$."%s"', charId) }
		)

		if #results == 0 then
			return {}
		end

		local spawns = {}

		local keys = {}

		for k, v in pairs(results) do
			table.insert(keys, v.id)
			local property = _properties[v.id]
			if property ~= nil then
				local interior = property.upgrades?.interior
				local interiorData = PropertyInteriors[interior]

				local icon = "house"
				if property.type == "warehouse" then
					icon = "warehouse"
				elseif property.type == "office" then
					icon = "building"
				end

				if interiorData ~= nil then
					table.insert(spawns, {
						id = property.id,
						label = property.label,
						location = {
							x = interiorData.locations.front.coords.x,
							y = interiorData.locations.front.coords.y,
							z = interiorData.locations.front.coords.z,
							h = interiorData.locations.front.heading,
						},
						icon = icon,
						event = "Properties:SpawnInside",
					})
				end
			end
		end
		GlobalState[string.format("Char:Properties:%s", charId)] = keys

		return spawns
	end, 3)
end