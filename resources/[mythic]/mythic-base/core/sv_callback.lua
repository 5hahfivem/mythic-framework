local _sCallbacks = {}
local _cCallbacks = {}
local _callbackId = 0
local _callbackTimeout = GetConvarInt('callback_timeout', 300000)

local function stackTrace()
    return Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''
end

local function generateId(event, extraId)
    _callbackId += 1

    if extraId ~= nil then
        return string.format("%s-%s-%s", event, extraId, _callbackId)
    end

    return string.format("%s-%s", event, _callbackId)
end

COMPONENTS.Callbacks = {
    _required = { 'RegisterServerCallback', 'DoServerCallback', 'ClientCallback' },
    _name = 'base',
    RegisterServerCallback = function(self, event, cb)
        _sCallbacks[event] = cb
    end,
    DoServerCallback = function(self, source, event, data, id)
        local callback = _sCallbacks[event]
        if callback == nil then
            COMPONENTS.Logger:Warn('Callbacks', string.format("Attempt To Trigger Non-Existent Server Callback: ^2%s^7", event), { console = true })
            TriggerClientEvent('Callbacks:Client:ReceiveCallback', source, event, id)
            return
        end

        CreateThread(function()
            local success, err = pcall(callback, source, data, function(...)
                TriggerClientEvent('Callbacks:Client:ReceiveCallback', source, event, id, ...)
            end)

            if not success then
                COMPONENTS.Logger:Error('Callbacks', string.format("Server Callback ^2%s^7 Failed: %s\n%s", event, err, stackTrace()), { console = true })
                TriggerClientEvent('Callbacks:Client:ReceiveCallback', source, event, id)
            end
        end)
    end,
    ClientCallback = function(self, source, event, data, cb, extraId)
        if data == nil then data = {} end

        local id = generateId(event, extraId)

        _cCallbacks[source] = _cCallbacks[source] or {}
        _cCallbacks[source][id] = cb
        TriggerClientEvent('Callbacks:Client:TriggerEvent', source, event, data, id)

        if cb == nil then return end

        SetTimeout(_callbackTimeout, function()
            if _cCallbacks[source] ~= nil and _cCallbacks[source][id] ~= nil then
                _cCallbacks[source][id] = nil
                COMPONENTS.Logger:Warn('Callbacks', string.format("Client Callback Timed Out: ^2%s^7", event), { console = true })
            end
        end)
    end,
    ClientCallbackSync = function(self, source, event, data, extraId)
        local p = promise.new()

        self:ClientCallback(source, event, data, function(...)
            p:resolve({ ... })
        end, extraId)

        SetTimeout(_callbackTimeout, function()
            p:reject(string.format("Client Callback Timed Out: %s", event))
        end)

        return table.unpack(Citizen.Await(p))
    end
}

RegisterServerEvent('Callbacks:Server:TriggerEvent', function(event, data, id)
    data = data or {}
    COMPONENTS.Callbacks:DoServerCallback(source, event, data, id)
end)

RegisterServerEvent('Callbacks:Server:ReceiveCallback', function(event, id, ...)
    local src = source

    local pending = _cCallbacks[src]
    if pending == nil then return end

    local callback = pending[id]
    if callback == nil then return end

    pending[id] = nil
    callback(...)
end)

AddEventHandler('Proxy:Shared:RegisterReady', function()
    COMPONENTS.Middleware:Add('playerDropped', function(source)
        _cCallbacks[source] = nil
    end)
end)
