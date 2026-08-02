LAPTOP.BizWiz = LAPTOP.BizWiz or {}
LAPTOP.BizWiz.Receipts = {
	Search = function(self, jobId, term)
        if not term then term = '' end

		local search = string.format('%%%%%%s%%%%', term)

		return DecodeBizWizRows(MySQL.query.await(
			[[SELECT * FROM business_receipts WHERE job = ? AND (customerName LIKE ? OR authorName LIKE ?)]],
			{ jobId, search, search }
		), 'receipt')
	end,
	View = function(self, jobId, id)
		local p = promise.new()
        local row = MySQL.single.await("SELECT * FROM business_receipts WHERE id = ? AND job = ?", { id, jobId })

		if row == nil then
			return false
		end

		local report = json.decode(row.receipt)
		report._id = row.id

		return report
	end,
	Create = function(self, jobId, data)
		if not _bizWizConfig[jobId] then
			return false
		end

        data.job = jobId

		local insertId = MySQL.insert.await(
			"INSERT INTO business_receipts (job, customerName, authorName, receipt) VALUES(?, ?, ?, ?)",
			{
				jobId,
				data.customerName,
				BizWizAuthorName(data.author),
				json.encode(data),
			}
		)

		if insertId == nil then
			return false
		end

		return {
			_id = insertId,
		}
	end,
	Update = function(self, jobId, id, char, report)
		local existing = Laptop.BizWiz.Receipts:View(jobId, id)
		if not existing then
			return false
		end

		for k, v in pairs(report) do
			existing[k] = v
		end

		existing.history = existing.history or {}
		table.insert(existing.history, {
			Time = (os.time() * 1000),
			Char = char:GetData("SID"),
			Log = string.format(
					"%s Updated Report",
					char:GetData("First") .. " " .. char:GetData("Last")
			),
		})

		return MySQL.query.await(
			"UPDATE business_receipts SET customerName = ?, receipt = ? WHERE id = ? AND job = ?",
			{ existing.customerName, json.encode(existing), id, jobId }
		) ~= nil
	end,
    Delete = function(self, jobId, id)
        return MySQL.query.await("DELETE FROM business_receipts WHERE id = ? AND job = ?", { id, jobId }) ~= nil
    end,
	DeleteAll = function(self, jobId)
		if not jobId then return false; end

		return MySQL.query.await("DELETE FROM business_receipts WHERE job = ?", { jobId }) ~= nil
	end,
}

AddEventHandler("Laptop:Server:RegisterCallbacks", function()
    Callbacks:RegisterServerCallback("Laptop:BizWiz:Receipt:Search", function(source, data, cb)
        local job = CheckBusinessPermissions(source)
		if job then
			cb(Laptop.BizWiz.Receipts:Search(job, data.term))
		else
			cb(false)
		end
    end)

    Callbacks:RegisterServerCallback("Laptop:BizWiz:Receipt:Create", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        local job = CheckBusinessPermissions(source, 'LAPTOP_CREATE_RECEIPT')
		if job then
			data.doc.author = {
				SID = char:GetData("SID"),
				First = char:GetData("First"),
				Last = char:GetData("Last"),
			}
			cb(Laptop.BizWiz.Receipts:Create(job, data.doc))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:BizWiz:Receipt:Update", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        local job = CheckBusinessPermissions(source, 'LAPTOP_MANAGE_RECEIPT')
		if char and job then
            data.Report.lastUpdated = {
                Time = (os.time() * 1000),
                SID = char:GetData("SID"),
                First = char:GetData("First"),
                Last = char:GetData("Last"),
            }
			cb(Laptop.BizWiz.Receipts:Update(job, data.id, char, data.Report))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:BizWiz:Receipt:Delete", function(source, data, cb)
        local job = CheckBusinessPermissions(source, 'LAPTOP_MANAGE_RECEIPT')
		if job then
			cb(Laptop.BizWiz.Receipts:Delete(job, data.id))
        else
            cb(false)
        end
    end)

	Callbacks:RegisterServerCallback("Laptop:BizWiz:Receipt:DeleteAll", function(source, data, cb)
        local job = CheckBusinessPermissions(source, 'LAPTOP_CLEAR_RECEIPT')
		if job then
			cb(Laptop.BizWiz.Receipts:DeleteAll(job))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:BizWiz:Receipt:View", function(source, data, cb)
        local job = CheckBusinessPermissions(source)
		if job then
			cb(Laptop.BizWiz.Receipts:View(job, data))
        else
			cb(false)
		end
    end)
end)
