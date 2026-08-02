local _runningBoloId = 0

_MDT.Misc = {
	Create = {
		BOLO = function (self, data)
			data._id = _runningBoloId
			table.insert(_bolos, data)
			GlobalState['MDT:Metric:BOLOs'] = GlobalState['MDT:Metric:BOLOs'] + 1
			for user, _ in pairs(_onDutyUsers) do
				TriggerClientEvent("MDT:Client:AddData", user, "bolos", data)
			end

			_runningBoloId = _runningBoloId + 1
		end,
		Charge = function(self, data)
			local p = promise.new()
			local insertIds = { MySQL.insert.await("INSERT INTO mdt_charges (charge) VALUES(?)", { json.encode(data) }) }

			if insertIds[1] == nil then
				p:resolve(false)
				return
			end

			data._id = insertIds[1]
			table.insert(_charges, data)
			for user, _ in pairs(_onDutyUsers) do
				TriggerClientEvent("MDT:Client:AddData", user, "charges", data)
			end
			for user, _ in pairs(_onDutyLawyers) do
				TriggerClientEvent("MDT:Client:AddData", user, "charges", data)
			end
			p:resolve(insertIds[1])
			return Citizen.Await(p)
		end,
		Tag = function(self, data)
			local p = promise.new()
			local insertIds = { MySQL.insert.await("INSERT INTO mdt_tags (tag) VALUES(?)", { json.encode(data) }) }

			if insertIds[1] == nil then
				p:resolve(false)
				return
			end

			data._id = insertIds[1]
			table.insert(_tags, data)
			for user, _ in pairs(_onDutyUsers) do
				TriggerClientEvent("MDT:Client:AddData", user, "tags", data)
			end
			for user, _ in pairs(_onDutyLawyers) do
				TriggerClientEvent("MDT:Client:AddData", user, "tags", data)
			end
			p:resolve(insertIds[1])
			return Citizen.Await(p)
		end,
		Notice = function(self, data)
			local p = promise.new()
			local insertIds = { MySQL.insert.await("INSERT INTO mdt_notices (notice) VALUES(?)", { json.encode(data) }) }

			if insertIds[1] == nil then
				p:resolve(false)
				return
			end

			data._id = insertIds[1]
			table.insert(_notices, data)

			for user, _ in pairs(_onDutyUsers) do
				TriggerClientEvent("MDT:Client:AddData", user, "notices", data)
			end
			for user, _ in pairs(_onDutyLawyers) do
				TriggerClientEvent("MDT:Client:AddData", user, "notices", data)
			end

			p:resolve(insertIds[1])
			return Citizen.Await(p)
		end,
	},
	Update = {
		Charge = function(self, id, data)
			local p = promise.new()
			local success = StoreMdtDoc('mdt_charges', 'charge', id, data)

			if not success then
				p:resolve(false)
				return
			end
			for k, v in ipairs(_charges) do
				if (v._id == id) then
					_charges[k] = data
					break
				end
			end

			-- if data.active then
			-- 	TriggerClientEvent("MDT:Client:UpdateData", -1, "charges", id, data)
			-- else
			-- 	TriggerClientEvent("MDT:Client:RemoveData", -1, "charges", id)
			-- end
			for user, _ in pairs(_onDutyUsers) do
				TriggerClientEvent("MDT:Client:UpdateData", user, "charges", id, data)
			end
			for user, _ in pairs(_onDutyLawyers) do
				TriggerClientEvent("MDT:Client:UpdateData", user, "charges", id, data)
			end
			p:resolve(true)
			return Citizen.Await(p)
		end,
		Tag = function(self, id, data)
			local p = promise.new()
			local success = StoreMdtDoc('mdt_tags', 'tag', id, data)

			if not success then
				p:resolve(false)
				return
			end

			for k, v in ipairs(_tags) do
				if (v._id == id) then
					_tags[k] = data
					break
				end
			end

			for user, _ in pairs(_onDutyUsers) do
				TriggerClientEvent("MDT:Client:UpdateData", user, "tags", id, data)
			end
			for user, _ in pairs(_onDutyLawyers) do
				TriggerClientEvent("MDT:Client:UpdateData", user, "tags", id, data)
			end
			p:resolve(true)
			return Citizen.Await(p)
		end,
	},
	Delete = {
		BOLO = function(self, id)
			for k, v in ipairs(_bolos) do
				if v._id == id then
					table.remove(_bolos, k)
					for user, _ in pairs(_onDutyUsers) do
						TriggerClientEvent("MDT:Client:RemoveData", user, "bolos", k)
					end
					return true
				end
			end

			return false
		end,
		Tag = function(self, id)
			local p = promise.new()
			local success = MySQL.query.await("DELETE FROM mdt_tags WHERE id = ?", { id }) ~= nil

			if not success then
				p:resolve(false)
				return
			end

			for k, v in ipairs(_tags) do
				if (v._id == id) then
					table.remove(_tags, k)
					break
				end
			end

			for user, _ in pairs(_onDutyUsers) do
				TriggerClientEvent("MDT:Client:RemoveData", user, "tags", id)
			end
			for user, _ in pairs(_onDutyLawyers) do
				TriggerClientEvent("MDT:Client:RemoveData", user, "tags", id)
			end
			p:resolve(true)
			return Citizen.Await(p)
		end,
		Notice = function(self, id)
			local p = promise.new()
			local success = MySQL.query.await("DELETE FROM mdt_notices WHERE id = ?", { id }) ~= nil

			if not success then
				p:resolve(false)
				return
			end

			for k, v in ipairs(_notices) do
				if (v._id == id) then
					table.remove(_notices, k)
					break
				end
			end

			for user, _ in pairs(_onDutyUsers) do
				TriggerClientEvent("MDT:Client:RemoveData", user, "notices", id)
			end
			for user, _ in pairs(_onDutyLawyers) do
				TriggerClientEvent("MDT:Client:RemoveData", user, "notices", id)
			end
			p:resolve(true)
			return Citizen.Await(p)
		end,
	}
}


AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:Create:BOLO", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
		if CheckMDTPermissions(source, false, 'police') then
			data.doc.author = {
				SID = char:GetData("SID"),
				First = char:GetData("First"),
				Last = char:GetData("Last"),
				Callsign = char:GetData("Callsign"),
			}
			MDT.Misc.Create:BOLO(data.doc)
			cb(true)
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Delete:BOLO", function(source, data, cb)
		if CheckMDTPermissions(source, false, 'police') then
			cb(MDT.Misc.Delete:BOLO(data.id))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Create:charge", function(source, data, cb)
		if CheckMDTPermissions(source, true) then
			data.doc.active = true
			cb(MDT.Misc.Create:Charge(data.doc))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Update:charge", function(source, data, cb)
		if CheckMDTPermissions(source, true) then
			cb(MDT.Misc.Update:Charge(data.doc._id, data.doc))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Create:tag", function(source, data, cb)
		if CheckMDTPermissions(source, true) then
			data.doc.active = true
			cb(MDT.Misc.Create:Tag(data.doc))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Update:tag", function(source, data, cb)
		if CheckMDTPermissions(source, true) then
			cb(MDT.Misc.Update:Tag(data.doc._id, data.doc))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Delete:tag", function(source, data, cb)
		if CheckMDTPermissions(source, true) then
			cb(MDT.Misc.Delete:Tag(data.id))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Create:notice", function(source, data, cb)
		if CheckMDTPermissions(source, {
			'PD_HIGH_COMMAND',
			'SAFD_HIGH_COMMAND',
		}) then
			cb(MDT.Misc.Create:Notice(data.doc))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Delete:notice", function(source, data, cb)
		if CheckMDTPermissions(source, {
			'PD_HIGH_COMMAND',
			'SAFD_HIGH_COMMAND',
		}) then
			cb(MDT.Misc.Delete:Notice(data.id))
		else
			cb(false)
		end
	end)
end)

function StoreMdtDoc(table_name, column, id, data)
	return MySQL.query.await(
		string.format('UPDATE `%s` SET `%s` = ? WHERE id = ?', table_name, column),
		{ json.encode(data), id }
	) ~= nil
end
