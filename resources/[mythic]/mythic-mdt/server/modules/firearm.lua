_MDT.Firearm = {
	Search = function(self, term)
		local search = string.format("%%%s%%", term)
		local rows = MySQL.query.await(
			[[SELECT * FROM firearms
				WHERE Scratched = 0 AND (ownerName LIKE ? OR CAST(ownerSID AS CHAR) LIKE ? OR Serial LIKE ?)]],
			{ search, search, search }
		)

		GlobalState["MDT:Metric:Search"] = GlobalState["MDT:Metric:Search"] + 1

		return DecodeMdtRows(rows, "firearm")
	end,
	View = function(self, id)
		return DecodeMdtRow(MySQL.single.await("SELECT * FROM firearms WHERE id = ?", { id }), "firearm")
	end,
	Flags = {
		Add = function(self, id, data)
			local firearm = MDT.Firearm:View(id)
			if not firearm then
				return false
			end

			firearm.Flags = firearm.Flags or {}
			table.insert(firearm.Flags, data)

			return StoreMdtFirearm(id, firearm)
		end,
		Remove = function(self, id, flag)
			local firearm = MDT.Firearm:View(id)
			if not firearm or not firearm.Flags then
				return false
			end

			for k = #firearm.Flags, 1, -1 do
				if firearm.Flags[k].Type == flag then
					table.remove(firearm.Flags, k)
				end
			end

			return StoreMdtFirearm(id, firearm)
		end,
	},
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:Search:firearm", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Firearm:Search(data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:View:firearm", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Firearm:View(data))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Create:firearm-flag", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Firearm.Flags:Add(data.parentId, data.doc))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Delete:firearm-flag", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Firearm.Flags:Remove(data.parentId, data.id))
		else
			cb(false)
		end
	end)
end)

function StoreMdtFirearm(id, firearm)
	return MySQL.query.await("UPDATE firearms SET firearm = ? WHERE id = ?", {
		json.encode(firearm),
		id,
	}) ~= nil
end
