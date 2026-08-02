local _selling = {}
local _pendingLoanAccept = {}

local govCut = 5
local commissionCut = 5
local companyCut = 10

AddEventHandler("Phone:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("Phone:Dyn8:Search", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
		if char then
			local qry = {
				label = {
					["$regex"] = data,
					["$options"] = "i",
				},
				sold = false,
			}

			if Player(source).state.onDuty == 'realestate' then
				qry = {
					label = {
						["$regex"] = data,
						["$options"] = "i",
					},
				}
			end

			local rows = MySQL.query.await(
				"SELECT * FROM properties WHERE label LIKE ? LIMIT 80",
				{ string.format("%%%s%%", data) }
			)

			local results = {}
			for k, v in ipairs(rows) do
				local property = json.decode(v.location)
				table.insert(results, {
					id = v.id,
					label = v.label,
					type = v.type,
					location = property,
				})
			end

			cb(results)
		else
			cb(false)
		end
	end)
end)



