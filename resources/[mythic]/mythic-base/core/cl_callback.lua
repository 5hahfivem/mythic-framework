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
    _required = { 'ServerCallback', 'RegisterClientCallback', 'DoClientCallback' },
    _name = 'base',
    ServerCallback = function(self, event, data, cb, extraId)
        local id = generateId(event, extraId)

        data = data or {}
        _sCallbacks[id] = cb
        TriggerServerEvent('Callbacks:Server:TriggerEvent', event, data, id)

        if cb == nil then return end

        SetTimeout(_callbackTimeout, function()
            if _sCallbacks[id] ~= nil then
                _sCallbacks[id] = nil
                COMPONENTS.Logger:Warn('Callbacks', string.format("Server Callback Timed Out: ^2%s^7", event), { console = true })
            end
        end)
    end,
    ServerCallbackSync = function(self, event, data, extraId)
        local p = promise.new()

        self:ServerCallback(event, data, function(...)
            p:resolve({ ... })
        end, extraId)

        SetTimeout(_callbackTimeout, function()
            p:reject(string.format("Server Callback Timed Out: %s", event))
        end)

        return table.unpack(Citizen.Await(p))
    end,
    RegisterClientCallback = function(self, event, cb)
        _cCallbacks[event] = cb
    end,
    DoClientCallback = function(self, event, id, data)
        local callback = _cCallbacks[event]
        if callback == nil then
            COMPONENTS.Logger:Warn('Callbacks', string.format("Attempt To Trigger Non-Existent Client Callback: ^2%s^7", event), { console = true })
            TriggerServerEvent('Callbacks:Server:ReceiveCallback', event, id)
            return
        end

        CreateThread(function()
            local success, err = pcall(callback, data, function(...)
                TriggerServerEvent('Callbacks:Server:ReceiveCallback', event, id, ...)
            end)

            if not success then
                COMPONENTS.Logger:Error('Callbacks', string.format("Client Callback ^2%s^7 Failed: %s\n%s", event, tostring(err), stackTrace()), { console = true })
                TriggerServerEvent('Callbacks:Server:ReceiveCallback', event, id)
            end
        end)
    end,
}

RegisterNetEvent('Callbacks:Client:TriggerEvent')
AddEventHandler('Callbacks:Client:TriggerEvent', function(event, data, id)
    if data == nil then data = {} end
    COMPONENTS.Callbacks:DoClientCallback(event, id, data)
end)

RegisterNetEvent('Callbacks:Client:ReceiveCallback')
AddEventHandler('Callbacks:Client:ReceiveCallback', function(event, id, ...)
    local callback = _sCallbacks[id]
    if callback == nil then return end

    _sCallbacks[id] = nil
    callback(...)
end)
