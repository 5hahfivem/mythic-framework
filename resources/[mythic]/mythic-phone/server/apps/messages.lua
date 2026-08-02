PHONE.Messages = {
	Read = function(self, owner, number)
		MySQL.query.await("UPDATE phone_messages SET unread = 0 WHERE owner = ? AND number = ?", {
			owner,
			number,
		})
	end,
	Delete = function(self, owner, number)
		MySQL.query.await("UPDATE phone_messages SET deleted = 1 WHERE owner = ? AND number = ?", {
			owner,
			number,
		})
	end,
}

AddEventHandler("Phone:Server:RegisterMiddleware", function()
	Middleware:Add("Characters:Spawning", function(source)
		local char = Fetch:Source(source):GetData("Character")
		local messages = FetchPhoneMessages(char:GetData("Phone"))

		TriggerClientEvent("Phone:Client:SetData", source, "messages", messages)
	end, 2)
	Middleware:Add("Phone:UIReset", function(source)
		local char = Fetch:Source(source):GetData("Character")
		local messages = FetchPhoneMessages(char:GetData("Phone"))

		TriggerClientEvent("Phone:Client:SetData", source, "messages", messages)
	end, 2)
end)

AddEventHandler("Phone:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("Phone:Messages:SendMessage", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		local data2 = {
			owner = data.number,
			number = data.owner,
			message = data.message,
			time = data.time + 1,
			-- I Wanna Die Omegalul
			method = 0,
			unread = true,
		}
		local insertedIds = {
			InsertPhoneMessage(data),
			InsertPhoneMessage(data2),
		}

		do
			if insertedIds[1] == nil then
				cb(nil)
				return
			end
			local target = Fetch:CharacterData("Phone", data.number)
			if target ~= nil then
				data2.contact = Phone.Contacts:IsContact(char:GetData("ID"), data2.number)
				TriggerClientEvent("Phone:Client:Messages:Notify", target:GetData("Source"), data2, false)
			end
			cb(insertedIds[1])
		end
	end)

	Callbacks:RegisterServerCallback("Phone:Messages:ReadConvo", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		Phone.Messages:Read(char:GetData("Phone"), data)
	end)

	Callbacks:RegisterServerCallback("Phone:Messages:DeleteConvo", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		Phone.Messages:Delete(char:GetData("Phone"), data.number)
	end)
end)

function FetchPhoneMessages(owner)
	local rows = MySQL.query.await("SELECT * FROM phone_messages WHERE owner = ? AND deleted = 0", { owner })

	local messages = {}
	for k, v in ipairs(rows) do
		local message = json.decode(v.message)
		message._id = v.id
		message.unread = v.unread == 1
		table.insert(messages, message)
	end

	return messages
end

function InsertPhoneMessage(message)
	return MySQL.insert.await(
		"INSERT INTO phone_messages (owner, number, time, unread, deleted, message) VALUES(?, ?, ?, ?, 0, ?)",
		{
			message.owner,
			message.number,
			message.time,
			message.unread and 1 or 0,
			json.encode(message),
		}
	)
end
