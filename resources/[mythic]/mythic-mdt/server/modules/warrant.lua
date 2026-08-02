_MDT.Warrants = {
	Search = function(self, term)
		return DecodeMdtRows(MySQL.query.await("SELECT * FROM mdt_warrants", {}), "warrant")
	end,
	View = function(self, id)
		return DecodeMdtRow(MySQL.single.await("SELECT * FROM mdt_warrants WHERE id = ?", { id }), "warrant")
	end,
	Create = function(self, data)
		local p = promise.new()
		local insertId = MySQL.insert.await("INSERT INTO mdt_warrants (state, warrant) VALUES(?, ?)", {
			data.state,
			json.encode(data),
		})

		if insertId == nil then
			p:resolve(false)
			return
		end
		data._id = insertId
		table.insert(_warrants, data)
		for user, _ in pairs(_onDutyUsers) do
			TriggerClientEvent("MDT:Client:AddData", user, "warrants", data)
		end
		for user, _ in pairs(_onDutyLawyers) do
			TriggerClientEvent("MDT:Client:AddData", user, "warrants", data)
		end
		p:resolve(true)

		GlobalState["MDT:Metric:Warrants"] = GlobalState["MDT:Metric:Warrants"] + 1
		return Citizen.Await(p)
	end,
	Update = function(self, id, state, updater)
	local p = promise.new()
	local warrant = MDT.Warrants:View(id)

	if warrant then
		warrant.state = state
		warrant.history = warrant.history or {}
		table.insert(warrant.history, updater)
	end

	local success = warrant and MySQL.query.await(
		"UPDATE mdt_warrants SET state = ?, warrant = ? WHERE id = ?",
		{ state, json.encode(warrant), id }
	) ~= nil

	if not success then
		p:resolve(false)
		return
	end

	for k, v in ipairs(_warrants) do
		if v._id == id then
			v.state = state

			for user, _ in pairs(_onDutyUsers) do
				TriggerClientEvent("MDT:Client:UpdateData", user, "warrants", id, v)
			end

			for user, _ in pairs(_onDutyLawyers) do
				TriggerClientEvent("MDT:Client:UpdateData", user, "warrants", id, v)
			end
		end
	end

	p:resolve(true)

	return Citizen.Await(p)
end,
	Delete = function(self, id)
		local success = MySQL.query.await("DELETE FROM mdt_warrants WHERE id = ?", { id }) ~= nil

		if not success then
			return false
		end

		for k, v in ipairs(_warrants) do
			if v._id == id then
				table.remove(_warrants, k)
				break
			end
		end

		for user, _ in pairs(_onDutyUsers) do
			TriggerClientEvent("MDT:Client:RemoveData", user, "warrants", id)
		end

		for user, _ in pairs(_onDutyLawyers) do
			TriggerClientEvent("MDT:Client:RemoveData", user, "warrants", id)
		end

		return true
	end,
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:Search:warrant", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
		cb(MDT.Warrants:Search(data.term))
	end)

	Callbacks:RegisterServerCallback("MDT:View:warrant", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Warrants:View(data))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Create:warrant", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")

		if char and CheckMDTPermissions(source, false) then
			data.doc.author = {
				SID = char:GetData("SID"),
				First = char:GetData("First"),
				Last = char:GetData("Last"),
				Callsign = char:GetData("Callsign"),
			}
			data.doc.ID = Sequence:Get("Warrant")
			cb(MDT.Warrants:Create(data.doc))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Update:warrant", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")

		if char and CheckMDTPermissions(source, false) then
			local updater = {
				SID = char:GetData("SID"),
				First = char:GetData("First"),
				Last = char:GetData("Last"),
				Callsign = char:GetData("Callsign"),
				Action = string.format("Updated Warrant State To: %s", data.state),
				Date = os.time() * 1000,
			}
			if CheckMDTPermissions(source, false) then
				cb(MDT.Warrants:Update(data.id, data.state, updater))
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Delete:warrant", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")

		if char and CheckMDTPermissions(source, true) then
			cb(MDT.Warrants:Delete(data.id))
		else
			cb(false)
		end
	end)
end)
