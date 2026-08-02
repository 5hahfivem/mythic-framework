function RegisterTasks()
    Tasks:Register('mdt_warrants', 30, function()
		Logger:Trace('MDT', 'Expiring Warrants')
		local filteredWarrants = {}
        for k, v in ipairs(_warrants) do
            if v.expires < (os.time() * 1000) then
				for user, _ in pairs(_onDutyUsers) do
					TriggerClientEvent("MDT:Client:RemoveData", user, "warrants", v._id)
				end
			else
				table.insert(filteredWarrants, v)
			end
        end

		_warrants = filteredWarrants
    end)
	
    Tasks:Register('mdt_metrics', 5, function()
		Logger:Trace('MDT', 'Metrics Stored')
		StoreMdtMetrics(GlobalState['MDT:Metric:CurrentDay'])
    end)
	
    Tasks:Register('mdt_metrics_time', 30, function()
		Logger:Trace('MDT', 'Validating Metric Key')
		local date = os.date("*t")
		local t = string.format('%s/%s/%s', date.month, date.day, date.year)
		if t ~= GlobalState['MDT:Metric:CurrentDay'] then
			Logger:Trace('MDT', 'New Day, Resetting Metrics')
			StoreMdtMetrics(GlobalState['MDT:Metric:CurrentDay'])

			GlobalState['MDT:Metric:CurrentDay'] = t
			GlobalState["MDT:Metric:Arrests"] = 0
			GlobalState["MDT:Metric:Reports"] = 0
			GlobalState["MDT:Metric:Warrants"] = 0
			GlobalState["MDT:Metric:BOLOs"] = 0
			GlobalState["MDT:Metric:Search"] = 0
		end
    end)
end

function StoreMdtMetrics(date)
	local metrics = {
		date = date,
		Arrests = GlobalState["MDT:Metric:Arrests"],
		Reports = GlobalState["MDT:Metric:Reports"],
		Warrants = GlobalState["MDT:Metric:Warrants"],
		BOLOs = GlobalState["MDT:Metric:BOLOs"],
		Searches = GlobalState["MDT:Metric:Search"],
	}

	return MySQL.query.await(
		'INSERT INTO mdt_metrics (date, metrics) VALUES(?, ?) ON DUPLICATE KEY UPDATE metrics = VALUES(metrics)',
		{ date, json.encode(metrics) }
	) ~= nil
end
