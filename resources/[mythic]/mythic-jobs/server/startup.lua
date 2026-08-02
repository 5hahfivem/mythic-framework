local _ranStartup = false
JOB_CACHE = {}
JOB_COUNT = 0

_loaded = false

AddEventHandler('Jobs:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
	Middleware = exports['mythic-base']:FetchComponent('Middleware')
	Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
	Logger = exports['mythic-base']:FetchComponent('Logger')
	Utils = exports['mythic-base']:FetchComponent('Utils')
	Fetch = exports['mythic-base']:FetchComponent('Fetch')
	Chat = exports['mythic-base']:FetchComponent('Chat')
	Execute = exports['mythic-base']:FetchComponent('Execute')
	Sequence = exports['mythic-base']:FetchComponent('Sequence')
	Generator = exports['mythic-base']:FetchComponent('Generator')
	Phone = exports['mythic-base']:FetchComponent('Phone')
	Jobs = exports['mythic-base']:FetchComponent('Jobs')
end

AddEventHandler('Core:Shared:Ready', function()
	exports['mythic-base']:RequestDependencies('Jobs', {
		'Middleware',
		'Callbacks',
		'Logger',
		'Utils',
		'Fetch',
		'Execute',
		'Sequence',
		'Generator',
		'Chat',
		'Jobs',
		'Phone'
	}, function(error)
		if #error > 0 then return; end
		RetrieveComponents()
		RegisterJobMiddleware()
		RegisterJobCallbacks()
		RegisterJobChatCommands()

		_loaded = true

		RunStartup()

		TriggerEvent('Jobs:Server:Startup')
	end)
end)

function FindAllJobs()
	local rows = MySQL.query.await('SELECT * FROM jobs', {})

	local res = {}
	for k, v in ipairs(rows) do
		local job = json.decode(v.job)
		job._id = v.id
		table.insert(res, job)
	end

	return res
end

function RefreshAllJobData(job)
	local jobsFetch = FindAllJobs()
	JOB_COUNT = #jobsFetch
	for k, v in ipairs(jobsFetch) do
		JOB_CACHE[v.Id] = v
	end

	TriggerEvent('Jobs:Server:UpdatedCache', job or -1)

	for k, v in ipairs(jobsFetch) do
		if v.Type == 'Government' and v.Workplaces then
			for k2, workplace in ipairs(v.Workplaces) do
				for k3, grade in ipairs(workplace.Grades or {}) do
					local key = string.format('JobPerms:%s:%s:%s', v.Id, workplace.Id, grade.Id)
					GlobalState[key] = grade.Permissions
				end
			end
		elseif v.Type == 'Company' and v.Grades then
			for k2, grade in ipairs(v.Grades) do
				local key = string.format('JobPerms:%s:false:%s', v.Id, grade.Id)
				GlobalState[key] = grade.Permissions
			end
		end
	end

	return true
end

function RunStartup()
    if _ranStartup then return; end
    _ranStartup = true

	local function replaceExistingDefaultJob(_id, document)
		local p = promise.new()

		if MySQL.query.await('DELETE FROM jobs WHERE id = ?', { _id }) == nil then
			Logger:Error('Jobs', 'Error Deleting Job on Default Job Update')
			p:resolve(false)
			return p
		end

		if InsertJob(document) == nil then
			Logger:Error('Jobs', 'Error Inserting Job on Default Job Update')
			p:resolve(false)
		else
			Wait(10000)
			p:resolve(true)
		end

		return p
	end

	local function insertDefaultJob(document)
		local p = promise.new()

		if InsertJob(document) == nil then
			Logger:Error('Jobs', 'Error Inserting Job on Default Job Update')
			p:resolve(false)
		else
			p:resolve(true)
		end

		return p
	end

	local jobsFetch = FindAllJobs()
	local currentData = {}
	for k, v in ipairs(jobsFetch) do
		currentData[v.Id] = v
	end

	local awaitingPromises = {}
	for k, v in ipairs(_defaultJobData) do
		local currentDataForJob = currentData[v.Id]
		if currentDataForJob and currentDataForJob.LastUpdated < v.LastUpdated then
			table.insert(awaitingPromises, replaceExistingDefaultJob(currentDataForJob._id, v))
		elseif not currentDataForJob then
			table.insert(awaitingPromises, insertDefaultJob(v))
		end
	end

	if #awaitingPromises > 0 then
		Citizen.Await(promise.all(awaitingPromises))
		Logger:Info('Jobs', 'Inserted/Replaced ^2' .. #awaitingPromises .. '^7 Default Jobs')
		jobsFetch = FindAllJobs()
	end

	RefreshAllJobData()
	Logger:Trace('Jobs', string.format('Loaded ^2%s^7 Jobs', JOB_COUNT))
	TriggerEvent('Jobs:Server:CompleteStartup')
end

function InsertJob(document)
	return MySQL.insert.await('INSERT INTO jobs (jobId, Type, Name, job) VALUES(?, ?, ?, ?)', {
		document.Id,
		document.Type,
		document.Name,
		json.encode(document),
	})
end

function StoreJob(job)
	return MySQL.query.await('UPDATE jobs SET Type = ?, Name = ?, job = ? WHERE jobId = ?', {
		job.Type,
		job.Name,
		json.encode(job),
		job.Id,
	}) ~= nil
end

function FetchJob(jobId)
	local row = MySQL.single.await('SELECT * FROM jobs WHERE jobId = ?', { jobId })

	if row == nil then
		return false
	end

	local job = json.decode(row.job)
	job._id = row.id

	return job
end

function GetJobGrades(job, workplaceId)
	if workplaceId then
		local workplace = job.Workplaces and FindById(job.Workplaces, workplaceId)
		if not workplace then
			return false
		end

		workplace.Grades = workplace.Grades or {}
		return workplace.Grades
	end

	job.Grades = job.Grades or {}
	return job.Grades
end

function FindById(list, id)
	for k, v in ipairs(list or {}) do
		if v.Id == id then
			return v
		end
	end

	return false
end

function FetchCharacterBySID(stateId)
	local row = MySQL.single.await('SELECT `character` FROM characters WHERE SID = ?', { stateId })

	if row == nil then
		return false
	end

	return json.decode(row.character)
end

function StoreCharacterJobs(stateId, jobs)
	return MySQL.query.await(
		[[UPDATE characters SET `character` = JSON_SET(`character`, '$.Jobs', CAST(? AS JSON)) WHERE SID = ?]],
		{ json.encode(jobs), stateId }
	) ~= nil
end

function FetchCharactersWithJob(jobId)
	local rows = MySQL.query.await(
		[[SELECT `character` FROM characters WHERE JSON_CONTAINS(JSON_EXTRACT(`character`, '$.Jobs'), JSON_OBJECT('Id', ?))]],
		{ jobId }
	)

	local characters = {}
	for k, v in ipairs(rows) do
		table.insert(characters, json.decode(v.character))
	end

	return characters
end

function UpdateOfflineCharacterJobs(jobId, onlineCharacters, mutate)
	local online = {}
	for k, v in ipairs(onlineCharacters or {}) do
		online[v] = true
	end

	local rows = MySQL.query.await(
		[[SELECT SID, `character` FROM characters WHERE JSON_CONTAINS(JSON_EXTRACT(`character`, '$.Jobs'), JSON_OBJECT('Id', ?))]],
		{ jobId }
	)

	local updated = 0
	for k, v in ipairs(rows) do
		if not online[v.SID] then
			local character = json.decode(v.character)

			for k2, job in ipairs(character.Jobs or {}) do
				if job.Id == jobId then
					mutate(job)
				end
			end

			if StoreCharacterJobs(v.SID, character.Jobs) then
				updated = updated + 1
			end
		end
	end

	return updated
end
