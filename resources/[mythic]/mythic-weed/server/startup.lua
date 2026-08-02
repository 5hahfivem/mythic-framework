local _started
function Startup()
	if _started then
		return
	end
	_started = true

	local results = MySQL.query.await("SELECT * FROM weed", {})
	local count = 0
	for k, v in ipairs(results) do
		if os.time() - v.planted <= Config.Lifetime then
			local plant = json.decode(v.plant)
			plant._id = v.id
			_plants[v.id] = {
				plant = plant,
				stage = getStageByPct(plant.growth),
			}
			count = count + 1
		end
	end
	Logger:Trace("Weed", string.format("Loaded ^2%s^7 Weed Plants", count), { console = true })

	Reputation:Create("weed", "Weed", {
		{ label = "Rank 1", value = 3000 },
		{ label = "Rank 2", value = 6000 },
		{ label = "Rank 3", value = 12000 },
		{ label = "Rank 4", value = 21000 },
		{ label = "Rank 5", value = 50000 },
	}, true)
end
