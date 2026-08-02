_expirationThread = false

_loadedScenes = {}
_hasLoadedScenes = false

_spamCheck = {}

AddEventHandler('Scenes:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
	Fetch = exports['mythic-base']:FetchComponent('Fetch')
	Utils = exports['mythic-base']:FetchComponent('Utils')
    Execute = exports['mythic-base']:FetchComponent('Execute')
	Middleware = exports['mythic-base']:FetchComponent('Middleware')
	Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    Chat = exports['mythic-base']:FetchComponent('Chat')
	Logger = exports['mythic-base']:FetchComponent('Logger')
	Generator = exports['mythic-base']:FetchComponent('Generator')
	Phone = exports['mythic-base']:FetchComponent('Phone')
	Jobs = exports['mythic-base']:FetchComponent('Jobs')
	Vehicles = exports['mythic-base']:FetchComponent('Vehicles')
    Inventory = exports['mythic-base']:FetchComponent('Inventory')
    Scenes = exports['mythic-base']:FetchComponent('Scenes')
end

AddEventHandler('Core:Shared:Ready', function()
	exports['mythic-base']:RequestDependencies('Scenes', {
		'Fetch',
		'Utils',
        'Execute',
        'Chat',
		'Middleware',
		'Callbacks',
		'Logger',
		'Generator',
		'Phone',
		'Jobs',
		'Vehicles',
        'Inventory',
        'Scenes',
	}, function(error)
		if #error > 0 then 
            exports['mythic-base']:FetchComponent('Logger'):Critical('Scenes', 'Failed To Load All Dependencies')
			return
		end
		RetrieveComponents()

        LoadScenesFromDB()
        StartExpirationThread()

        Callbacks:RegisterServerCallback('Scenes:Create', function(source, data, cb)
            local player = Fetch:Source(source)
            local timeStamp = GetGameTimer()

            if _spamCheck[source] and (timeStamp < _spamCheck[source]) and not player.Permissions:IsStaff() then
                return cb(false)
            end

            if player and data.scene and data.data then
                local wasCreated = Scenes:Create(data.scene, data.data.staff and player.Permissions:IsStaff())
                if wasCreated then
                    _spamCheck[source] = timeStamp + 3500
                end
                cb(wasCreated)
            end
        end)

        Callbacks:RegisterServerCallback('Scenes:Delete', function(source, sceneId, cb)
            local player = Fetch:Source(source)
            local scene = _loadedScenes[sceneId]
            local timeStamp = GetGameTimer()

            if _spamCheck[source] and (timeStamp < _spamCheck[source]) and not player.Permissions:IsStaff() then
                return cb(false)
            end

            if scene and player then
                if scene.staff and not player.Permissions:IsStaff() then
                    return cb(false, true)
                end

                _spamCheck[source] = timeStamp + 5000

                cb(Scenes:Delete(sceneId))
            else
                cb(false)
            end
        end)

        Callbacks:RegisterServerCallback('Scenes:CanEdit', function(source, sceneId, cb)
            local player = Fetch:Source(source)
            local scene = _loadedScenes[sceneId]
            local timeStamp = GetGameTimer()

            if _spamCheck[source] and (timeStamp < _spamCheck[source]) and not player.Permissions:IsStaff() then
                return cb(false, false)
            end

            if scene and player then
                if scene.staff and not player.Permissions:IsStaff() then
                    return cb(false, player.Permissions:IsStaff())
                end

                _spamCheck[source] = timeStamp + 5000

                cb(true, player.Permissions:IsStaff())
            else
                cb(false, false)
            end
        end)

        Callbacks:RegisterServerCallback('Scenes:Edit', function(source, data, cb)
            local player = Fetch:Source(source)
            local scene = _loadedScenes[data.id]
            local timeStamp = GetGameTimer()

            if _spamCheck[source] and (timeStamp < _spamCheck[source]) and not player.Permissions:IsStaff() then
                return cb(false)
            end

            if scene and player then
                _spamCheck[source] = timeStamp + 5000

                cb(Scenes:Edit(data.id, data.scene, player.Permissions:IsStaff()))
            else
                cb(false)
            end
        end)

        Middleware:Add('Characters:Spawning', function(source)
            TriggerClientEvent('Scenes:Client:RecieveScenes', source, _loadedScenes)
        end, 5)

        Middleware:Add("playerDropped", function(source, message)
            _spamCheck[source] = nil
        end, 5)

        Chat:RegisterCommand('scene', function(source, args, rawCommand)
            TriggerClientEvent('Scenes:Client:Creation', source, args)
        end, {
            help = 'Create a Scene (Look Where You Want to Place)',
        })

        Chat:RegisterStaffCommand('scenestaff', function(source, args, rawCommand)
            TriggerClientEvent('Scenes:Client:Creation', source, args, true)
        end, {
            help = '[Staff] Create a Scene (Look Where You Want to Place)',
        })

        Chat:RegisterCommand('scenedelete', function(source, args, rawCommand)
            TriggerClientEvent('Scenes:Client:Deletion', source)
        end, {
            help = 'Delete a Scene (Look at Scene You Want to Delete)',
        })

        Chat:RegisterCommand('sceneedit', function(source, args, rawCommand)
            TriggerClientEvent('Scenes:Client:StartEdit', source)
        end, {
            help = 'Delete a Scene (Look at Scene You Want to Delete)',
        })
	end)
end)

_SCENES = {
    Create = function(self, scene, isStaff)
        if scene and scene.coords then
            scene.coords = {
                x = scene.coords.x,
                y = scene.coords.y,
                z = scene.coords.z
            }

            if not scene.length and not isStaff then
                return false
            end

            if scene.length then
                if scene.length > 24 then
                    scene.length = 24
                elseif scene.length < 1 then
                    scene.length = 1
                end

                scene.expires = os.time() + (3600 * scene.length)
                scene.staff = false
            else
                scene.expires = false
                scene.staff = true
            end

            if type(scene.distance) ~= 'number' or scene.distance > 10.0 or scene.distance < 1.0 then
                scene.distance = 7.5
            end

            local id = MySQL.insert.await('INSERT INTO scenes (staff, route, expires, scene) VALUES(?, ?, ?, ?)', {
                scene.staff,
                scene.route or 0,
                scene.expires or 0,
                json.encode(scene),
            })

            if not id then
                return false
            end

            scene._id = id
            _loadedScenes[scene._id] = scene
            TriggerClientEvent('Scenes:Client:AddScene', -1, scene._id, scene)

            return scene
        end
    end,
    Edit = function(self, id, newData, isStaff)
        if newData and newData.coords then
            newData.coords = {
                x = newData.coords.x,
                y = newData.coords.y,
                z = newData.coords.z
            }

            if not newData.length and not isStaff then
                return false
            end

            if newData.length then
                if newData.length > 24 then
                    newData.length = 24
                elseif newData.length < 1 then
                    newData.length = 1
                end

                newData.expires = os.time() + (3600 * newData.length)
                newData.staff = false
            else
                newData.expires = false
                newData.staff = true
            end

            if type(newData.distance) ~= 'number' or newData.distance > 10.0 or newData.distance < 1.0 then
                newData.distance = 7.5
            end

            newData._id = nil

            local result = MySQL.query.await('UPDATE scenes SET staff = ?, route = ?, expires = ?, scene = ? WHERE id = ?', {
                newData.staff,
                newData.route or 0,
                newData.expires or 0,
                json.encode(newData),
                id,
            })

            if not result then
                return false
            end

            newData._id = id
            _loadedScenes[id] = newData
            TriggerClientEvent('Scenes:Client:AddScene', -1, newData._id, newData)

            return newData
        end
    end,
    Delete = function(self, id)
        local result = MySQL.query.await('DELETE FROM scenes WHERE id = ?', { id })

        if result and _loadedScenes[id] then
            _loadedScenes[id] = nil
            TriggerClientEvent('Scenes:Client:RemoveScene', -1, id)
        end

        return result ~= nil
    end,
}

AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['mythic-base']:RegisterComponent('Scenes', _SCENES)
end)

function DeleteExpiredScenes(deleteRouted)
    local query = 'DELETE FROM scenes WHERE staff = 0 AND expires <= ?'

    if deleteRouted then -- Delete Routed
        query = 'DELETE FROM scenes WHERE (staff = 0 AND expires <= ?) OR route != 0'
    end

    local result = MySQL.query.await(query, { os.time() })

    if not result then
        return false
    end

    return result.affectedRows
end

function LoadScenesFromDB()
    if not _hasLoadedScenes then
        _hasLoadedScenes = true
        DeleteExpiredScenes(true)

        local results = MySQL.query.await('SELECT * FROM scenes', {})

        for k, v in ipairs(results) do
            local scene = json.decode(v.scene)
            scene._id = v.id
            _loadedScenes[v.id] = scene
        end
    end
end

function StartExpirationThread()
    if not _expirationThread then
        _expirationThread = true

        CreateThread(function()
            while true do
                Wait(60 * 1000 * 30)
                if _hasLoadedScenes then
                    local deleteScenes = {}
                    local timeStamp = os.time()

                    for k, v in pairs(_loadedScenes) do
                        if v.expires and timeStamp >= v.expires then
                            if Scenes:Delete(v._id) then
                                table.insert(deleteScenes, v._id)
                            end
                        end
                    end

                    TriggerClientEvent('Scenes:Client:RemoveScenes', -1, deleteScenes)
                end
            end
        end)
    end
end