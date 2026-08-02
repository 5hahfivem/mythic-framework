local _channels = {}

AddEventHandler("Phone:Server:RegisterMiddleware", function()
	Middleware:Add("Characters:Spawning", function(source)
		local char = Fetch:Source(source):GetData("Character")
		local channels = DecodePhoneRows(
			MySQL.query.await("SELECT * FROM irc_channels WHERE `character` = ?", { char:GetData("ID") }),
			"channel"
		)

		_channels[char:GetData("ID")] = channels
		TriggerClientEvent("Phone:Client:SetData", source, "ircChannels", channels)
	end, 2)
	Middleware:Add("Phone:UIReset", function(source)
		local char = Fetch:Source(source):GetData("Character")
		local channels = DecodePhoneRows(
			MySQL.query.await("SELECT * FROM irc_channels WHERE `character` = ?", { char:GetData("ID") }),
			"channel"
		)

		_channels[char:GetData("ID")] = channels
		TriggerClientEvent("Phone:Client:SetData", source, "ircChannels", channels)
	end, 2)
	Middleware:Add("Phone:CharacterCreated", function(source, cData)
		return {
			{
				app = "irc",
				alias = string.format("anon%s", cData.SID * (math.random(math.random(1000)))),
			},
		}
	end)
	Middleware:Add("Characters:Logout", function(source)
		local char = Fetch:Source(source):GetData("Character")
		if char ~= nil then
			_channels[char:GetData("ID")] = nil
		end
	end)
end)

local _cachedMessages = {}
AddEventHandler("Phone:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("Phone:IRC:GetMessages", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")

		local v = -1
		if _cachedMessages[data] == nil then
			_cachedMessages[data] = DecodePhoneRows(
				MySQL.query.await("SELECT * FROM irc_messages WHERE channel = ?", { data }),
				"message"
			)
			v = true
		else
			v = true
		end

		while v == -1 do
			Wait(10)
		end

		cb(_cachedMessages[data])
	end)
	Callbacks:RegisterServerCallback("Phone:IRC:SendMessage", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		local alias = char:GetData("Alias").irc
		_cachedMessages[data.channel] = _cachedMessages[data.channel] or {}

		local data2 = {
			from = alias,
			channel = data.channel,
			message = data.message,
			time = data.time,
		}
		local insertedIds = { MySQL.insert.await("INSERT INTO irc_messages (channel, time, message) VALUES(?, ?, ?)", {
			data2.channel,
			data2.time,
			json.encode(data2),
		}) }

		if insertedIds[1] == nil then
			cb(nil)
			return
		end
		data2._id = insertedIds[1]
		data2.time = data2.time * 1.0 -- Dear Lue, Die In A Fire
		table.insert(_cachedMessages[data.channel], data2)

		for k, v in pairs(_channels) do
			if k ~= char:GetData("ID") then
				for k2, channel in ipairs(v) do
					if channel.slug == data.channel then
						local tPlyr = Fetch:CharacterData("ID", k)
						if tPlyr ~= nil then
							local tChar = tPlyr:GetData("Character")
							if tChar ~= nil then
								TriggerClientEvent(
									"Phone:Client:IRC:Notify",
									tPlyr:GetData("Source"),
									data2,
									false
								)
							end
						end
						break
					end
				end
			end
		end
		cb(insertedIds[1])
	end)

	Callbacks:RegisterServerCallback("Phone:IRC:JoinChannel", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		local data2 = {
			slug = data.slug,
			joined = data.joined,
			character = char:GetData("ID"),
		}

		for k, v in ipairs(_channels[char:GetData("ID")]) do
			if v.slug == data2.slug then
				cb(false)
				return
			end
		end

		local insertedId = MySQL.insert.await("INSERT INTO irc_channels (`character`, slug, channel) VALUES(?, ?, ?)", {
			data2.character,
			data2.slug,
			json.encode(data2),
		})

		if insertedId == nil then
			cb(false)
			return
		end

		data2._id = insertedId
		table.insert(_channels[char:GetData("ID")], data2)

		cb(true)
	end)

	Callbacks:RegisterServerCallback("Phone:IRC:LeaveChannel", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		local success = MySQL.query.await("DELETE FROM irc_channels WHERE `character` = ? AND slug = ?", {
			char:GetData("ID"),
			data,
		}) ~= nil

		if not success then
			cb(false)
			return
		end

		for k, v in ipairs(_channels[char:GetData("ID")]) do
			if v.slug == data then
				table.remove(_channels[char:GetData("ID")], k)
				break
			end
		end

		cb(true)
	end)
end)
