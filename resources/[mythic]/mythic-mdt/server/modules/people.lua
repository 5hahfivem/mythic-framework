local requiredCharacterData = {
	SID = 1,
	User = 1,
	First = 1,
	Last = 1,
	Gender = 1,
	Origin = 1,
	Jobs = 1,
	DOB = 1,
	Callsign = 1,
	Phone = 1,
	Licenses = 1,
	Qualifications = 1,
	Flags = 1,
	Mugshot = 1,
	MDTSystemAdmin = 1,
	MDTHistory = 1,
	Attorney = 1,
	LastClockOn = 1,
	TimeClockedOn = 1,
}

_MDT.People = {
	Search = {
		People = function(self, term)
			local search = string.format("%%%s%%", term)
			local results = MySQL.query.await(
				[[SELECT * FROM characters
					WHERE Deleted = 0 AND (CONCAT(First, ' ', Last) LIKE ? OR CAST(SID AS CHAR) LIKE ?)
					LIMIT 12]],
				{ search, search }
			)

			GlobalState["MDT:Metric:Search"] = GlobalState["MDT:Metric:Search"] + 1

			return DecodeMdtCharacters(results)
		end,
		Government = function(self)
			return DecodeMdtCharacters(MySQL.query.await(
				string.format(
					[[SELECT * FROM characters WHERE Deleted = 0 AND (%s)]],
					GovernmentJobClause()
				),
				_governmentJobs
			))
		end,
		NotGovernment = function(self)
			return DecodeMdtCharacters(MySQL.query.await(
				string.format(
					[[SELECT * FROM characters WHERE Deleted = 0 AND NOT (%s)]],
					GovernmentJobClause()
				),
				_governmentJobs
			))
		end,
		Job = function(self, job, term)
			local query = [[SELECT * FROM characters
				WHERE Deleted = 0 AND JSON_CONTAINS(JSON_EXTRACT(`character`, '$.Jobs'), JSON_OBJECT('Id', ?))]]
			local params = { job }

			if term then
				local search = string.format("%%%s%%", term)
				query = query .. " AND (CONCAT(First, ' ', Last) LIKE ? OR CAST(SID AS CHAR) LIKE ?) LIMIT 12"
				table.insert(params, search)
				table.insert(params, search)
			end

			return DecodeMdtCharacters(MySQL.query.await(query, params))
		end,
		NotJob = function(self, job)
			return DecodeMdtCharacters(MySQL.query.await(
				[[SELECT * FROM characters
					WHERE Deleted = 0 AND NOT JSON_CONTAINS(JSON_EXTRACT(`character`, '$.Jobs'), JSON_OBJECT('Id', ?))]],
				{ job }
			))
		end,
	},
	View = function(self, id, requireAllData)
		local SID = tonumber(id)
		local char = DecodeMdtCharacter(MySQL.single.await('SELECT * FROM characters WHERE SID = ?', { SID }))

		if not char then
			return false
		end

		if not requireAllData then
			return char
		end

		local convictions = DecodeMdtRow(
			MySQL.single.await('SELECT * FROM character_convictions WHERE SID = ?', { SID }),
			'convictions'
		)

		local vehicleRows = MySQL.query.await(
			"SELECT vehicle FROM vehicles WHERE ownerType = 0 AND ownerId = ?",
			{ SID }
		)

		local vehicles = {}
		for k, v in ipairs(vehicleRows) do
			table.insert(vehicles, json.decode(v.vehicle))
		end

		local ownedBusinesses = {}
		if char.Jobs then
			for k, v in ipairs(char.Jobs) do
				local jobData = Jobs:Get(v.Id)
				if jobData.Owner and jobData.Owner == char.SID then
					table.insert(ownedBusinesses, v.Id)
				end
			end
		end

		return {
			data = char,
			convictions = convictions,
			vehicles = vehicles,
			ownedBusinesses = ownedBusinesses,
		}
	end,

	Update = function(self, requester, id, key, value)
		local p = promise.new()
		local logVal = value
		if type(value) == "table" then
			logVal = json.encode(value)
		end

		local historyEntry
		if requester == -1 then
			historyEntry = {
				Time = (os.time() * 1000),
				Char = -1,
				Log = string.format("System Updated Profile, Set %s To %s", key, logVal),
			}
		else
			historyEntry = {
				Time = (os.time() * 1000),
				Char = requester:GetData("SID"),
				Log = string.format(
					"%s Updated Profile, Set %s To %s",
					requester:GetData("First") .. " " .. requester:GetData("Last"),
					key,
					logVal
				),
			}
		end

		local character = DecodeMdtCharacter(MySQL.single.await('SELECT * FROM characters WHERE SID = ?', { id }))

		if character then
			character[key] = value
			character.MDTHistory = character.MDTHistory or {}
			table.insert(character.MDTHistory, historyEntry)
		end

		local success = character and MySQL.query.await(
			'UPDATE characters SET `character` = ? WHERE SID = ?',
			{ json.encode(character), id }
		) ~= nil

		do
			if success then
				local target = Fetch:SID(id)
				if target then
					target:GetData("Character"):SetData(key, value)
				end
			end
			p:resolve(success)
		end
		return Citizen.Await(p)
	end,
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:Search:people", function(source, data, cb)
		cb(MDT.People.Search:People(data.term))
	end)

	Callbacks:RegisterServerCallback("MDT:Search:government", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.People.Search:Government(data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Search:not-government", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.People.Search:NotGovernment(data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Search:job", function(source, data, cb)
		if CheckMDTPermissions(source, false) or CheckBusinessPermissions(source) then
			cb(MDT.People.Search:Job(data.job, data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Search:not-job", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.People.Search:NotJob(data.job, data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:View:person", function(source, data, cb)
		cb(MDT.People:View(data, true))
	end)

	Callbacks:RegisterServerCallback("MDT:Update:person", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
		if char and CheckMDTPermissions(source, false) and data.SID then
			cb(MDT.People:Update(char, data.SID, data.Key, data.Data))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:CheckCallsign", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			local count = MySQL.scalar.await(
				[[SELECT COUNT(*) FROM characters WHERE JSON_EXTRACT(`character`, '$.Callsign') = ?]],
				{ data }
			)

			cb(count == 0)
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:CheckParole", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			local character = DecodeMdtCharacter(MySQL.single.await('SELECT * FROM characters WHERE SID = ?', { data }))

			if character and character.Parole ~= nil then
				cb(character.Parole)
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)
end)

function GovernmentJobClause()
	local clauses = {}

	for k, v in ipairs(_governmentJobs) do
		table.insert(clauses, "JSON_CONTAINS(JSON_EXTRACT(`character`, '$.Jobs'), JSON_OBJECT('Id', ?))")
	end

	if #clauses == 0 then
		return '1 = 0'
	end

	return table.concat(clauses, ' OR ')
end

function DecodeMdtCharacter(row)
	if row == nil then
		return false
	end

	local character = json.decode(row.character)
	character._id = row.id

	return character
end

function DecodeMdtCharacters(rows)
	local characters = {}

	for k, v in ipairs(rows) do
		table.insert(characters, DecodeMdtCharacter(v))
	end

	return characters
end
