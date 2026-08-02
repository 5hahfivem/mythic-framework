Spawns = {}

local _ran = false

function Startup()
	if _ran then
		return
	end

	local results = MySQL.query.await('SELECT * FROM locations WHERE Type = ?', { 'spawn' })

	Logger:Trace('Characters', 'Loaded ^2' .. #results .. '^7 Spawn Locations', { console = true })

	Spawns = { table.unpack(Config.DefaultSpawns) }
	for _, v in ipairs(results) do
		local coords = json.decode(v.Coords)
		local spawn = {
			id = v.id,
			label = v.Name,
			location = { x = coords.x, y = coords.y, z = coords.z, h = v.Heading },
		}
		table.insert(Spawns, spawn)
	end

	_ran = true
end

AddEventHandler('Locations:Server:Added', function(type, location)
	if type == 'spawn' then
		table.insert(Spawns, {
			label = location.Name,
			location = { x = location.Coords.x, y = location.Coords.y, z = location.Coords.z, h = location.Heading },
		})
		Logger:Info('Characters', 'New Spawn Point Created: ^5' .. location.Name, { console = true })
	end
end)
