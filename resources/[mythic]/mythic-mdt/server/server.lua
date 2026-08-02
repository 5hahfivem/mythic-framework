_MDT = _MDT or {}
_bolos = {}
_breakpoints = {
	reduction = 25,
	license = 12,
}

local governmentJobs = {
	police = true,
	government = true,
	ems = true,
	tow = true,
}

local _editingReports = {}

_onDutyUsers = {}
_onDutyLawyers = {}

_governmentJobData = {}

local sentencedSuspects = {}

AddEventHandler("MDT:Shared:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
	Fetch = exports["mythic-base"]:FetchComponent("Fetch")
	Callbacks = exports["mythic-base"]:FetchComponent("Callbacks")
	Logger = exports["mythic-base"]:FetchComponent("Logger")
	Utils = exports["mythic-base"]:FetchComponent("Utils")
	Chat = exports["mythic-base"]:FetchComponent("Chat")
	Middleware = exports["mythic-base"]:FetchComponent("Middleware")
	Execute = exports["mythic-base"]:FetchComponent("Execute")
	Tasks = exports["mythic-base"]:FetchComponent("Tasks")
	Sequence = exports["mythic-base"]:FetchComponent("Sequence")
	MDT = exports["mythic-base"]:FetchComponent("MDT")
	Jobs = exports["mythic-base"]:FetchComponent("Jobs")
	Inventory = exports["mythic-base"]:FetchComponent("Inventory")
	Default = exports["mythic-base"]:FetchComponent("Default")
	RegisterChatCommands()
end

AddEventHandler("Core:Shared:Ready", function()
	exports["mythic-base"]:RequestDependencies("MDT", {
		"Fetch",
		"Callbacks",
		"Logger",
		"Utils",
		"Chat",
		"Phone",
		"Middleware",
		"Execute",
		"Tasks",
		"Sequence",
		"MDT",
		"Jobs",
		"Inventory",
		"Default",
	}, function(error)
		if #error > 0 then
			return
		end
		RetrieveComponents()
		DefaultData()
		RegisterMiddleware()
		Startup()
		MetricsStartup()
		TriggerEvent("MDT:Server:RegisterCallbacks")

		Wait(2500)
		UpdateMDTJobsData()
	end)
end)

AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["mythic-base"]:RegisterComponent("MDT", _MDT)
end)

function RegisterMiddleware()
    Middleware:Add('Characters:Spawning', function(source)
		local char = Fetch:Source(source):GetData('Character')
		if char and char:GetData("Attorney") then
			SetTimeout(5000, function()
				TriggerClientEvent("MDT:Client:Login", source, nil, nil, nil, true)
				_onDutyLawyers[source] = char:GetData('SID')

				TriggerClientEvent("MDT:Client:SetData", source, "governmentJobs", _governmentJobs)
				TriggerClientEvent("MDT:Client:SetData", source, "charges", _charges)
				TriggerClientEvent("MDT:Client:SetData", source, "tags", _tags)
				TriggerClientEvent("MDT:Client:SetData", source, "notices", _notices)
				TriggerClientEvent("MDT:Client:SetData", source, "warrants", _warrants)
				TriggerClientEvent("MDT:Client:SetData", source, "governmentJobsData", _governmentJobData)
			end)
		end
    end, 50)

	Middleware:Add('Characters:Logout', function(source)
		local char = Fetch:Source(source):GetData('Character')
		if char then
			_onDutyLawyers[source] = nil
		end
	end)
end

function UpdateMDTJobsData()
	local newData = {}
	local allJobData = Jobs:GetAll()
	for k, v in ipairs(_governmentJobs) do
		newData[v] = allJobData[v]
	end

	_governmentJobData = newData
	TriggerClientEvent("MDT:Client:SetData", -1, "governmentJobsData", _governmentJobData)
end

AddEventHandler('Jobs:Server:UpdatedCache', function(job)
	if job == -1 or governmentJobs[job] then
		UpdateMDTJobsData()
	end
end)

AddEventHandler('Job:Server:DutyAdd', function(dutyData, source, SID)
	if governmentJobs[dutyData.Id] then
		local job = Jobs.Permissions:HasJob(source, dutyData.Id)
		if job then
			_onDutyUsers[source] = job.Id
			local permissions = Jobs.Permissions:GetPermissionsFromJob(source, job.Id)

			-- This is a yikes
			TriggerClientEvent("MDT:Client:SetData", source, "governmentJobs", _governmentJobs)
			TriggerClientEvent("MDT:Client:SetData", source, "charges", _charges)
			TriggerClientEvent("MDT:Client:SetData", source, "tags", _tags)
			TriggerClientEvent("MDT:Client:SetData", source, "notices", _notices)
			TriggerClientEvent("MDT:Client:SetData", source, "governmentJobsData", _governmentJobData)

			TriggerClientEvent("MDT:Client:SetData", source, "permissions", _permissions)
			TriggerClientEvent("MDT:Client:SetData", source, "qualifications", _qualifications)
			TriggerClientEvent("MDT:Client:SetData", source, "bolos", _bolos)
			TriggerClientEvent("MDT:Client:SetData", source, "warrants", _warrants)
	
			TriggerClientEvent("MDT:Client:Login", source, _breakpoints, job, permissions)
		end
	end
end)

AddEventHandler('Jobs:Server:JobUpdate', function(source)
	local dutyData = Jobs.Duty:Get(source)
	if dutyData and governmentJobs[dutyData.Id] then
		local job = Jobs.Permissions:HasJob(source, dutyData.Id)
		if job then
			local permissions = Jobs.Permissions:GetPermissionsFromJob(source, job.Id)
			TriggerClientEvent('MDT:Client:UpdateJobData', source, job, permissions)
		end
	end
end)

AddEventHandler('Job:Server:DutyRemove', function(dutyData, source, SID)
	if governmentJobs[dutyData.Id] then
		_onDutyUsers[source] = nil
		TriggerClientEvent("MDT:Client:Logout", source)
	end
end)

function CheckMDTPermissions(source, permission, jobId)
	local mdtUser = _onDutyUsers[source]
	if mdtUser and (not jobId or jobId == mdtUser or (type(jobId) == 'table' and jobId[mdtUser])) then
		if not permission then
			return true
		end

		if type(permission) == 'string' then
			local hasPerm = Jobs.Permissions:HasPermissionInJob(source, mdtUser, permission)
			if hasPerm then
				return true, mdtUser
			end
		elseif type(permission) == 'table' then
			local jobPermissions = Jobs.Permissions:GetPermissionsFromJob(source, mdtUser)
			for k, v in ipairs(permission) do
				if jobPermissions[v] then
					return true, mdtUser
				end
			end
		end
		
		local char = Fetch:Source(source):GetData('Character')
		if char:GetData('MDTSystemAdmin') then -- They have all permissions
			return true, mdtUser
		end
	end
	return false
end

RegisterNetEvent('MDT:Server:OpenPublicRecords', function()
	local src = source
	local dutyData = Jobs.Duty:Get(src)
	local dumbStuff = false

	if dutyData?.Id then
		TriggerClientEvent("MDT:Client:Logout", source)
		dumbStuff = true

		Wait(1500)
	end

	if not _onDutyUsers[src] then
		TriggerClientEvent("MDT:Client:SetData", src, "governmentJobs", _governmentJobs)
		TriggerClientEvent("MDT:Client:SetData", src, "charges", _charges)
		TriggerClientEvent("MDT:Client:SetData", src, "tags", _tags)
		TriggerClientEvent("MDT:Client:SetData", src, "notices", _notices)
		TriggerClientEvent("MDT:Client:SetData", src, "warrants", _warrants)
		TriggerClientEvent("MDT:Client:SetData", src, "governmentJobsData", _governmentJobData)
	end

	TriggerClientEvent('MDT:Client:Toggle', src, dumbStuff)
end)

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:Admin:SetMaxReduction", function(source, data, cb)
		--TODO: Set max reduction and dispatch to all clients
	end)

	Callbacks:RegisterServerCallback("MDT:SentencePlayer", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")

		if CheckMDTPermissions(source, false) and data.report and not _editingReports[data.report] then
			_editingReports[data.report] = true

			if not sentencedSuspects[data.report] then
				sentencedSuspects[data.report] = {}
			end

			if data.data.suspect.SID and not sentencedSuspects[data.report][data.data.suspect.SID] then
				local sentence = {
					time = os.time() * 1000,
					fine = data.fine,
					jail = data.jail,
					months = data.jail,
					revoked = data.sentence.revoke,
					doc = data.sentence.doc,
					reduction = {
						type = data.sentence.type,
						value = data.sentence.value,
					},
					parole = data.parole,
					sentencedBy = {
						SID = char:GetData('SID'),
						First = char:GetData('First'),
						Last = char:GetData('Last'),
						Callsign = char:GetData('Callsign'),
					}
				}

				local success = SentenceReportSuspect(data.report, data.data.suspect.SID, sentence)

				if success then
					sentencedSuspects[data.report][data.data.suspect.SID] = true

					AddCharacterConvictions(data.data.suspect.SID, data.data.charges, {
						time = os.time() * 1000,
						report = data.report,
						fine = data.fine,
						jail = data.jail,
						parole = data.parole,
					})

					local p = promise.new()

					if data.parole ~= nil then
						p:resolve(SetCharacterField(data.data.suspect.SID, 'Parole', data.parole))
					end

					Citizen.Await(p)

					if data.sentence.revoke then
						local needsUpdate = false
						local licenseUpdate = {
							['$set'] = {}
						}
						for k, v in pairs(data.sentence.revoke) do
							if v then
								needsUpdate = true
								if k == 'drivers' then
									licenseUpdate['$set']['Licenses.Drivers.Active'] = false
									licenseUpdate['$set']['Licenses.Drivers.Suspended'] = true
								elseif k == 'weapons' then
									licenseUpdate['$set']['Licenses.Weapons.Active'] = false
									licenseUpdate['$set']['Licenses.Weapons.Suspended'] = true
								elseif k == 'hunting' then
									licenseUpdate['$set']['Licenses.Hunting.Active'] = false
									licenseUpdate['$set']['Licenses.Hunting.Suspended'] = true
								elseif k == 'fishing' then
									licenseUpdate['$set']['Licenses.Fishing.Active'] = false
									licenseUpdate['$set']['Licenses.Fishing.Suspended'] = true
								end
							end
						end

						if needsUpdate then
							local p2 = promise.new()
							local results = ApplyCharacterLicenseUpdate(data.data.suspect.SID, licenseUpdate)

							if results and results.SID then
								if results and results.Licenses then
									local plyr = Fetch:SID(results.SID)
									if plyr then
										local char = plyr:GetData('Character')
										if char then
											char:SetData('Licenses', results.Licenses)
										end
									end
								end
							end

							p:resolve(success)

							Citizen.Await(p2)
						end
					end

					GlobalState["MDT:Metric:Arrests"] = GlobalState["MDT:Metric:Arrests"] + 1

					cb(true)
					_editingReports[data.report] = nil
				else
					_editingReports[data.report] = nil
					cb(false)
				end
			else
				cb(false)
			end

		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:RevokeLicenseSuspension", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")

		if CheckMDTPermissions(source, true) then
			local canUpdate = false
			local licenseUpdate = {
				['$set'] = {}
			}

			for k, v in pairs(data.unsuspend) do
				if v then
					canUpdate = true

					licenseUpdate['$set'][string.format('Licenses.%s.Active', k)] = false
					licenseUpdate['$set'][string.format('Licenses.%s.Suspended', k)] = false

					if k == 'Drivers' then
						licenseUpdate['$set']['Licenses.Drivers.Active'] = true
						licenseUpdate['$set']['Licenses.Drivers.Points'] = 0
					end
				end
			end

			if canUpdate then
				licenseUpdate["$push"] = {
					MDTHistory = {
						Time = (os.time() * 1000),
						Char = char:GetData("SID"),
						Log = string.format(
							"%s Updated Profile, Revoked License Suspensions %s",
							char:GetData("First") .. " " .. char:GetData("Last"),
							json.encode(data.unsuspend)
						),
					},
				}

				local results = ApplyCharacterLicenseUpdate(data.SID, licenseUpdate)

				if results and results.SID and results.Licenses then
					local plyr = Fetch:SID(results.SID)
					if plyr then
						local char = plyr:GetData('Character')
						if char then
							char:SetData('Licenses', results.Licenses)
						end
					end
					cb(results.Licenses)
				else
					cb(false)
				end
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:ClearCriminalRecord", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")

		if char and CheckMDTPermissions(source, true) then
			local old = DecodeMdtRow(
				MySQL.single.await('SELECT * FROM character_convictions WHERE SID = ?', { data.SID }),
				'convictions'
			)

			if old and old.SID then
				old._id = nil
				old.Time = os.time()
				old.ClearedBy = char:GetData("SID")

				local expunged = MySQL.insert.await(
					'INSERT INTO character_convictions_expunged (SID, convictions) VALUES(?, ?)',
					{ data.SID, json.encode(old) }
				)

				do
					if expunged ~= nil then
						cb(MySQL.query.await('DELETE FROM character_convictions WHERE SID = ?', { data.SID }) ~= nil)
					else
						cb(false)
					end
				end
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:OpenEvidenceLocker", function(source, caseNum, cb)
		local myDuty = Player(source).state.onDuty
		if myDuty and (myDuty == "police" or myDuty == "government") then
			Callbacks:ClientCallback(source, "Inventory:Compartment:Open", {
				invType = 44,
				owner = ("evidencelocker:%s"):format(caseNum),
			}, function()
				Inventory:OpenSecondary(source, 44, ("evidencelocker:%s"):format(caseNum))
			end)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:OpenPersonalLocker", function(source, data, cb)
		local char = Fetch:Source(source):GetData('Character')
		if char and (Jobs.Permissions:HasJob(source, 'police') or Jobs.Permissions:HasJob(source, 'ems')) and char:GetData('Callsign') then
			cb(true)

			Callbacks:ClientCallback(source, "Inventory:Compartment:Open", {
				invType = 45,
				owner = ("pdlocker:%s"):format(char:GetData('SID')),
			}, function()
				Inventory:OpenSecondary(source, 45, ("pdlocker:%s"):format(char:GetData('SID')))
			end)
		else
			cb(false)
		end
	end)
end)
