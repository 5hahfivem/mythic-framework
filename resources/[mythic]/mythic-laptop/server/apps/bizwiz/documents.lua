LAPTOP.BizWiz = LAPTOP.BizWiz or {}

LAPTOP.BizWiz.Documents = {
	Search = function(self, jobId, term)
        if not term then term = '' end

		local search = string.format('%%%%%%s%%%%', term)

		return DecodeBizWizRows(MySQL.query.await(
			[[SELECT * FROM business_documents WHERE job = ? AND (title LIKE ? OR authorName LIKE ?)]],
			{ jobId, search, search }
		), 'document')
	end,
	View = function(self, jobId, id)
		local p = promise.new()
        local row = MySQL.single.await("SELECT * FROM business_documents WHERE id = ? AND job = ?", { id, jobId })

		if row == nil then
			return false
		end

		local report = json.decode(row.document)
		report._id = row.id

		return report
	end,
	Create = function(self, jobId, data)
        data.job = jobId

		local insertId = MySQL.insert.await(
			"INSERT INTO business_documents (job, title, authorName, document) VALUES(?, ?, ?, ?)",
			{
				jobId,
				data.title,
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
		local existing = Laptop.BizWiz.Documents:View(jobId, id)
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
			"UPDATE business_documents SET title = ?, document = ? WHERE id = ? AND job = ?",
			{ existing.title, json.encode(existing), id, jobId }
		) ~= nil
	end,
    Delete = function(self, jobId, id)
        return MySQL.query.await("DELETE FROM business_documents WHERE id = ? AND job = ?", { id, jobId }) ~= nil
    end,
}

AddEventHandler("Laptop:Server:RegisterCallbacks", function()
    Callbacks:RegisterServerCallback("Laptop:BizWiz:Document:Search", function(source, data, cb)
        local job = CheckBusinessPermissions(source, 'LAPTOP_VIEW_DOCUMENT')
		if job then
			cb(Laptop.BizWiz.Documents:Search(job, data.term))
		else
			cb(false)
		end
    end)

    Callbacks:RegisterServerCallback("Laptop:BizWiz:Document:Create", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        local job = CheckBusinessPermissions(source, 'LAPTOP_CREATE_DOCUMENT')
		if job then
			data.doc.author = {
				SID = char:GetData("SID"),
				First = char:GetData("First"),
				Last = char:GetData("Last"),
			}
			cb(Laptop.BizWiz.Documents:Create(job, data.doc))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:BizWiz:Document:Update", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        local job = CheckBusinessPermissions(source, 'LAPTOP_CREATE_DOCUMENT')
		if char and job then
            data.Report.lastUpdated = {
                Time = (os.time() * 1000),
                SID = char:GetData("SID"),
                First = char:GetData("First"),
                Last = char:GetData("Last"),
            }
			cb(Laptop.BizWiz.Documents:Update(job, data.id, char, data.Report))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:BizWiz:Document:Delete", function(source, data, cb)
        local job = CheckBusinessPermissions(source, 'LAPTOP_DELETE_DOCUMENT')
		if job then
			cb(Laptop.BizWiz.Documents:Delete(job, data.id))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:BizWiz:Document:View", function(source, data, cb)
        local job = CheckBusinessPermissions(source, 'LAPTOP_VIEW_DOCUMENT')
		if job then
			cb(Laptop.BizWiz.Documents:View(job, data))
        else
			cb(false)
		end
    end)
end)
