COMPONENTS.Convar = {}
CreateThread(function()
    COMPONENTS.Convar = {
        ENVIRONMENT = { key = 'sv_environment', value = GetConvar('sv_environment', 'DEV'), stop = true },
        ACCESS_ROLE = { key = 'sv_access_role', value = GetConvar('sv_access_role', 0), stop = false },
        -- API_ADDRESS = { key = 'api_address', value = GetConvar('api_address', 'CONVAR_DEFAULT'), stop = true },
        -- API_TOKEN = { key = 'api_token', value = GetConvar('api_token', 'CONVAR_DEFAULT'), stop = true },
        --BOT_TOKEN = { key = 'discord_bot_token', value = GetConvar('discord_bot_token', 'CONVAR_DEFAULT'), stop = true },
        LOGGING = { value = tonumber(GetConvar('log_level', 0)), key = 'log_level', stop = false },
        MFW_VERSION = { value = GetConvar('mfw_version', "UNKNOWN"), key = 'MFW_VERSION', stop = false },
    }
end)

AddEventHandler('Core:Shared:Watermark', function()
    GlobalState.IsProduction = (COMPONENTS.Convar.ENVIRONMENT.value:upper()) ~= "DEV"
    for k, v in pairs(COMPONENTS.Convar) do
        if v.value == 'CONVAR_DEFAULT' then
            COMPONENTS.Logger:Error('Convar', 'Missing Convar ' .. v.key, {
                console = true,
                file = true,
            })

            if v.stop then
                COMPONENTS.Core:Shutdown('Missing Convar ' .. v.key)
                return
            end
        end
    end

    TriggerEvent('Core:Server:StartupReady')
end)