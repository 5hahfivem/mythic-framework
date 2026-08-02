function RegisterBallisticsCallbacks()
    Callbacks:RegisterServerCallback('Evidence:Ballistics:FileGun', function(source, data, cb)
		local player = Fetch:Source(source)
		if player and data and data.slotNum and data.serial then
			local char = player:GetData('Character')
			if char then
				local charId = char:GetData('SID')
				-- Files a Gun So Evidence Can Be Found
		
				local item = Inventory:GetSlot(charId, data.slotNum, 1)
				if item and item.MetaData and (item.MetaData.ScratchedSerialNumber or item.MetaData.SerialNumber) then
					local firearmRecord, policeWeapId

					if item.MetaData.ScratchedSerialNumber and item.MetaData.ScratchedSerialNumber == data.serial then
						firearmRecord = GetFirearmsRecord(item.MetaData.ScratchedSerialNumber, true)
					elseif item.MetaData.SerialNumber and item.MetaData.SerialNumber == data.serial then
						firearmRecord = GetFirearmsRecord(item.MetaData.SerialNumber, false)
					end

					if firearmRecord then
						if not firearmRecord.FiledByPolice then
							local update
							if item.MetaData.ScratchedSerialNumber then
								policeWeapId = string.format('PWI-%s', Sequence:Get('PoliceWeaponId'))

								update = {
									['$set'] = {
										FiledByPolice = true,
										PoliceWeaponId = policeWeapId,
									}
								}

								Inventory:SetMetaDataKey(item.id, 'PoliceWeaponId', policeWeapId)
							elseif item.MetaData.SerialNumber then
								update = {
									['$set'] = {
										FiledByPolice = true,
									}
								}
							end

							if update then
								firearmRecord.FiledByPolice = true
								if policeWeapId then
									firearmRecord.PoliceWeaponId = policeWeapId
								end

								local updated = MySQL.query.await(
									'UPDATE firearms SET FiledByPolice = 1, PoliceWeaponId = ?, firearm = ? WHERE Serial = ?',
									{
										firearmRecord.PoliceWeaponId,
										json.encode(firearmRecord),
										firearmRecord.Serial,
									}
								)

								if updated ~= nil then
									cb(true, false, GetMatchingEvidenceProjectiles(firearmRecord.Serial), policeWeapId)
								else
									cb(false)
								end
							end
						else
							return cb(true, true, GetMatchingEvidenceProjectiles(firearmRecord.Serial), firearmRecord.PoliceWeaponId)
						end
					else
						cb(false)
					end
				else
					cb(false)
				end
				return
			end
		end
		cb(false)
    end)
end

function RegisterBallisticsItemUses()
	Inventory.Items:RegisterUse('evidence-projectile', 'Evidence', function(source, itemData)
		if itemData and itemData.MetaData and itemData.MetaData.EvidenceId and itemData.MetaData.EvidenceWeapon then
			Callbacks:ClientCallback(source, 'Polyzone:IsCoordsInZone', {
				coords = GetEntityCoords(GetPlayerPed(source)),
				key = 'ballistics',
				val = true,
			}, function(inZone)
				if inZone then
					if not itemData.MetaData.EvidenceDegraded then
						local filedEvidence = GetEvidenceProjectileRecord(itemData.MetaData.EvidenceId)
						local matchingWeapon = GetFirearmsRecord(itemData.MetaData.EvidenceWeapon.serial, nil, true)
	
						if filedEvidence then -- Already Exists
							TriggerClientEvent('Evidence:Client:FiledProjectile', source, false, true, true, filedEvidence, matchingWeapon, itemData.MetaData.EvidenceId)
						else
							local newFiledEvidence = CreateEvidenceProjectileRecord({
								Id = itemData.MetaData.EvidenceId,
								Weapon = itemData.MetaData.EvidenceWeapon,
								Coords = itemData.MetaData.EvidenceCoords,
								AmmoType = itemData.MetaData.EvidenceAmmoType,
							})
	
							if newFiledEvidence then
								TriggerClientEvent('Evidence:Client:FiledProjectile', source, false, true, false, newFiledEvidence, matchingWeapon, itemData.MetaData.EvidenceId)
							else
								TriggerClientEvent('Evidence:Client:FiledProjectile', source, false, false)
							end
						end
					else
						TriggerClientEvent('Evidence:Client:FiledProjectile', source, true)
					end
				end
			end)
		end
	end)

	Inventory.Items:RegisterUse('evidence-dna', 'Evidence', function(source, itemData)
		if itemData and itemData.MetaData and itemData.MetaData.EvidenceId and itemData.MetaData.EvidenceDNA then
			Callbacks:ClientCallback(source, 'Polyzone:IsCoordsInZone', {
				coords = GetEntityCoords(GetPlayerPed(source)),
				key = 'dna',
				val = true,
			}, function(inZone)
				if inZone then
					if not itemData.MetaData.EvidenceDegraded then
						local char = GetCharacter(itemData.MetaData.EvidenceDNA)
						if char then
							TriggerClientEvent('Evidence:Client:RanDNA', source, false, char, itemData.MetaData.EvidenceId)
						else
							TriggerClientEvent('Evidence:Client:RanDNA', source, false, false)
						end
					else
						TriggerClientEvent('Evidence:Client:RanDNA', source, true)
					end
				end
			end)
		end
	end)
end

function GetFirearmsRecord(serialNumber, scratched, filedOnly)
	if not serialNumber then
		return false
	end

	local p = promise.new()

	local query = 'SELECT firearm FROM firearms WHERE Serial = ? AND Scratched = ?'
	local params = { serialNumber, scratched and 1 or 0 }

	if filedOnly then
		query = query .. ' AND FiledByPolice = 1'
	end

	local result = MySQL.single.await(query, params)

	if result == nil then
		return false
	end

	return json.decode(result.firearm)
end

function GetEvidenceProjectileRecord(evidenceId)
	local result = MySQL.single.await('SELECT projectile FROM firearms_projectiles WHERE Id = ?', { evidenceId })

	if result == nil then
		return false
	end

	return json.decode(result.projectile)
end

function CreateEvidenceProjectileRecord(document)
	local inserted = MySQL.insert.await(
		'INSERT INTO firearms_projectiles (Id, WeaponSerial, projectile) VALUES(?, ?, ?)',
		{
			document.Id,
			document.Weapon?.serial,
			json.encode(document),
		}
	)

	if inserted == nil then
		return false
	end

	return document
end

function GetMatchingEvidenceProjectiles(weaponSerial)
	local results = MySQL.query.await('SELECT Id FROM firearms_projectiles WHERE WeaponSerial = ?', { weaponSerial })

	local foundEvidence = {}
	for k, v in ipairs(results) do
		table.insert(foundEvidence, v.Id)
	end

	return foundEvidence
end

function GetCharacter(stateId)
	local p = promise.new()

	do
		local row = MySQL.single.await('SELECT `character` FROM characters WHERE SID = ?', { stateId })
		local char = row and json.decode(row.character) or nil

		if char then
			if char.SID and char.First and char.Last then
				p:resolve({
					SID = char.SID,
					First = char.First,
					Last = char.Last,
					Age = math.floor((os.time() - char.DOB) / 3.156e+7),
				})
			end
		else
			p:resolve(false)
		end
	end

	return Citizen.Await(p)
end
