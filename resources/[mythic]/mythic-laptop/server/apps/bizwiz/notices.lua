AddEventHandler("Laptop:Server:RegisterCallbacks", function()
	local results = DecodeRows(MySQL.query.await("SELECT * FROM business_notices", {}), "notice")

	Logger:Trace("Laptop", "[BizWiz] Loaded ^2" .. #results .. "^7 Business Notices", { console = true })
	_businessNotices = results

	Callbacks:RegisterServerCallback("Laptop:BizWiz:Notice:Create", function(source, data, cb)
		local job = CheckBusinessPermissions(source, "LAPTOP_CREATE_NOTICE")
		if job then
			cb(Laptop.BizWiz.Notices:Create(source, job, data.doc))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("Laptop:BizWiz:Notice:Delete", function(source, data, cb)
		local job = CheckBusinessPermissions(source, "LAPTOP_DELETE_NOTICE")
		if job then
			cb(Laptop.BizWiz.Notices:Delete(job, data.id))
		else
			cb(false)
		end
	end)
end)

LAPTOP.BizWiz = LAPTOP.BizWiz or {}
LAPTOP.BizWiz.Notices = {
	Create = function(self, source, job, data)
		local char = Fetch:Source(source):GetData("Character")
		if char then
			local p = promise.new()

			data.job = job
			data.author = {
				SID = char:GetData("SID"),
				First = char:GetData("First"),
				Last = char:GetData("Last"),
			}

			local insertId = MySQL.insert.await("INSERT INTO business_notices (job, notice) VALUES(?, ?)", {
				data.job,
				json.encode(data),
			})

			do
				if insertId == nil then
					p:resolve(false)
					return
				end

				data._id = insertId
				table.insert(_businessNotices, data)

				local jobDutyData = Jobs.Duty:GetDutyData(job)
				if jobDutyData and jobDutyData.DutyPlayers then
					for k, v in ipairs(jobDutyData.DutyPlayers) do
						TriggerClientEvent("Laptop:Client:AddData", v, "businessNotices", data)
					end
				end

				p:resolve(insertId)
			end
			return Citizen.Await(p)
		end
		return false
	end,
	Delete = function(self, job, id)
		local p = promise.new()
		local deleted = MySQL.query.await("DELETE FROM business_notices WHERE id = ? AND job = ?", { id, job })

		do
			if deleted == nil then
				p:resolve(false)
				return
			end

			for k, v in ipairs(_businessNotices) do
				if v._id == id then
					table.remove(_businessNotices, k)
					break
				end
			end

			local jobDutyData = Jobs.Duty:GetDutyData(job)
			if jobDutyData and jobDutyData.DutyPlayers then
				for k, v in ipairs(jobDutyData.DutyPlayers) do
					TriggerClientEvent("Laptop:Client:RemoveData", v, "businessNotices", id)
				end
			end

			p:resolve(true)
		end
		return Citizen.Await(p)
	end,
}

function DecodeRows(rows, column)
	local decoded = {}

	for k, v in ipairs(rows) do
		local doc = json.decode(v[column])
		doc._id = v.id
		table.insert(decoded, doc)
	end

	return decoded
end
