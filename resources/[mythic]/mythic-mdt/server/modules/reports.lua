_MDT.Reports = {
	Search = function(self, term, type, tagsFilter)
        if not term then term = '' end

        local query = 'SELECT * FROM mdt_reports'
        local clauses, params = {}, {}

        if tagsFilter and #tagsFilter > 0 then
            local tagClauses = {}
            for k, v in ipairs(tagsFilter) do
                table.insert(tagClauses, "JSON_CONTAINS(JSON_EXTRACT(report, '$.tags'), CAST(? AS JSON))")
                table.insert(params, json.encode(v))
            end
            table.insert(clauses, string.format('(%s)', table.concat(tagClauses, ' OR ')))
        end

        if type then
            table.insert(clauses, 'type = ?')
            table.insert(params, type)
        end

        local search = string.format('%%%s%%', term)
        table.insert(clauses, '(title LIKE ? OR suspectNames LIKE ? OR CAST(ID AS CHAR) LIKE ?)')
        table.insert(params, search)
        table.insert(params, search)
        table.insert(params, search)

        query = string.format('%s WHERE %s ORDER BY time DESC', query, table.concat(clauses, ' AND '))

        if #term <= 0 then
            query = query .. ' LIMIT 24'
        end

        GlobalState['MDT:Metric:Search'] = GlobalState['MDT:Metric:Search'] + 1

        return DecodeMdtRows(MySQL.query.await(query, params), 'report')
	end,
    SearchEvidence = function(self, term)
        if not term then term = '' end

        local query = [[SELECT * FROM mdt_reports
            WHERE JSON_SEARCH(JSON_EXTRACT(report, '$.evidence[*].value'), 'one', ?) IS NOT NULL
            ORDER BY time DESC]]

        if #term <= 0 then
            query = query .. ' LIMIT 24'
        end

        GlobalState['MDT:Metric:Search'] = GlobalState['MDT:Metric:Search'] + 1

        return DecodeMdtRows(MySQL.query.await(query, { string.format('%%%s%%', term) }), 'report')
	end,
	Mine = function(self, char)
		local results = MySQL.query.await(
            [[SELECT * FROM mdt_reports
                WHERE JSON_CONTAINS(JSON_EXTRACT(report, '$.primaries'), CAST(? AS JSON))
                    OR authorSID = ?]],
            { json.encode(char:GetData("Callsign")), char:GetData("SID") }
        )

		GlobalState['MDT:Metric:Search'] = GlobalState['MDT:Metric:Search'] + 1

		return DecodeMdtRows(results, 'report')
	end,
	View = function(self, id)
		return DecodeMdtRow(MySQL.single.await('SELECT * FROM mdt_reports WHERE id = ?', { id }), 'report')
	end,
	Create = function(self, data)
        data.ID = Sequence:Get('Report')

		local insertId = StoreMdtReport(nil, data)

		GlobalState['MDT:Metric:Reports'] = GlobalState['MDT:Metric:Reports'] + 1

		if insertId == nil then
			return false
		end

		return {
			_id = insertId,
			ID = data.ID,
		}
	end,
	Update = function(self, id, char, report)
		local existing = MDT.Reports:View(id)
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

		return StoreMdtReport(id, existing) ~= nil
	end,
    Delete = function(self, id)
        return MySQL.query.await('DELETE FROM mdt_reports WHERE id = ?', { id }) ~= nil
    end,
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
    Callbacks:RegisterServerCallback("MDT:Search:report", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
		if CheckMDTPermissions(source, false) or char:GetData("Attorney") then
			cb(MDT.Reports:Search(data.term, data.reportType, data.tags))
		else
			cb(false)
		end
    end)

    Callbacks:RegisterServerCallback("MDT:Search:report-evidence", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Reports:SearchEvidence(data.term))
		else
			cb(false)
		end
    end)

    Callbacks:RegisterServerCallback("MDT:Search:myReport", function(source, data, cb)
        -- local char = Fetch:Source(source):GetData("Character")
		-- if char:GetData('Job').Id == 'police' then
		-- 	cb(MDT.Reports:Mine(char))
		-- else
		-- 	cb(false)
		-- end
    end)

    Callbacks:RegisterServerCallback("MDT:Create:report", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
		if CheckMDTPermissions(source, false) then
			data.doc.author = {
				SID = char:GetData("SID"),
				First = char:GetData("First"),
				Last = char:GetData("Last"),
				Callsign = char:GetData("Callsign"),
			}
			cb(MDT.Reports:Create(data.doc))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("MDT:Update:report", function(source, data, cb)
        local char = Fetch:Source(source):GetData('Character')
		if char and CheckMDTPermissions(source, false) then
            data.Report.lastUpdated = {
                Time = (os.time() * 1000),
                SID = char:GetData("SID"),
                First = char:GetData("First"),
                Last = char:GetData("Last"),
                Callsign = char:GetData("Callsign"),
            }
			cb(MDT.Reports:Update(data.ID, char, data.Report))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("MDT:Delete:report", function(source, data, cb)
		if CheckMDTPermissions(source, true) then
			cb(MDT.Reports:Delete(data.id))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("MDT:View:report", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
		if CheckMDTPermissions(source, false) or char:GetData("Attorney") then
			cb(MDT.Reports:View(data))
        else
			cb(false)
		end
    end)
end)

function StoreMdtReport(id, report)
	local suspectNames = {}
	for k, v in ipairs(report.suspects?.suspect or {}) do
		table.insert(suspectNames, string.format('%s %s', v.First or '', v.Last or ''))
	end

	if id == nil then
		return MySQL.insert.await(
			'INSERT INTO mdt_reports (ID, type, title, time, authorSID, suspectNames, report) VALUES(?, ?, ?, ?, ?, ?, ?)',
			{
				report.ID,
				report.type,
				report.title,
				report.time or (os.time() * 1000),
				report.author?.SID,
				table.concat(suspectNames, ', '),
				json.encode(report),
			}
		)
	end

	return MySQL.query.await(
		'UPDATE mdt_reports SET type = ?, title = ?, suspectNames = ?, report = ? WHERE id = ?',
		{
			report.type,
			report.title,
			table.concat(suspectNames, ', '),
			json.encode(report),
			id,
		}
	)
end
