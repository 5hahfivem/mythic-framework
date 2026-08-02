local _banColumns = {
	_id = "id",
	account = "account",
	identifier = "identifier",
}

local function fetchBans(key, value)
	local column = _banColumns[key]
	if column == nil then
		COMPONENTS.Logger:Error(
			"Database",
			"[^8Error^7] Invalid Ban Lookup: " .. tostring(key),
			{ console = true, file = true, database = true }
		)
		return {}
	end

	local results = MySQL.query.await(("SELECT * FROM bans WHERE %s = ? AND active = 1"):format(column), { value })

	for k, v in ipairs(results) do
		results[k]._id = v.id
		results[k].tokens = v.tokens and json.decode(v.tokens) or {}
	end

	return results
end

COMPONENTS.Punishment = {
	_required = { "CheckBan", "Kick", "Unban", "Ban" },
	_name = "base",
	CheckBan = function(self, key, value)
		local results = fetchBans(key, value)

		for k, v in ipairs(results) do
			if v.expires < os.time() and v.expires ~= -1 then
				MySQL.query.await("UPDATE bans SET active = 0 WHERE id = ?", { v.id })
			else
				return v
			end
		end

		return nil
	end,
	Kick = function(self, source, reason, issuer)
		local tPlayer = COMPONENTS.Fetch:Source(source)

		if not tPlayer then
			return {
				success = false,
			}
		end

		if issuer ~= "Pwnzor" then
			if source == issuer then
				return {
					success = false,
					message = "Cannot Ban Yourself!",
				}
			end

			local iPlayer = COMPONENTS.Fetch:Source(issuer)

			if not iPlayer then
				return {
					success = false,
				}
			end

			if iPlayer.Permissions:GetLevel() <= tPlayer.Permissions:GetLevel() then
				return {
					success = false,
					message = "Insufficient Permissions",
				}
			end

			COMPONENTS.Punishment.Actions:Kick(source, reason, iPlayer:GetData("Name"))

			COMPONENTS.Logger:Info(
				"Punishment",
				string.format(
					"%s [%s] Kicked By %s [%s] For %s",
					tPlayer:GetData("Name"),
					tPlayer:GetData("AccountID"),
					iPlayer:GetData("Name"),
					iPlayer:GetData("AccountID"),
					reason
				),
				{ console = true, file = true, database = true, discord = { embed = true, type = "inform" } },
				{
					account = tPlayer:GetData("AccountID"),
					identifier = tPlayer:GetData("Identifier"),
					reason = reason,
					issuer = string.format("%s [%s]", iPlayer:GetData("Name"), iPlayer:GetData("AccountID")),
				}
			)

			return {
				success = true,
				Name = tPlayer:GetData("Name"),
				AccountID = tPlayer:GetData("AccountID"),
				reason = reason,
			}
		else
			COMPONENTS.Punishment.Actions:Kick(source, reason, issuer)

			COMPONENTS.Logger:Info(
				"Punishment",
				string.format(
					"%s [%s] Kicked By %s For %s",
					tPlayer:GetData("Name"),
					tPlayer:GetData("AccountID"),
					issuer,
					reason
				),
				{
					console = true,
					file = true,
					database = true,
					discord = { embed = true, type = "inform", webhook = GetConvar("discord_pwnzor_webhook", "") },
				},
				{
					account = tPlayer:GetData("AccountID"),
					identifier = tPlayer:GetData("Identifier"),
					reason = reason,
					issuer = issuer,
				}
			)

			return {
				success = true,
				Name = tPlayer:GetData("Name"),
				AccountID = tPlayer:GetData("AccountID"),
				reason = reason,
			}
		end
	end,
}

COMPONENTS.Punishment.Unban = {
	BanID = function(self, id, issuer)
		if COMPONENTS.Punishment:CheckBan("_id", id) then
			local iPlayer = COMPONENTS.Fetch:Source(issuer)

			if COMPONENTS.Punishment.Actions:Unban(fetchBans("_id", id), iPlayer) then
				COMPONENTS.Chat.Send.Server:Single(
					iPlayer:GetData("Source"),
					string.format("%s Has Been Revoked", id)
				)
			end
		end
	end,
	AccountID = function(self, aId, issuer)
		if COMPONENTS.Punishment:CheckBan("account", aId) then
			local tPlayer = COMPONENTS.Fetch:PlayerData("AccountID", aId)
			local dbf = false

			if tPlayer == nil then
				tPlayer = COMPONENTS.Fetch:Website("account", aId)
				dbf = true
			end

			local iPlayer = COMPONENTS.Fetch:Source(issuer)

			if COMPONENTS.Punishment.Actions:Unban(fetchBans("account", aId), iPlayer) then
				COMPONENTS.Chat.Send.Server:Single(
					iPlayer:GetData("Source"),
					string.format(
						"%s (Account: %s) Has Been Unbanned",
						tPlayer:GetData("Name"),
						tPlayer:GetData("AccountID")
					)
				)
			end

			if dbf then
				tPlayer:DeleteStore()
			end
		else
			COMPONENTS.Chat.Send.Server:Single(
				iPlayer:GetData("Source"),
				string.format("%s (Account: %s) Is Not Banned", tPlayer:GetData("Name"), tPlayer:GetData("AccountID"))
			)
		end
	end,
	Identifier = function(self, identifier, issuer)
		if COMPONENTS.Punishment:CheckBan("identifier", identifier) then
			local tPlayer = COMPONENTS.Fetch:PlayerData("Identifier", identifier)
			local dbf = false
			if tPlayer == nil then
				tPlayer = COMPONENTS.Fetch:Website("identifier", identifier)
				dbf = true
			end
			local iPlayer = COMPONENTS.Fetch:Source(issuer)

			if COMPONENTS.Punishment.Actions:Unban(fetchBans("identifier", identifier), iPlayer) then
				COMPONENTS.Chat.Send.Server:Single(
					iPlayer:GetData("Source"),
					string.format(
						"%s (Identifier: %s) Has Been Unbanned",
						tPlayer:GetData("Name"),
						tPlayer:GetData("Identifier")
					)
				)
			end

			if dbf then
				tPlayer:DeleteStore()
			end
		else
			COMPONENTS.Chat.Send.Server:Single(
				iPlayer:GetData("Source"),
				string.format(
					"%s (Identifier: %s) Is Not Banned",
					tPlayer:GetData("Name"),
					tPlayer:GetData("Identifier")
				)
			)
		end
	end,
}

COMPONENTS.Punishment.Ban = {
	Source = function(self, source, expires, reason, issuer)
		local tPlayer = COMPONENTS.Fetch:Source(source)
		local iPlayer

		if not tPlayer then
			return {
				success = false,
			}
		end

		if issuer ~= "Pwnzor" then
			if source == issuer then
				return {
					success = false,
					message = "Cannot Ban Yourself!",
				}
			end

			iPlayer = COMPONENTS.Fetch:Source(issuer)
			if not iPlayer then
				return {
					success = false,
				}
			end

			if iPlayer.Permissions:GetLevel() < tPlayer.Permissions:GetLevel() then
				return {
					success = false,
					message = "Insufficient Permissions",
				}
			end

			issuer = string.format("%s [%s]", iPlayer:GetData("Name"), iPlayer:GetData("AccountID"))
		end

		local expStr = "Never"
		if expires ~= -1 then
			expires = (os.time() + ((60 * 60 * 24) * expires))
			expStr = os.date("%Y-%m-%d at %I:%M:%S %p", expires)
		end

		local banStr = string.format("%s Was Permanently Banned By %s for %s", tPlayer:GetData("Name"), issuer, reason)

		if expires ~= -1 then
			banStr = string.format(
				"%s Was Banned By %s Until %s for %s",
				tPlayer:GetData("Name"),
				issuer,
				expStr,
				reason
			)
		end

		if iPlayer ~= nil then
			COMPONENTS.Punishment.Actions:Ban(
				tPlayer:GetData("Source"),
				tPlayer:GetData("AccountID"),
				tPlayer:GetData("Identifier"),
				tPlayer:GetData("Name"),
				tPlayer:GetData("Tokens"),
				reason,
				expires,
				expStr,
				issuer,
				iPlayer:GetData("AccountID"),
				false
			)

			return {
				success = true,
				Name = tPlayer:GetData("Name"),
				AccountID = tPlayer:GetData("AccountID"),
				expires = expires,
				reason = reason,
				banStr = banStr,
			}
		else
			COMPONENTS.Punishment.Actions:Ban(
				tPlayer:GetData("Source"),
				tPlayer:GetData("AccountID"),
				tPlayer:GetData("Identifier"),
				tPlayer:GetData("Name"),
				tPlayer:GetData("Tokens"),
				reason,
				expires,
				expStr,
				issuer,
				-1,
				true
			)

			return {
				success = true,
				Name = tPlayer:GetData("Name"),
				AccountID = tPlayer:GetData("AccountID"),
				expires = expires,
				reason = reason,
				banStr = banStr,
			}
		end

		COMPONENTS.Logger:Info(
			"Punishment",
			banStr,
			{ console = true, file = true, database = true, discord = { embed = true, type = "info" } },
			{
				player = tPlayer:GetData("Name"),
				identifier = tPlayer:GetData("Identifier"),
				reason = reason,
				issuer = issuer,
				expires = expStr,
			}
		)
	end,
	AccountID = function(self, aId, expires, reason, issuer)
		local iPlayer = COMPONENTS.Fetch:Source(issuer)
		if not iPlayer then
			return {
				success = false,
			}
		end

		if iPlayer:GetData("AccountID") == tonumber(aid) then
			return {
				success = false,
				message = "Cannot Ban Yourself!",
			}
		end

		local tPlayer = COMPONENTS.Fetch:PlayerData("AccountID", tonumber(aId))

		issuer = string.format("%s [%s]", iPlayer:GetData("Name"), iPlayer:GetData("AccountID"))

		local dbf = false
		if tPlayer == nil then
			tPlayer = COMPONENTS.Fetch:Website("account", tonumber(aId))
			dbf = true
		end

		local bannedPlayer = tonumber(aId)

		local expStr = "Never"
		if expires ~= -1 then
			expires = (os.time() + ((60 * 60 * 24) * expires))
			expStr = os.date("%Y-%m-%d at %I:%M:%S %p", expires)
		end

		local banStr = string.format(
			"%s (Account: %s) Was Permanently Banned By %s. Reason: %s",
			tPlayer and tPlayer:GetData("Name") or "Unknown",
			tPlayer and tPlayer:GetData("AccountID") or bannedPlayer,
			issuer,
			reason
		)

		if expires ~= -1 then
			banStr = string.format(
				"%s (Account: %s) Was Banned By %s Until %s. Reason: %s",
				(tPlayer and tPlayer:GetData("Name") or "Unknown"),
				(tPlayer and tPlayer:GetData("AccountID") or bannedPlayer),
				issuer,
				expStr,
				reason
			)
		end

		if tPlayer == nil then
			if
				COMPONENTS.Punishment.Actions:Ban(
					nil,
					tonumber(aId),
					nil,
					bannedPlayer,
					{},
					reason,
					expires,
					expStr,
					issuer,
					iPlayer:GetData("AccountID"),
					false
				)
			then
				COMPONENTS.Logger:Info(
					"Punishment",
					banStr,
					{ console = true, file = true, database = true, discord = { embed = true, type = "info" } },
					{
						player = bannedPlayer,
						account = tonumber(aId),
						reason = reason,
						issuer = issuer,
						expires = expStr,
					}
				)

				return {
					success = true,
					AccountID = tonumber(aId),
					reason = reason,
					expires = expires,
					banStr = banStr,
				}
			end
		else
			local tPerms = 0

			if tPlayer:GetData("Source") ~= nil then
				for k, v in ipairs(tPlayer:GetData("Groups")) do
					if COMPONENTS.Config.Groups[tostring(v)].Permission then
						if COMPONENTS.Config.Groups[tostring(v)].Permission.Level > tPerms then
							tPerms = COMPONENTS.Config.Groups[tostring(v)].Permission.Level
						end
					end
				end
			else
				-- Offline so Cannot Get Groups - Just allow devs for now
				tPerms = 99
			end

			if iPlayer.Permissions:GetLevel() <= tPerms then
				return {
					success = false,
					message = "Insufficient Permissions",
				}
			end

			if
				COMPONENTS.Punishment.Actions:Ban(
					tPlayer:GetData("Source"),
					tPlayer:GetData("AccountID"),
					tPlayer:GetData("Identifier"),
					tPlayer:GetData("Name"),
					tPlayer:GetData("Tokens"),
					reason,
					expires,
					expStr,
					issuer,
					iPlayer:GetData("AccountID"),
					false
				)
			then
				COMPONENTS.Logger:Info(
					"Punishment",
					banStr,
					{ console = true, file = true, database = true, discord = { embed = true, type = "info" } },
					{
						player = bannedPlayer,
						account = tPlayer:GetData("AccountID"),
						identifier = tPlayer:GetData("Identifier"),
						reason = reason,
						issuer = issuer,
						expires = expStr,
					}
				)

				local retData = {
					success = true,
					Name = tPlayer:GetData("Name"),
					AccountID = tPlayer:GetData("AccountID"),
					expires = expires,
					reason = reason,
					banStr = banStr,
				}

				CreateThread(function()
					if dbf and tPlayer then
						tPlayer:DeleteStore()
					end
				end)

				return retData
			end
		end
	end,
	Identifier = function(self, identifier, expires, reason, issuer)
		local iPlayer = COMPONENTS.Fetch:Source(issuer)
		if not iPlayer then
			return {
				success = false,
			}
		end

		if iPlayer:GetData("Identifier") == identifier then
			return {
				success = false,
				message = "Cannot Ban Yourself!",
			}
		end

		local tPlayer = COMPONENTS.Fetch:PlayerData("Identifier", identifier)

		issuer = string.format("%s [%s]", iPlayer:GetData("Name"), iPlayer:GetData("AccountID"))

		local dbf = false
		if tPlayer == nil then
			tPlayer = COMPONENTS.Fetch:Website("identifier", identifier)
			dbf = true
		end

		local expStr = "Never"
		if expires ~= -1 then
			expires = (os.time() + ((60 * 60 * 24) * expires))
			expStr = os.date("%Y-%m-%d at %I:%M:%S %p", expires)
		end

		local banStr = string.format(
			"%s (Identifier: %s) Was Permanently Banned By %s. Reason: %s",
			tPlayer and tPlayer:GetData("Name") or "Unknown",
			tPlayer and tPlayer:GetData("Identifier") or identifier,
			issuer,
			reason
		)
		if expires ~= -1 then
			banStr = string.format(
				"%s (Identifier: %s) Was Banned By %s Until %s. Reason: %s",
				tPlayer and tPlayer:GetData("Name") or "Unknown",
				tPlayer and tPlayer:GetData("Identifier") or identifier,
				issuer,
				expStr,
				reason
			)
		end

		if tPlayer == nil then
			if
				COMPONENTS.Punishment.Actions:Ban(
					nil,
					nil,
					identifier,
					bannedPlayer,
					{},
					reason,
					expires,
					expStr,
					issuer,
					iPlayer:GetData("ID"),
					false
				)
			then
				COMPONENTS.Logger:Info(
					"Punishment",
					banStr,
					{ console = true, file = true, database = true, discord = { embed = true, type = "info" } },
					{
						player = identifier,
						identifier = identifier,
						reason = reason,
						issuer = issuer,
						expires = expStr,
					}
				)

				if dbf and tPlayer then
					tPlayer:DeleteStore()
				end

				return {
					success = true,
					Identifier = identifier,
					reason = reason,
					expires = expires,
					banStr = banStr,
				}
			end
		else
			local tPerms = 0

			if tPlayer:GetData("Source") ~= nil then
				for k, v in ipairs(tPlayer:GetData("Groups")) do
					if COMPONENTS.Config.Groups[tostring(v)].Permission then
						if COMPONENTS.Config.Groups[tostring(v)].Permission.Level > tPerms then
							tPerms = COMPONENTS.Config.Groups[tostring(v)].Permission.Level
						end
					end
				end
			else
				for k, v in ipairs(tPlayer:GetData("Groups")) do
					if COMPONENTS.Config.Groups[tostring(v)].Permission then
						if COMPONENTS.Config.Groups[tostring(v)].Permission.Level > tPerms then
							tPerms = COMPONENTS.Config.Groups[tostring(v)].Permission.Level
						end
					end
				end
			end

			if iPlayer.Permissions:GetLevel() <= tPerms then
				return {
					success = false,
					message = "Insufficient Permissions",
				}
			end

			if
				COMPONENTS.Punishment.Actions:Ban(
					tPlayer:GetData("Source"),
					tPlayer:GetData("AccountID"),
					tPlayer:GetData("Identifier"),
					tPlayer:GetData("Name"),
					tPlayer:GetData("Tokens"),
					reason,
					expires,
					expStr,
					issuer,
					false
				)
			then
				COMPONENTS.Logger:Info(
					"Punishment",
					banStr,
					{ console = true, file = true, database = true, discord = { embed = true, type = "info" } },
					{
						player = tPlayer:GetData("Name"),
						account = tPlayer:GetData("AccountID"),
						identifier = tPlayer:GetData("Identifier"),
						reason = reason,
						issuer = issuer,
						expires = expStr,
					}
				)

				local retData = {
					success = true,
					Name = tPlayer:GetData("Name"),
					AccountID = tPlayer:GetData("AccountID"),
					Identifier = tPlayer:GetData("Identifier"),
					expires = expires,
					reason = reason,
					banStr = banStr,
				}

				if dbf and tPlayer then
					tPlayer:DeleteStore()
				end

				return retData
			end
		end

		if dbf then
			tPlayer:DeleteStore()
		end
	end,
}

COMPONENTS.Punishment.Actions = {
	Kick = function(self, tSource, reason, issuer)
		DropPlayer(tSource, string.format("Kicked From The Server By %s\nReason: %s", issuer, reason))
	end,
	Ban = function(self, tSource, tAccount, tIdentifier, tName, tTokens, reason, expires, expStr, issuer, issuerId, mask)
		local orStatement = {}
		local orParams = {}
		if tAccount then
			table.insert(orStatement, "account = ?")
			table.insert(orParams, tAccount)
		end

		if tIdentifier then
			table.insert(orStatement, "identifier = ?")
			table.insert(orParams, tIdentifier)
		end

		local existing = nil
		if #orStatement > 0 then
			existing = MySQL.single.await(
				("SELECT id, tokens FROM bans WHERE active = 1 AND (%s)"):format(table.concat(orStatement, " OR ")),
				orParams
			)
		end

		local tokens = {}
		local hasToken = {}
		if existing ~= nil and existing.tokens ~= nil then
			tokens = json.decode(existing.tokens)
			for k, v in ipairs(tokens) do
				hasToken[v] = true
			end
		end

		for k, v in ipairs(tTokens or {}) do
			if not hasToken[v] then
				hasToken[v] = true
				table.insert(tokens, v)
			end
		end

		local banId = existing?.id
		if banId ~= nil then
			MySQL.query.await(
				"UPDATE bans SET account = ?, identifier = ?, expires = ?, reason = ?, issuer = ?, active = 1, started = ?, tokens = ? WHERE id = ?",
				{ tAccount, tIdentifier, expires, reason, issuer, os.time(), json.encode(tokens), banId }
			)
		else
			banId = MySQL.insert.await(
				"INSERT INTO bans (account, identifier, expires, reason, issuer, active, started, tokens) VALUES(?, ?, ?, ?, ?, 1, ?, ?)",
				{ tAccount, tIdentifier, expires, reason, issuer, os.time(), json.encode(tokens) }
			)
		end

		if banId == nil then
			return COMPONENTS.Logger:Error(
				"Database",
				"[^8Error^7] Error in insertOne: " .. tostring(tIdentifier),
				{ console = true, file = true, database = true, discord = { embed = true, type = "error" } }
			)
		end

		local data = COMPONENTS.WebAPI:Request("POST", "admin/ban", {
			account = tAccount,
			identifier = tIdentifier,
			duration = expires,
			issuer = issuerId,
		}, {})
		if data.code ~= 200 then
			COMPONENTS.Logger:Info(
				"Punishment",
				("Failed To Ban Account %s On Website"):format(tAccount),
				{ console = true, discord = { embed = true, type = "error" } }
			)
		end

		if mask then
			reason = "💙 From Pwnzor 🙂"
		end

		if tSource ~= nil then
			if expires ~= -1 then
				DropPlayer(
					tSource,
					string.format(
						"You're Banned, Appeal At https://mythicrp.com/\n\nReason: %s\nExpires: %s\nID: %s",
						reason,
						expStr,
						banId
					)
				)
			else
				DropPlayer(
					tSource,
					string.format(
						"You're Permanently Banned, Appeal At https://mythicrp.com/\n\nReason: %s\nID: %s",
						reason,
						banId
					)
				)
			end
		end

		return true
	end,
	Unban = function(self, ids, issuer)
		local _ids = {}
		for k, v in ipairs(ids) do
			MySQL.query.await("UPDATE bans SET active = 0, unbanned = ? WHERE id = ? AND active = 1", {
				json.encode({ issuer = issuer:GetData("Name"), date = os.time() }),
				v._id,
			})

			local data = COMPONENTS.WebAPI:Request("DELETE", "admin/ban", {
				type = v.account ~= nil and "account" or "identifier",
				account = v.account,
				identifier = v.identifier,
				issuer = issuer:GetData("AccountID"),
			}, {})
			if data.code ~= 200 then
				success = false
				COMPONENTS.Logger:Info(
					"Punishment",
					("Failed To Revoke Site Ban For Account: %s & Identifier: %s"):format(v.account, v.identifier),
					{ console = true, discord = { embed = true, type = "error" } }
				)
			end

			table.insert(_ids, v._id)
		end

		COMPONENTS.Logger:Info(
			"Punishment",
			string.format("%s Bans Revoked By %s [%s]", #ids, issuer:GetData("Name"), issuer:GetData("AccountID")),
			{ console = true, file = true, database = true, discord = { embed = true, type = "info" } },
			{
				issuer = string.format("%s [%s]", issuer:GetData("Name"), issuer:GetData("AccountID")),
			},
			_ids
		)

		return #_ids > 0
	end,
}
