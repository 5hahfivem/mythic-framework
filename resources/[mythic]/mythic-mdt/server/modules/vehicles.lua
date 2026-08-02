_MDT.Vehicles = {
	Search = function(self, term)
		local search = string.format('%%%s%%', term)
		local rows = MySQL.query.await(
			[[SELECT vehicle FROM vehicles
				WHERE (ownerType = 0 AND ownerId LIKE ?)
					OR VIN LIKE ?
					OR RegisteredPlate LIKE ?
					OR CONCAT(Make, ' ', Model) LIKE ?
				LIMIT 24]],
			{ search, search, search, search }
		)

		GlobalState['MDT:Metric:Search'] = GlobalState['MDT:Metric:Search'] + 1

		return DecodeVehicles(rows)
	end,
	View = function(self, VIN)
		local result = MySQL.single.await("SELECT vehicle FROM vehicles WHERE VIN = ?", { VIN })

		if result == nil then
			return false
		end

		local vehicle = json.decode(result.vehicle)

		do

			if vehicle.Owner then
				if vehicle.Owner.Type == 0 then
					vehicle.Owner.Person = MDT.People:View(vehicle.Owner.Id)
				elseif vehicle.Owner.Type == 1 or vehicle.Owner.Type == 2 then
					local jobData = Jobs:DoesExist(vehicle.Owner.Id, vehicle.Owner.Workplace)
					if jobData then
						if jobData.Workplace then
							vehicle.Owner.JobName = string.format('%s (%s)', jobData.Name, jobData.Workplace.Name)
						else
							vehicle.Owner.JobName = jobData.Name
						end
					end
				end

				if vehicle.Owner.Type == 2 then
					vehicle.Owner.JobName = vehicle.Owner.JobName .. " (Dealership Buyback)"
				end
			end
		end

		return vehicle
	end,
	Flags = {
		Add = function(self, VIN, data, plate)
			local vehicle = MDT.Vehicles:Fetch(VIN)
			if not vehicle then
				return false
			end

			vehicle.Flags = vehicle.Flags or {}
			table.insert(vehicle.Flags, data)

			local success = MDT.Vehicles:Store(VIN, vehicle)

			if success and data.radarFlag and plate then
				Radar:AddFlaggedPlate(plate, 'Vehicle Flagged in MDT')
			end

			return success
		end,
		Remove = function(self, VIN, flag)
			local vehicle = MDT.Vehicles:Fetch(VIN)
			if not vehicle or not vehicle.Flags then
				return false
			end

			for k = #vehicle.Flags, 1, -1 do
				if vehicle.Flags[k].Type == flag then
					table.remove(vehicle.Flags, k)
				end
			end

			return MDT.Vehicles:Store(VIN, vehicle)
		end,
	},
	UpdateStrikes = function(self, VIN, strikes)
		local vehicle = MDT.Vehicles:Fetch(VIN)
		if not vehicle then
			return false
		end

		vehicle.Strikes = strikes

		return MDT.Vehicles:Store(VIN, vehicle)
	end,
	GetStrikes = function(self, VIN)
		local veh = MDT.Vehicles:Fetch(VIN)
		local strikes = 0
		if veh and veh.Strikes and #veh.Strikes > 0 then
			strikes = #veh.Strikes
		end

		return strikes
	end,
	Fetch = function(self, VIN)
		local result = MySQL.single.await("SELECT vehicle FROM vehicles WHERE VIN = ?", { VIN })

		if result == nil then
			return false
		end

		return json.decode(result.vehicle)
	end,
	Store = function(self, VIN, vehicle)
		return MySQL.query.await("UPDATE vehicles SET vehicle = ? WHERE VIN = ?", {
			json.encode(vehicle),
			VIN,
		}) ~= nil
	end,
}

function DecodeVehicles(rows)
	local vehicles = {}

	for k, v in ipairs(rows) do
		table.insert(vehicles, json.decode(v.vehicle))
	end

	return vehicles
end

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:Search:vehicle", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Vehicles:Search(data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:View:vehicle", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Vehicles:View(data))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Create:vehicle-flag", function(source, data, cb)
		if CheckMDTPermissions(source, false, 'police') then
			cb(MDT.Vehicles.Flags:Add(data.parent, data.doc, data.plate))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Delete:vehicle-flag", function(source, data, cb)
		if CheckMDTPermissions(source, false, 'police') then
			cb(MDT.Vehicles.Flags:Remove(data.parent, data.id))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Update:vehicle-strikes", function(source, data, cb)
		if CheckMDTPermissions(source, false, 'police') then
			cb(MDT.Vehicles:UpdateStrikes(data.VIN, data.strikes))
		else
			cb(false)
		end
	end)
end)
