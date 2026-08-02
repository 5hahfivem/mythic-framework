PHONE.Contacts = {
	IsContact = function(self, myId, targetNumber)
		local row = MySQL.single.await("SELECT * FROM phone_contacts WHERE `character` = ? AND number = ?", {
			myId,
			targetNumber,
		})

		return DecodePhoneRow(row, "contact")
	end,
}

AddEventHandler("Phone:Server:RegisterMiddleware", function()
	Middleware:Add("Characters:Spawning", function(source)
		local char = Fetch:Source(source):GetData("Character")
		local contacts = DecodePhoneRows(
			MySQL.query.await("SELECT * FROM phone_contacts WHERE `character` = ?", { char:GetData("ID") }),
			"contact"
		)

		TriggerClientEvent("Phone:Client:SetData", source, "contacts", contacts)
	end, 2)
	Middleware:Add("Phone:UIReset", function(source)
		local char = Fetch:Source(source):GetData("Character")
		local contacts = DecodePhoneRows(
			MySQL.query.await("SELECT * FROM phone_contacts WHERE `character` = ?", { char:GetData("ID") }),
			"contact"
		)

		TriggerClientEvent("Phone:Client:SetData", source, "contacts", contacts)
	end, 2)
end)

AddEventHandler("Phone:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("Phone:Contacts:Create", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		if char then
			data.character = char:GetData("ID")
			local insertedId = MySQL.insert.await(
				"INSERT INTO phone_contacts (`character`, number, contact) VALUES(?, ?, ?)",
				{
					data.character,
					data.number,
					json.encode(data),
				}
			)

			if insertedId == nil then
				return cb(nil)
			end

			cb(insertedId)
		else
			cb(nil)
		end
	end)

	Callbacks:RegisterServerCallback("Phone:Contacts:Update", function(source, data, cb)
		if data.id == nil then
			return cb(nil)
		end

		local src = source
		local char = Fetch:Source(src):GetData("Character")
		if char then
			data.character = char:GetData("ID")
			local updated = MySQL.query.await(
				"UPDATE phone_contacts SET number = ?, contact = ? WHERE id = ? AND `character` = ?",
				{
					data.number,
					json.encode(data),
					data.id,
					char:GetData("ID"),
				}
			)

			if updated == nil then
				return cb(nil)
			end

			cb(true)
		else
			cb(nil)
		end
	end)

	Callbacks:RegisterServerCallback("Phone:Contacts:Delete", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		if char and data then
			cb(MySQL.query.await("DELETE FROM phone_contacts WHERE id = ? AND `character` = ?", {
				data,
				char:GetData("ID"),
			}) ~= nil)
		else
			cb(false)
		end
	end)
end)
