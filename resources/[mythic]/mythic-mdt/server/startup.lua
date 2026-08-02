_warrants = {}
_charges = {}
_tags = {}
_notices = {}

local _ran = false

function Startup()
	if _ran then
		return
	end
	AddDefaultData()
	RegisterTasks()

	local expired = MySQL.query.await(
		[[UPDATE mdt_warrants SET state = 'expired',
			warrant = JSON_SET(warrant, '$.state', 'expired')
			WHERE JSON_EXTRACT(warrant, '$.expires') <= ?]],
		{ (os.time() * 1000) }
	)

	if expired ~= nil then
		Logger:Trace("MDT", "Expired ^2" .. expired.affectedRows .. "^7 Old Warrants", { console = true })
	end

	local warrants = DecodeMdtRows(MySQL.query.await("SELECT * FROM mdt_warrants WHERE state = 'active'", {}), "warrant")

	Logger:Trace("MDT", "Loaded ^2" .. #warrants .. "^7 Active Warrants", { console = true })
	_warrants = warrants

	local charges = DecodeMdtRows(MySQL.query.await("SELECT * FROM mdt_charges", {}), "charge")

	Logger:Trace("MDT", "Loaded ^2" .. #charges .. "^7 Charges", { console = true })
	_charges = charges

	local tags = DecodeMdtRows(MySQL.query.await("SELECT * FROM mdt_tags", {}), "tag")

	Logger:Trace("MDT", "Loaded ^2" .. #tags .. "^7 Tags", { console = true })
	_tags = tags

	local notices = DecodeMdtRows(MySQL.query.await("SELECT * FROM mdt_notices", {}), "notice")

	Logger:Trace("MDT", "Loaded ^2" .. #notices .. "^7 Notices", { console = true })
	_notices = notices

	local flagged = MySQL.query.await(
		[[SELECT vehicle FROM vehicles WHERE JSON_CONTAINS(JSON_EXTRACT(vehicle, '$.Flags'), '{"radarFlag": true}')]],
		{}
	)

	for k, r in ipairs(flagged) do
		local v = json.decode(r.vehicle)
		if v.RegisteredPlate and v.Type == 0 then
			Radar:AddFlaggedPlate(v.RegisteredPlate, 'Vehicle Flagged in MDT')
		end
	end

	_ran = true

	SetHttpHandler(function(req, res)
		if req.path == '/charges' then
			res.send(json.encode(_charges))
		end
	end)
end

function DecodeMdtRow(row, column)
	if row == nil then
		return false
	end

	local doc = json.decode(row[column])
	doc._id = row.id

	return doc
end

function DecodeMdtRows(rows, column)
	local decoded = {}

	for k, v in ipairs(rows) do
		table.insert(decoded, DecodeMdtRow(v, column))
	end

	return decoded
end

function FetchMdtCharacter(SID)
	local row = MySQL.single.await('SELECT * FROM characters WHERE SID = ?', { SID })

	if row == nil then
		return false
	end

	local character = json.decode(row.character)
	character._id = row.id

	return character
end

function StoreMdtCharacter(SID, character)
	return MySQL.query.await('UPDATE characters SET `character` = ? WHERE SID = ?', {
		json.encode(character),
		SID,
	}) ~= nil
end

function SetCharacterField(SID, key, value)
	local character = FetchMdtCharacter(SID)

	if not character then
		return false
	end

	character[key] = value

	return StoreMdtCharacter(SID, character)
end

function PushCharacterHistory(SID, entry)
	local character = FetchMdtCharacter(SID)

	if not character then
		return false
	end

	character.MDTHistory = character.MDTHistory or {}
	table.insert(character.MDTHistory, entry)

	return StoreMdtCharacter(SID, character)
end

function ApplyCharacterLicenseUpdate(SID, licenseUpdate)
	local character = FetchMdtCharacter(SID)

	if not character then
		return false
	end

	character.Licenses = character.Licenses or {}

	for path, value in pairs(licenseUpdate['$set'] or {}) do
		local license, field = path:match('^Licenses%.([^.]+)%.(.+)$')
		if license then
			character.Licenses[license] = character.Licenses[license] or {}
			character.Licenses[license][field] = value
		end
	end

	for path, value in pairs(licenseUpdate['$push'] or {}) do
		if path == 'MDTHistory' then
			character.MDTHistory = character.MDTHistory or {}
			table.insert(character.MDTHistory, value)
		end
	end

	if not StoreMdtCharacter(SID, character) then
		return false
	end

	return character
end

function SentenceReportSuspect(reportId, suspectSID, sentence)
	local row = MySQL.single.await('SELECT * FROM mdt_reports WHERE reportId = ?', { reportId })

	if row == nil then
		return false
	end

	local report = json.decode(row.report)
	local found = false

	for k, v in ipairs(report.suspects?.suspect or {}) do
		if v.SID == suspectSID then
			v.sentence = sentence
			found = true
		end
	end

	if not found then
		return false
	end

	return MySQL.query.await('UPDATE mdt_reports SET report = ? WHERE id = ?', {
		json.encode(report),
		row.id,
	}) ~= nil
end

function AddCharacterConvictions(SID, charges, conviction)
	local row = MySQL.single.await('SELECT * FROM character_convictions WHERE SID = ?', { SID })
	local record = row and json.decode(row.convictions) or { SID = SID, Charges = {}, Convictions = {} }

	record.Charges = record.Charges or {}
	record.Convictions = record.Convictions or {}

	for k, v in ipairs(charges or {}) do
		table.insert(record.Charges, v)
	end

	table.insert(record.Convictions, conviction)

	return MySQL.query.await(
		'INSERT INTO character_convictions (SID, convictions) VALUES(?, ?) ON DUPLICATE KEY UPDATE convictions = VALUES(convictions)',
		{ SID, json.encode(record) }
	) ~= nil
end
