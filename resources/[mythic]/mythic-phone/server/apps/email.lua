PHONE.Email = {
	Read = function(self, charId, id)
		return MySQL.query.await("UPDATE character_emails SET unread = 0 WHERE id = ?", { id }) ~= nil
	end,
	Send = function(self, serverId, sender, time, subject, body, flags)
		local plyr = Fetch:Source(serverId)
		if plyr ~= nil then
			local char = plyr:GetData("Character")
			if char ~= nil then
				local doc = {
					owner = char:GetData("ID"),
					sender = sender,
					time = time,
					subject = subject,
					body = body,
					unread = true,
					flags = flags,
				}
				local insertedId = MySQL.insert.await(
					"INSERT INTO character_emails (owner, time, unread, expires, email) VALUES(?, ?, 1, ?, ?)",
					{
						doc.owner,
						doc.time,
						doc.flags?.expires or 0,
						json.encode(doc),
					}
				)

				if insertedId ~= nil then
					doc._id = insertedId
					TriggerClientEvent("Phone:Client:Email:Receive", serverId, doc)
				end
			end
		end
	end,
	Delete = function(self, charId, id)
		local success = MySQL.query.await("DELETE FROM character_emails WHERE id = ? AND owner = ?", {
			id,
			charId,
		}) ~= nil

		if success then
			local char = Fetch:ID(charId)
			if char then
				TriggerClientEvent("Phone:Client:Email:Delete", char:GetData("Source"), id)
			end
		end

		return success
	end,
}

AddEventHandler("Phone:Server:RegisterMiddleware", function()
	Middleware:Add("Characters:Spawning", function(source)
		local char = Fetch:Source(source):GetData("Character")
		local emails = DecodePhoneRows(
			MySQL.query.await("SELECT * FROM character_emails WHERE owner = ?", { char:GetData("ID") }),
			"email"
		)

		TriggerClientEvent("Phone:Client:SetData", source, "emails", emails)
	end, 2)
	Middleware:Add("Phone:UIReset", function(source)
		local char = Fetch:Source(source):GetData("Character")
		local emails = DecodePhoneRows(
			MySQL.query.await("SELECT * FROM character_emails WHERE owner = ?", { char:GetData("ID") }),
			"email"
		)

		TriggerClientEvent("Phone:Client:SetData", source, "emails", emails)
	end, 2)
	Middleware:Add("Phone:CharacterCreated", function(source, cData)
		return {
			{
				app = "email",
				alias = string.format("%s_%s%s@mythicmail.net", cData.First, cData.Last, cData.SID),
			},
		}
	end)
end)

AddEventHandler("Phone:Server:RegisterCallbacks", function()
	Chat:RegisterAdminCommand("email", function(source, args, rawCommand)
		local plyr = Fetch:CharacterData("SID", tonumber(args[1]))
		if plyr ~= nil then
			Phone.Email:Send(plyr:GetData("Source"), args[2], os.time() * 1000, args[3], args[4])
		else
			Chat.Send.System:Single(source, "Invalid State ID")
		end
	end, {
		help = "Send Email To Player",
		params = {
			{
				name = "Target",
				help = "State ID",
			},
			{
				name = "Sender Email",
				help = "Email To Show As Sender, EX: scaryman@something.net",
			},
			{
				name = "Subject",
				help = "Subject Line Of Email",
			},
			{
				name = "Body",
				help = "Body of email to send",
			},
		},
	}, 4)

	Callbacks:RegisterServerCallback("Phone:Email:Read", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		cb(Phone.Email:Read(char:GetData("Phone"), data))
	end)

	Callbacks:RegisterServerCallback("Phone:Email:Delete", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		cb(Phone.Email:Delete(char:GetData("ID"), data))
	end)

	Callbacks:RegisterServerCallback("Phone:Email:DeleteExpired", function(source, data, cb)
		local src = source

		local plyr = Fetch:Source(src)
		if plyr ~= nil then
			local char = plyr:GetData("Character")
			if char ~= nil then
				local expired = MySQL.query.await(
					"SELECT id FROM character_emails WHERE owner = ? AND expires > 0 AND expires < ?",
					{ char:GetData("ID"), os.time() * 1e3 }
				)

				MySQL.query.await(
					"DELETE FROM character_emails WHERE owner = ? AND expires > 0 AND expires < ?",
					{ char:GetData("ID"), os.time() * 1e3 }
				)

				local ids = {}
				for k, v in ipairs(expired) do
					table.insert(ids, v.id)
				end

				cb(ids)
			end
		end
	end)
end)
