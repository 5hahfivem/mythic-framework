local _cachedSeq = {}
local _loading = {}

COMPONENTS.Sequence = {
	Get = function(self, key)
		if _loading[key] then
			while _loading[key] do
				Wait(10)
			end
		end

		if _cachedSeq[key] ~= nil then
			_cachedSeq[key] = {
				value = _cachedSeq[key].value + 1,
				dirty = true
			}
			return _cachedSeq[key].value
		else
			_loading[key] = true

			local result = MySQL.single.await("SELECT current FROM sequence WHERE `key` = ?", { key })
			local v

			if result == nil then
				MySQL.insert.await("INSERT INTO sequence (`key`, current) VALUES(?, ?)", { key, 1 })
				v = { value = 1, dirty = true }
			else
				v = { value = result.current + 1, dirty = true }
			end

			_cachedSeq[key] = v
			_loading[key] = false
			return v.value
		end
	end,
	Save = function(self)
		for k, v in pairs(_cachedSeq) do
			if v.dirty then
				local success = MySQL.query.await(
					"INSERT INTO sequence (`key`, current) VALUES(?, ?) ON DUPLICATE KEY UPDATE current = VALUES(current)",
					{ k, v.value }
				) ~= nil

				if success then
					COMPONENTS.Logger:Trace("Sequence", string.format("Saved Sequence: ^2%s^7", k))
				end

				v.dirty = false
			end
		end
	end,
}

AddEventHandler("Core:Shared:Ready", function()
	COMPONENTS.Tasks:Register("sequence_save", 1, function()
		COMPONENTS.Sequence:Save()
	end)
end)

AddEventHandler("Core:Server:ForceSave", function()
	COMPONENTS.Sequence:Save()
end)
