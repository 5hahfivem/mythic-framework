PHONE.Documents = {
	Create = function(self, source, doc)
		local char = Fetch:Source(source):GetData("Character")
		if char ~= nil and type(doc) == "table" then
            local p = promise.new()

            doc.owner = char:GetData("ID")
            doc.time = os.time()

			local insertedId = MySQL.insert.await(
				"INSERT INTO character_documents (owner, time, document) VALUES(?, ?, ?)",
				{ doc.owner, doc.time, json.encode(doc) }
			)

			if insertedId ~= nil then
				doc._id = insertedId
				p:resolve(doc)
			else
				p:resolve(false)
			end

            return Citizen.Await(p)
		end
        return false
	end,
    Edit = function(self, source, id, doc)
		local char = Fetch:Source(source):GetData("Character")
		if char ~= nil and type(doc) == "table" then
            local p = promise.new()

			local existing = FetchPhoneDocument(id)
			local success = false

			if existing and existing.owner == char:GetData("ID") then
				existing.title = doc.title
				existing.content = doc.content
				existing.time = os.time()
				success = StorePhoneDocument(id, existing)
			end

			local res = success and existing or nil

            p:resolve(success)

            if res and res.sharedWith then
                for k, v in ipairs(res.sharedWith) do
                    if v.ID then
                        local char = Fetch:ID(v.ID)
                        if char then
                            TriggerClientEvent("Phone:Client:UpdateData", char:GetData("Source"), "myDocuments", res._id, res)
                        end
                    end
                end
            end

            return Citizen.Await(p)
		end
        return false
	end,
	Delete = function(self, source, id)
        local char = Fetch:Source(source):GetData("Character")
        if char ~= nil then
            local p = promise.new()

            local doc = FetchPhoneDocument(id)

            if doc then
                if doc.owner == char:GetData("ID") then
                    local success = MySQL.query.await("DELETE FROM character_documents WHERE id = ?", { id }) ~= nil

                    p:resolve(success)

                    if success and doc.sharedWith then
                        for k, v in ipairs(doc.sharedWith) do
                            if v.ID then
                                local shared = Fetch:ID(v.ID)
                                if shared then
                                    TriggerClientEvent("Phone:Client:RemoveData", shared:GetData("Source"), "myDocuments", id)
                                end
                            end
                        end
                    end
                else
                    local sharedWith = {}
                    for k, v in ipairs(doc.sharedWith or {}) do
                        if v.ID ~= char:GetData("ID") then
                            table.insert(sharedWith, v)
                        end
                    end

                    doc.sharedWith = sharedWith
                    p:resolve(StorePhoneDocument(id, doc))
                end
            else
                p:resolve(false)
            end

            return Citizen.Await(p)
        end
        return false
	end,
}

AddEventHandler("Phone:Server:RegisterMiddleware", function()
	Middleware:Add("Characters:Spawning", function(source)
		local char = Fetch:Source(source):GetData("Character")
		local docs = FetchPhoneDocumentsFor(char:GetData("ID"))

		TriggerClientEvent("Phone:Client:SetData", source, "myDocuments", docs)
	end, 2)
	Middleware:Add("Phone:UIReset", function(source)
		local char = Fetch:Source(source):GetData("Character")
		local docs = FetchPhoneDocumentsFor(char:GetData("ID"))

		TriggerClientEvent("Phone:Client:SetData", source, "myDocuments", docs)
	end, 2)
end)

AddEventHandler("Phone:Server:RegisterCallbacks", function()
    Callbacks:RegisterServerCallback("Phone:Documents:Create", function(source, data, cb)
		cb(Phone.Documents:Create(source, data))
	end)

    Callbacks:RegisterServerCallback("Phone:Documents:Edit", function(source, data, cb)
		cb(Phone.Documents:Edit(source, data.id, data.data))
	end)

	Callbacks:RegisterServerCallback("Phone:Documents:Delete", function(source, data, cb)
		cb(Phone.Documents:Delete(source, data))
	end)

    Callbacks:RegisterServerCallback("Phone:Documents:Refresh", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
		cb("myDocuments", FetchPhoneDocumentsFor(char:GetData("ID")))
	end)

    Callbacks:RegisterServerCallback("Phone:Documents:Share", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
        if char and data and data.type and data.document then
            local target = nil
            if not data.nearby then
                if not data.target then
                    return cb(false)
                end

                target = Fetch:SID(data.target)
                if target then
                    target = target:GetData("Character")
                end

                if not target then
                    return cb(false)
                end

                if target:GetData("SID") == char:GetData("SID") then
                    return cb(false)
                end
            end

            local shareData = nil

            if data.type == 1 then
                data.document._id = nil
                data.document.sharedBy = {
                    ID = char:GetData("ID"),
                    First = char:GetData("First"),
                    Last = char:GetData("Last"),
                    SID = char:GetData("SID"),
                }
                data.document.shared = true
                data.document.sharedWith = {}

                sharedData = {
                    isCopy = true,
                    document = data.document,
                }
            elseif data.type == 2 or data.type == 3 then
                sharedData = {
                    isCopy = false,
                    document = {
                        _id = data.document._id,
                        title = data.document.title,
                        sharedBy = {
                            ID = char:GetData("ID"),
                            First = char:GetData("First"),
                            Last = char:GetData("Last"),
                            SID = char:GetData("SID"),
                        }
                    },
                    requireSignature = data.type == 3,
                }
            end

            if sharedData then
                if target then
                    TriggerClientEvent("Phone:Client:ReceiveShare", target:GetData("Source"), {
                        type = "documents",
                        data = sharedData,
                    }, os.time() * 1000)

                    return cb(true)
                else
                    local myPed = GetPlayerPed(source)
                    local myCoords = GetEntityCoords(myPed)
                    local myBucket = GetPlayerRoutingBucket(source)
                    for k, v in pairs(Fetch:All()) do
                        local tsrc = v:GetData("Source")
                        local tped = GetPlayerPed(tsrc)
                        local coords = GetEntityCoords(tped)
                        if tsrc ~= source and #(myCoords - coords) <= 5.0 and GetPlayerRoutingBucket(tsrc) == myBucket then
                            TriggerClientEvent("Phone:Client:ReceiveShare", tsrc, {
                                type = "documents",
                                data = sharedData,
                            }, os.time() * 1000)
                        end
                    end

                    return cb(true)
                end
            end
        end

        cb(false)
	end)

    Callbacks:RegisterServerCallback("Phone:Documents:RecieveShare", function(source, data, cb)
        if data then
            if data.isCopy then
                cb(Phone.Documents:Create(source, data.document))
            else
                local char = Fetch:Source(source):GetData("Character")
                if char then
                    local doc = FetchPhoneDocument(data.document._id)
                    local alreadyShared = false

                    for k, v in ipairs(doc and doc.sharedWith or {}) do
                        if v.ID == char:GetData("ID") then
                            alreadyShared = true
                        end
                    end

                    if doc and doc.owner ~= char:GetData("ID") and not alreadyShared then
                        doc.sharedWith = doc.sharedWith or {}
                        table.insert(doc.sharedWith, {
                            Time = os.time(),
                            ID = char:GetData("ID"),
                            First = char:GetData("First"),
                            Last = char:GetData("Last"),
                            SID = char:GetData("SID"),
                            RequireSignature = data.requireSignature,
                        })
                        doc.sharedBy = data.document.sharedBy

                        if StorePhoneDocument(data.document._id, doc) then
                            cb(doc)
                        else
                            cb(false)
                        end
                    else
                        cb(false)
                    end
                else
                    cb(false)
                end
            end
        else
            cb(false)
        end
	end)

    Callbacks:RegisterServerCallback("Phone:Documents:Sign", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char then
            local res = FetchPhoneDocument(data)
            local alreadySigned = false

            for k, v in ipairs(res and res.signed or {}) do
                if v.ID == char:GetData("ID") then
                    alreadySigned = true
                end
            end

            local success = false
            if res and res.owner ~= char:GetData("ID") and not alreadySigned then
                res.signed = res.signed or {}
                table.insert(res.signed, {
                    Time = os.time(),
                    ID = char:GetData("ID"),
                    First = char:GetData("First"),
                    Last = char:GetData("Last"),
                    SID = char:GetData("SID"),
                })

                success = StorePhoneDocument(data, res)
            end

            cb(success)

            if res and res.sharedWith then
                for k, v in ipairs(res.sharedWith) do
                    if v.ID then
                        local char = Fetch:ID(v.ID)
                        if char then
                            TriggerClientEvent("Phone:Client:UpdateData", char:GetData("Source"), "myDocuments", res._id, res)
                        end
                    end
                end

                local char = Fetch:ID(res.owner)
                if char then
                    TriggerClientEvent("Phone:Client:UpdateData", char:GetData("Source"), "myDocuments", res._id, res)
                end
            end
        else
            cb(false)
        end
	end)
end)

function FetchPhoneDocument(id)
	return DecodePhoneRow(MySQL.single.await("SELECT * FROM character_documents WHERE id = ?", { id }), "document")
end

function StorePhoneDocument(id, doc)
	return MySQL.query.await("UPDATE character_documents SET document = ? WHERE id = ?", {
		json.encode(doc),
		id,
	}) ~= nil
end

function FetchPhoneDocumentsFor(charId)
	return DecodePhoneRows(MySQL.query.await(
		[[SELECT * FROM character_documents
			WHERE owner = ?
				OR JSON_CONTAINS(JSON_EXTRACT(document, '$.sharedWith'), JSON_OBJECT('ID', ?))]],
		{ charId, charId }
	), "document")
end
